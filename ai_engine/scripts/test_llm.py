import sys
sys.path.append("/app")

from shared.config import llm
from langchain_core.messages import HumanMessage

print("⏳ Sending request to Groq API (Isolated Test)...")

try:
    response = llm.invoke(
        [
            HumanMessage(
                content="Hello! Please reply with 'Connection successful' if you receive this."
            )
        ]
    )

    print("\n✅ SUCCESS: Groq API Key and connection are working perfectly!")
    print("-" * 40)
    print("AI Response:", response.content)

except Exception as e:
    print("\n❌ ERROR: Groq connection failed!")
    print("-" * 40)
    print(str(e))