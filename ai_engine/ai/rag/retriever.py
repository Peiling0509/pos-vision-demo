import os
import chromadb
import jieba

from langchain_core.documents import Document
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.retrievers import BM25Retriever
from langchain_classic.retrievers import EnsembleRetriever
from langchain_classic.retrievers import ContextualCompressionRetriever
from langchain_classic.retrievers.document_compressors import CrossEncoderReranker
from langchain_community.cross_encoders import HuggingFaceCrossEncoder

from langchain_groq import ChatGroq
from langchain_openai import ChatOpenAI

from pydantic import BaseModel, Field
from typing import List, Optional
from langchain_core.prompts import ChatPromptTemplate

from langchain_groq import ChatGroq

# ==========================================
# Global Singleton Variables
# ==========================================
query_rewriter_pipeline = None
embedding_model = None
chroma_client = None
knowledge_collection = None
vectorstore = None
bm25_retriever_instance = None
advanced_rag_retriever = None

# ==========================================
# Query Rewriter
# ==========================================
class SearchIntent(BaseModel):
    optimized_query: str = Field(description="Optimized search query")
    excluded_keywords: Optional[List[str]] = Field(description="Keywords to exclude")

def get_query_rewriter():
    global query_rewriter_pipeline
    
    if query_rewriter_pipeline is None:
        print("Loading query rewriter...")

        # OpenAI model
        # rewriter_llm = ChatOpenAI(
        #     model="gpt-4o-mini",
        #     openai_api_key=os.getenv("OPENAI_API_KEY"),
        #     base_url="https://models.inference.ai.azure.com",
        #     temperature=0
        # )

        # Groq model
        rewriter_llm = ChatGroq(
            model="llama-3.3-70b-versatile",
            api_key=os.getenv("GROQ_API_KEY"),
            temperature=0
        )

        rewrite_prompt = ChatPromptTemplate.from_messages([
            (
                "system",
                """You are an expert and highly strictly retail POS assistant. 
                CRITICAL ANTI-HALLUCINATION RULES:
                1. STRICT GROUNDING: You MUST base your answers ENTIRELY on the data returned by your tools. 
                2. NO GUESSING: If a tool returns no data, or if the user asks for a price/stock/ingredient that is NOT explicitly stated in the tool's response, you MUST reply: "I do not have that information."
                3. NO EXTERNAL KNOWLEDGE: Never recommend general items (like "popcorn" or "coca cola") unless they specifically appeared in the 'get_product_knowledge' tool output.
                4. OUT OF BOUNDS: If the user asks about products we don't sell (e.g., iPhones, laptops, appliances), explicitly state: "We only sell grocery products."
                """
            ),
            (
                "human",
                "{raw_query}"
            )
        ])
        
        query_rewriter_pipeline = rewrite_prompt | rewriter_llm.with_structured_output(SearchIntent)
        
    return query_rewriter_pipeline

# ======================================
# Embedding Model
# ======================================
def get_embedding_model():
    global embedding_model

    if embedding_model is None:
        print("Loading embedding model...")
        embedding_model = HuggingFaceEmbeddings(
            model_name="all-MiniLM-L6-v2"
        )
    return embedding_model

# ======================================
# ChromaDB
# ======================================
def get_chroma_client():
    global chroma_client
    if chroma_client is None:
        print("Initializing Chroma client...")
        chroma_client = chromadb.PersistentClient(path="/app/chroma_data")
    return chroma_client

def get_knowledge_collection():
    global knowledge_collection
    if knowledge_collection is None:
        knowledge_collection = get_chroma_client().get_or_create_collection(
            name="product_knowledge"
        )
    return knowledge_collection

def get_vectorstore():
    global vectorstore
    if vectorstore is None:
        print("Initializing Chroma VectorStore...")
        vectorstore = Chroma(
            client=get_chroma_client(),
            collection_name="product_knowledge",
            embedding_function=get_embedding_model()
        )
    return vectorstore

# ======================================
# BM25 Retriever
# ======================================
def get_bm25_retriever():
    global bm25_retriever_instance
    if bm25_retriever_instance is None:
        print("Initializing BM25 Retriever...")
        collection = get_knowledge_collection()
        existing_data = collection.get()

        docs = []
        if existing_data.get("documents"):
            for text in existing_data["documents"]:
                if text: 
                    docs.append(Document(page_content=text))

        if not docs:
            docs.append(Document(page_content="empty"))
            
        bm25_retriever_instance = BM25Retriever.from_documents(
            docs,
            preprocess_func=jieba.lcut
        )
        bm25_retriever_instance.k = 10
        
    return bm25_retriever_instance

# ======================================
# Final RAG Pipeline
# ======================================
def get_rag_retriever():
    global advanced_rag_retriever

    if advanced_rag_retriever is None:
        print("Building RAG pipeline...")
        
        # 1. Lazy load Base Retrievers
        vector_retriever = get_vectorstore().as_retriever(search_kwargs={"k": 10})
        bm25_ret = get_bm25_retriever()

        # 2. Setup Hybrid Retriever
        hybrid_retriever = EnsembleRetriever(
            retrievers=[bm25_ret, vector_retriever],
            weights=[0.4, 0.6]
        )

        # 3. Setup Reranker (Cross Encoder is slow to load, lazy loading is crucial here)
        print("Loading CrossEncoder Reranker...")
        cross_encoder = HuggingFaceCrossEncoder(
            model_name="BAAI/bge-reranker-base"
        )

        reranker = CrossEncoderReranker(
            model=cross_encoder,
            top_n=6
        )

        # 4. Final Compression Retriever
        advanced_rag_retriever = ContextualCompressionRetriever(
            base_compressor=reranker,
            base_retriever=hybrid_retriever
        )

    return advanced_rag_retriever