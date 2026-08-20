import json
import shutil
import cv2
import numpy as np
import os

from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse, StreamingResponse
from langchain_core.messages import HumanMessage

from graphs.multi_agent_graph import build_graph
from ai.vision.detector import get_vision_model

# Initialize the multi-agent graph
app_graph = build_graph()

UPLOAD_DIR = "/tmp/pos_uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

app = FastAPI(title="Smart POS AI Microservice")

# ==========================================
# Module 1: YOLO Computer Vision (Image Recognition)
# ==========================================
@app.post("/api/scan")
async def scan_item(image: UploadFile = File(...)):
    try:
        contents = await image.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        # Retrieve the shared YOLO instance to prevent duplicate memory usage
        model = get_vision_model()
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
    image: UploadFile = File(None),
    session_id: str = Form("default_user_1")
):
    try:
        prompt_text = ""

        # 1. Image handling
        if image:
            image_path = os.path.join(UPLOAD_DIR, image.filename)
            with open(image_path, "wb") as buffer:
                shutil.copyfileobj(image.file, buffer)
                
            prompt_text += (
                f"\n[SYSTEM NOTICE: The user has uploaded an image for you to analyze. "
                f"The image is saved at the path: '{image_path}'. "
                f"Use your 'analyze_product_image' tool on this path to see what is inside.]\n"
            )

        # 2. Add question
        prompt_text += f"\nCustomer question: {question}"

        input_message = HumanMessage(content=prompt_text)
        state_input = {"messages": [input_message]}
        config = {
                "configurable": {"thread_id": session_id},
                "recursion_limit": 30  # <-- avoid deadlocks in recursive tool calls
            }
        
        # 3. Graph Execution
        final_state = app_graph.invoke(state_input, config=config)
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
    config = {
        "configurable": {"thread_id": session_id},
        "recursion_limit": 30  # <-- avoid deadlocks in recursive tool calls
    }

    async def event_generator():
        try:
            async for event in app_graph.astream_events(state_input, config=config, version="v2"):
                kind = event["event"]
                
                if kind == "on_chat_model_stream":
                    chunk = event["data"]["chunk"]
                    if chunk.content:
                        yield f"data: {json.dumps({'type': 'token', 'content': chunk.content})}\n\n"
                
                elif kind == "on_tool_start":
                    tool_name = event["name"]
                    yield f"data: {json.dumps({'type': 'tool_start', 'tool': tool_name})}\n\n"
                    
                elif kind == "on_tool_end":
                    tool_name = event["name"]
                    yield f"data: {json.dumps({'type': 'tool_end', 'tool': tool_name})}\n\n"

            yield f"data: {json.dumps({'type': 'done'})}\n\n"
            
        except Exception as e:
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")