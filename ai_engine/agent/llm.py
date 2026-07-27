import os
from langchain_openai import ChatOpenAI
from langchain_groq import ChatGroq
from dotenv import load_dotenv
from agent.tools import tools_list


# Load environment variables at the very beginning to ensure
# API keys are available before initializing any models.
load_dotenv()

# =====================================================================
# 1. Production Model Configuration
# (Agent Core / Query Rewriter)
# =====================================================================

# ----------------- Option A: OpenAI / Azure / GitHub Models -----------------
llm = ChatOpenAI(
    model="gpt-4o",
    openai_api_key=os.getenv("OPENAI_API_KEY"),
    base_url="https://models.inference.ai.azure.com",
    temperature=0
)
#
# rewriter_llm = ChatOpenAI(
#     model="gpt-4o-mini",
#     openai_api_key=os.getenv("OPENAI_API_KEY"),
#     base_url="https://models.inference.ai.azure.com",
#     temperature=0
# )

# ----------------- Option B: DeepSeek Official API -----------------
# llm = ChatOpenAI(
#     model="deepseek-chat",
#     api_key=os.getenv("DEEPSEEK_API_KEY"),
#     base_url="https://api.deepseek.com",
#     temperature=0
# )
#
# rewriter_llm = ChatOpenAI(
#     model="deepseek-chat",
#     api_key=os.getenv("DEEPSEEK_API_KEY"),
#     base_url="https://api.deepseek.com",
#     temperature=0
# )

# ----------------- Option C: Groq Platform -----------------
# llm = ChatGroq(
#     model="llama-3.3-70b-versatile",
#     api_key=os.getenv("GROQ_API_KEY"),
#     temperature=0
# )

#Tool Binding, let LLM have Function Calling ability
llm_with_tools = llm.bind_tools(tools_list)