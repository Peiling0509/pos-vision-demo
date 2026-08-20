from typing import Literal

from pydantic import BaseModel

from shared.config import llm
from shared.state import AgentState
from prompts.supervisor import supervisor_prompt


class RouterSchema(BaseModel):
    next: Literal["Inventory", "Knowledge", "Vision", "FINISH"]


router = supervisor_prompt | llm.with_structured_output(RouterSchema)


def supervisor_node(state: AgentState):
    response = router.invoke(
        {
            "messages": state["messages"],
            "last_worker": state.get("last_worker"),
        }
    )

    return {
        "next": response.next
    }