from ultralytics import YOLO

vision_model = None

def get_vision_model():

    global vision_model

    if vision_model is None:
        print("Loading YOLO model...")

        vision_model = YOLO(
            "best.pt"
        )

    return vision_model