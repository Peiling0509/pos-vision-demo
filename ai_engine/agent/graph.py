# Import LangGraph components
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode, tools_condition
from langgraph.checkpoint.memory import MemorySaver

# Import our agent state, LLM, and available tools
from agent.state import AgentState
from agent.llm import llm_with_tools
from agent.tools import tools_list

# Node 1: The Brain Node
def agent_node(state: AgentState):
    """
    This node is the AI brain.
    It thinks about the user's request and decides what to do next.
    """

    # Send the conversation history to the LLM
    # The LLM already knows which tools it can use.
    response = llm_with_tools.invoke(state["messages"])

    # Return the AI's new message.
    # It can be:
    # 1. A normal answer
    # 2. A request to call a tool
    return {"messages": [response]}


# Node 2: Tool Execution Node
# ToolNode automatically runs the tools we created
# and returns the tool results.
tool_node = ToolNode(tools_list)

# --- Build the workflow graph ---

# Create a graph using AgentState as the data structure
workflow = StateGraph(AgentState)

# Add nodes into the graph
workflow.add_node("agent", agent_node)
workflow.add_node("tools", tool_node)

# The first step is always the AI brain
workflow.set_entry_point("agent")

# Add a conditional path after the agent node
# tools_condition checks the AI's decision:
#
# If the AI wants to use a tool:
#     agent --> tools
#
# If the AI already has the answer:
#     agent --> END
#
workflow.add_conditional_edges(
    "agent",
    tools_condition,
)

# After the tool finishes:
# Send the result back to the AI
# so the AI can continue thinking
# or generate the final answer.
workflow.add_edge("tools", "agent")

memory = MemorySaver()

#Compile the graph into an executable workflow
app_graph = workflow.compile(checkpointer=memory)