from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from shared.config import llm
from tools.chromadb import get_product_knowledge

knowledge_tools = [get_product_knowledge]

prompt = ChatPromptTemplate.from_messages([
    ("system", """You are a Product Knowledge Specialist.

    Responsibilities:
    - Search the RAG knowledge base.
    - Answer questions about products.
    - Explain product features, usage, specifications and recommendations.

    Always use the knowledge search tool when external product knowledge is required.
    Never invent information that is not returned by the tool.

    RULES:
    - Maximum ONE knowledge search per user request.
    - After the tool returns information, immediately generate the final answer.
    - Never search the knowledge base twice for the same request.
    
    CRITICAL XML TOOL CALLING RULE: 
    If you need to call a tool, you MUST use the EXACT following XML format without missing any brackets:
    <function=tool_name>{{"arg1": "value"}}</function>
    
    DO NOT FORGET the closing '>' bracket. NEVER write <function=tool_name{{...
    
    """),
    MessagesPlaceholder(variable_name="messages"),
])

knowledge_agent = prompt | llm.bind_tools(knowledge_tools)

def knowledge_node(state):
    result = knowledge_agent.invoke(
        {
            "messages": state["messages"]
        }
    )

    return {
        "messages": [result],
        "last_worker": "Knowledge"
    }