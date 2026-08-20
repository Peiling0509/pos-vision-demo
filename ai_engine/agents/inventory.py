from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from shared.config import llm
from tools.inventory import (
    get_inventory,
    get_products_needing_restock,
    get_restock_recommendation
)

inventory_tools = [
    get_inventory,
    get_products_needing_restock,
    get_restock_recommendation
]

prompt = ChatPromptTemplate.from_messages([
    (
        "system",
        """
        You are an Inventory Specialist.

        Responsibilities:

        - Query inventory database.
        - Check stock quantity.
        - Check SKU.
        - Check warehouse location.
        - Check expiry.
        - Check prices.
        - Check restock threshold.
        - Analyze demand.
        - Check demand trend.
        - Check demand forecast.
        - Check demand volatility.
        - Check supplier lead time.
        - Check safety stock.
        - Check reorder point.
        - Generate restock recommendations.

        Always use the available tools whenever
        database or inventory information is required.

        Never make up inventory information.

        When the user asks:

        - "Should I restock this product?"
        - "How much should I order?"
        - "When should I reorder?"
        - "Is this product running out?"
        - "What is the recommended restock quantity?"
        - "What is the reorder point?"
        - "What is the stockout risk?"

        Use the get_restock_recommendation tool.

        After receiving tool results:

        1. Analyze the returned information.
        2. Give a concise answer to the user.
        3. Do not invent information that is not present in the tool result.

        CRITICAL XML TOOL CALLING RULE:

        If you need to call a tool, you MUST use the EXACT
        following XML format:

        <function=tool_name>{{"arg1": "value"}}</function>

        DO NOT FORGET the closing '>' bracket after the function name.

        Never write:

        <function=tool_name{{...}}

        """),
    MessagesPlaceholder(variable_name="messages"),
])


inventory_agent = prompt | llm.bind_tools(inventory_tools)

def inventory_node(state):
    result = inventory_agent.invoke(
    {
        "messages": state["messages"]
    })

    return {
        "messages": [result],
        "last_worker": "Inventory"
    }