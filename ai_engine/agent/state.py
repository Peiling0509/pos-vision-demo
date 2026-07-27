from typing import TypedDict, Annotated
from langgraph.graph.message import add_messages

class AgentState(TypedDict):
    # Annotated[list, add_messages]
    # auto add the new message to list instead of overlay it
    messages: Annotated[list, add_messages]