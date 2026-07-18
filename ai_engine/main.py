import json
import shutil

from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel
from ultralytics import YOLO
import cv2
import numpy as np
import os

from langchain_core.messages import HumanMessage
from agent.graph import app_graph

# LangChain
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate
from langchain_community.utilities import SQLDatabase
from langchain_community.agent_toolkits import create_sql_agent

UPLOAD_DIR = "/tmp/pos_uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

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
@app.post("/api/chat")
async def ai_assistant(
    question: str = Form(...), 
    image: UploadFile = File(None), #make upload file as optional
    session_id: str = Form("default_user_1")
):
    try:
        # To avoid repeatedly using the same system suggestions for every question, we've made some minor optimizations.
        prompt_text = ""

        # 1. if the user uploaded an image, save it and inform the model about its path
        if image:
            image_path = os.path.join(UPLOAD_DIR, image.filename)
            
            # make sure to save the uploaded image to the specified path
            with open(image_path, "wb") as buffer:
                shutil.copyfileobj(image.file, buffer)
                
            # Inform the model that an image has been uploaded and provide the path for analysis
            prompt_text += (
                f"\n[SYSTEM NOTICE: The user has uploaded an image for you to analyze. "
                f"The image is saved at the path: '{image_path}'. "
                f"Use your 'analyze_product_image' tool on this path to see what is inside.]\n"
            )

        # 2. add the user's question to the prompt
        prompt_text += f"\nCustomer question: {question}"

        # 3. active the LangChain agent with the constructed prompt
        input_message = HumanMessage(content=prompt_text)
        state_input = {"messages": [input_message]}

        # 4. Setting the session_id allows LangGraph to automatically retrieve previous chat history from MemorySaver
        # LangGraph will automatically save the current conversation to MemorySaver for future reference.
        config = {"configurable": {"thread_id": session_id}}
        
        # Agent -> analyze_product_image -> Agent -> get_inventory -> Agent -> END
        final_state = app_graph.invoke(state_input,  config=config)
        final_answer = final_state["messages"][-1].content

        return {
            "status": "success",
            "answer": final_answer, 
            "steps": [
                {
                    "role": msg.type, 
                    "content": msg.content, 
                    "tool_calls": getattr(msg, 'tool_calls', None)
                } for msg in final_state["messages"]
            ]
        }
    
    except Exception as e:
        return JSONResponse(
            content={"status": "error", "message": str(e)},
            status_code=500
        )
    

# ------------------------------------------------
# Module 3: LangGraph Agent Enhanced Q&A (Streaming)
# ------------------------------------------------
@app.post("/api/chat/stream")
async def ai_assistant_stream(
    question: str = Form(...), 
    image: UploadFile = File(None),
    session_id: str = Form("default_user_1") 
):
    prompt_text = ""
    if image:
        image_path = os.path.join(UPLOAD_DIR, image.filename)
        with open(image_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        prompt_text += (
            f"[SYSTEM NOTICE: User uploaded image at '{image_path}'. "
            f"Use 'analyze_product_image' if needed.]\n"
        )

    prompt_text += f"Customer: {question}"
    input_message = HumanMessage(content=prompt_text)
    state_input = {"messages": [input_message]}
    config = {"configurable": {"thread_id": session_id}}

    #2. Define an asynchronous generator function to intercept the underlying events of LangGraph
    async def event_generator():
        try:
            # using astream_events(version="v2") to get fine-grained execution flow
            async for event in app_graph.astream_events(state_input, config=config, version="v2"):
                kind = event["event"]
                
                # Scenario A: The LLM is generating the final answer token by token (Typing Effect)
                if kind == "on_chat_model_stream":
                    chunk = event["data"]["chunk"]
                    if chunk.content:
                        # following the Server-Sent Events (SSE) format
                        # we send each token to the frontend as a JSON object
                        yield f"data: {json.dumps({'type': 'token', 'content': chunk.content})}\n\n"
                
                # Scenario B: Agent decides to call a tool (can display "Checking inventory..." on the frontend)
                elif kind == "on_tool_start":
                    tool_name = event["name"]
                    yield f"data: {json.dumps({'type': 'tool_start', 'tool': tool_name})}\n\n"
                    
                # Scenario C: Tool call ends
                elif kind == "on_tool_end":
                    tool_name = event["name"]
                    yield f"data: {json.dumps({'type': 'tool_end', 'tool': tool_name})}\n\n"

            # Execution completed, send completion signal
            yield f"data: {json.dumps({'type': 'done'})}\n\n"
            
        except Exception as e:
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"

    # 3. Return a StreamingResponse with media_type set to event-stream
    return StreamingResponse(event_generator(), media_type="text/event-stream")