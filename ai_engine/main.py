from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from ultralytics import YOLO
import cv2
import numpy as np
import os

# LangChain
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate
from langchain_community.utilities import SQLDatabase
from langchain_community.agent_toolkits import create_sql_agent

app = FastAPI(title="Smart POS AI Microservice")


# ==========================================
# Module 1: YOLO Computer Vision (Image Recognition)
# ==========================================
# Load the fine-tuned YOLO model weights during startup
model = YOLO("best.pt")

@app.post("/api/scan")
async def scan_item(image: UploadFile = File(...)):
    try:
        contents = await image.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        results = model(img, conf=0.5)

        detected_items = []

        for box in results[0].boxes:
            cls_id = int(box.cls[0])
            name = model.names[cls_id]
            confidence = float(box.conf[0])

            xyxy = box.xyxy[0].tolist()

            detected_items.append({
                "item_name": name,
                "confidence": round(confidence, 2),
                "box": xyxy
            })

        return JSONResponse(content={
            "status": "success",
            "data": detected_items
        })

    except Exception as e:
        return JSONResponse(
            content={
                "status": "error",
                "message": str(e)
            },
            status_code=500
        )


# ==========================================
# Module 2: LangChain Intelligent Q&A (RAG Enhanced Generation)
# ==========================================

# Define the data format received from Laravel
class ChatRequest(BaseModel):
    question: str
    context_data: str = ""

# 1. Connect LangChain to the database
mysql_uri = "mysql+pymysql://sail:password@mysql:3306/laravel"
db = SQLDatabase.from_uri(mysql_uri)

@app.post("/api/chat")
async def ai_assistant(request: ChatRequest):
    try:

        # 1. Initialize OpenAI Large Language Model
        # Temperature = 0.7 allows responses to be accurate while maintaining
        # a natural and conversational tone
        llm = ChatOpenAI(
            model="gpt-4o-mini",
            openai_api_key=os.getenv("OPENAI_API_KEY"),
            base_url="https://models.inference.ai.azure.com",
            temperature=0.7
        )

        # 2. Create a database intelligent agent (SQL Agent)
        # agent_type="openai-tools" allows the LLM to automatically call SQL query functions when needed
        agent_executor = create_sql_agent(
            llm,
            db=db,
            agent_type="openai-tools",
            verbose=True  # Print how the AI thinks and generates SQL queries in the console
        )

        # 4. Combine context (if there is scanned product data, include it;
        # otherwise, rely on the user's question and let the AI query the database by itself)
        prompt = f"You are a professional POS system sales assistant. Please answer customer questions.\n"

        if request.context_data:
            prompt += f"Current product information viewed by the customer: {request.context_data}\n"

        prompt += f"Customer question: {request.question}"

        # 5. Execute reasoning
        response = agent_executor.invoke({"input": prompt})

        return {"status": "success", "answer": response['output']}

    except Exception as e:
        return JSONResponse(
            content={
                "status": "error",
                "message": str(e)
            },
            status_code=500
        )