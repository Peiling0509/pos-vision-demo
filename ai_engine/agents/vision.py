from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from shared.config import llm
from tools.yolo import analyze_product_image

vision_tools = [analyze_product_image]

prompt = ChatPromptTemplate.from_messages([
    ("system", """You are a Vision AI Specialist. Your ONLY job is to analyze product images and extract the product name or items visible.
    
    INSTRUCTIONS:
    1. Call the `analyze_product_image` tool to inspect the image.
    2. Once you get the product name from the tool, state it clearly in your text response (e.g., "The image shows [Product Name]"). 
    3. DO NOT attempt to call inventory or knowledge tools yourself. Pass the identified product name back to the supervisor so other specialists can handle it.
    
    CRITICAL XML TOOL CALLING RULE: 
    If you need to call a tool, you MUST use the EXACT following XML format without missing any brackets:
    <function=tool_name>{{"arg1": "value"}}</function>
    
    DO NOT FORGET the closing '>' bracket after the function name."""),
    MessagesPlaceholder(variable_name="messages"),
])

vision_agent = prompt | llm.bind_tools(vision_tools)

def vision_node(state):
    result = vision_agent.invoke(state)
    return {
        "messages": [result],
        "last_worker": "Vision"
    }