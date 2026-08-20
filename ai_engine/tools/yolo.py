from langchain_core.tools import tool

# Update this import path based on where you moved your vision model logic
from ai.vision.detector import get_vision_model

# ==========================================
# Tool: Image Product Detection
# ==========================================
@tool
def analyze_product_image(image_path: str) -> str:
    """
    Analyze an uploaded image to detect physical products inside it.
    Use this when the system notice indicates the user has uploaded an image.

    Args:
        image_path: The absolute file path of the image.
    """
    try:
        model = get_vision_model()
        results = model(image_path, conf=0.5)
        detected = []

        for box in results[0].boxes:
            cls_id = int(box.cls[0])
            name = model.names[cls_id]
            detected.append(name)

        if not detected:
            return "No recognizable products detected in the image."

        unique_items = list(set(detected))
        return f"Detected the following item categories: {', '.join(unique_items)}. Now use get_product_knowledge to find specific brands for these categories."

    except Exception as e:
        return f"Image analysis failed due to model error: {str(e)}"