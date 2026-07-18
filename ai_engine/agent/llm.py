import os
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv
from agent.tools import tools_list

load_dotenv()

llm = ChatOpenAI(
        model="gpt-4o-mini",
        openai_api_key=os.getenv("OPENAI_API_KEY"),
        base_url="https://models.inference.ai.azure.com",
        temperature=0
    )

#Tool Binding, let LLM have Function Calling ability
llm_with_tools = llm.bind_tools(tools_list)