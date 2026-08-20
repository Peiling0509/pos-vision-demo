from langchain_core.tools import tool

# Update this import path based on where you moved your RAG pipeline logic
from ai.rag.retriever import get_rag_retriever, get_query_rewriter

# ==========================================
# Tool: Product Knowledge RAG Search
# ==========================================
# @tool
# def get_product_knowledge(query: str) -> str:
#     """
#     Search the semantic knowledge base for product recommendations, alternatives, and detailed descriptions.
#     Use this FIRST when a user asks for general recommendations, categories, or has specific constraints (e.g., 'no sugar', 'movie snacks').

#     Args:
#         query: The user's exact requirements or situation.
#     """
#     try:
#         # Step 1: Rewrite user query to handle negations
#         rewriter = get_query_rewriter()
#         intent = rewriter.invoke({"raw_query": query})
        
#         print(f"🔍 Optimized Query: {intent.optimized_query}")
#         print(f"🚫 Excluded Keywords: {intent.excluded_keywords}")

#         # Step 2: Hybrid Retrieval
#         retriever = get_rag_retriever()
        
#         results = retriever.invoke(intent.optimized_query)

#         if not results:
#             return "No relevant product knowledge found in the database."

#         # Step 3: Strict Substring Filter for exclusions
#         filtered = []
#         for doc in results:
#             text = doc.page_content.lower()
#             excluded = False

#             if intent.excluded_keywords:
#                 for word in intent.excluded_keywords:
#                     if word.lower() in text:
#                         excluded = True
#                         break

#             if not excluded:
#                 filtered.append(doc.page_content)

#         # Step 4: Contextual Response formatting
#         if not filtered:
#             return (f"Search completed for '{intent.optimized_query}', but all results were removed "
#                     f"because they contained the excluded keywords: {intent.excluded_keywords}. "
#                     f"Please inform the user we do not have items fitting this strict criteria.")

#         # Return top 3 filtered results along with the constraints used
#         context_str = "\n\n---\n\n".join(filtered[:3])
#         return (f"[Search Context for '{intent.optimized_query}' | Excluded: {intent.excluded_keywords}]\n\n"
#                 f"{context_str}")

#     except Exception as e:
#         return f"Product knowledge search failed: {str(e)}"

@tool
def get_product_knowledge(query: str) -> str:
    """
    Search the semantic knowledge base for product recommendations, alternatives, and detailed descriptions.
    Use this FIRST when a user asks for general recommendations, categories, or has specific constraints (e.g., 'no sugar', 'movie snacks').

    Args:
        query: The user's exact requirements or situation.
    """
    print(f"🔍 Searching knowledge base for: {query}")
    
    try:
        retriever = get_rag_retriever()
        
        results = retriever.invoke(query)
        
        if not results:
            return "No specific information found in the knowledge base."
            
        formatted_results = "\n\n".join([doc.page_content for doc in results])
        print("✅ Search complete, returning data to Agent.")
        return formatted_results

    except Exception as e:
        print(f"❌ Knowledge base error: {e}")
        return f"Error accessing knowledge base: {str(e)}"