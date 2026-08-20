from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode, tools_condition
from langgraph.checkpoint.memory import MemorySaver

from shared.state import AgentState
from agents.supervisor import supervisor_node
from agents.inventory import inventory_node, inventory_tools
from agents.knowledge import knowledge_node, knowledge_tools
from agents.vision import vision_node, vision_tools

def build_graph():
    workflow = StateGraph(AgentState)

    # 1. Add Nodes
    workflow.add_node("Supervisor", supervisor_node)
    
    workflow.add_node("Inventory", inventory_node)
    workflow.add_node("Knowledge", knowledge_node)
    workflow.add_node("Vision", vision_node)
    
    workflow.add_node("Inventory_tools", ToolNode(inventory_tools))
    workflow.add_node("Knowledge_tools", ToolNode(knowledge_tools))
    workflow.add_node("Vision_tools", ToolNode(vision_tools))

    # 2. Add Routing Edges
    workflow.set_entry_point("Supervisor")
    
    workflow.add_conditional_edges(
        "Supervisor",
        lambda x: x["next"],
        {
            "Inventory": "Inventory",
            "Knowledge": "Knowledge",
            "Vision": "Vision",
            "FINISH": END
        }
    )

    # 3. Add Tool Execution Edges
    workflow.add_conditional_edges("Inventory", tools_condition, {"tools": "Inventory_tools", END: "Supervisor"})
    workflow.add_conditional_edges("Knowledge", tools_condition, {"tools": "Knowledge_tools", END: "Supervisor"})
    workflow.add_conditional_edges("Vision", tools_condition, {"tools": "Vision_tools", END: "Supervisor"})

    workflow.add_edge("Inventory_tools", "Inventory")
    workflow.add_edge("Knowledge_tools", "Knowledge")
    workflow.add_edge("Vision_tools", "Vision")

    # 4. Compile
    memory = MemorySaver()
    return workflow.compile(checkpointer=memory)