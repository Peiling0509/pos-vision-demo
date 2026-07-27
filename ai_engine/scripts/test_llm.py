import sys
sys.path.append("/app")

from agent.llm import llm_with_tools
from langchain_core.messages import HumanMessage

response = llm_with_tools.invoke(
    [
        HumanMessage(
            content="Cola zero 有货吗？"
        )
    ]
)

print(response)
print(response.tool_calls)