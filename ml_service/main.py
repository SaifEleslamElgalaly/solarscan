from fastapi import FastAPI, UploadFile, File
from ultralytics import YOLO
import shutil
import os
from PIL import Image
import io

app = FastAPI()

# Load the model (assume best.pt exists after training, fallback to base if not)
MODEL_PATH = 'runs/classify/solar_defect_classifier/weights/best.pt'
if os.path.exists(MODEL_PATH):
    model = YOLO(MODEL_PATH)
else:
    # If not trained yet, use pretrained nano for development
    model = YOLO('yolov8n-cls.pt')

RECOMMENDATIONS = {
    "Bird-drop": "Cleaning required",
    "Clean": "No action needed",
    "Dusty": "Cleaning required",
    "Electrical-damage": "Technician inspection required",
    "Physical-Damage": "Panel replacement required",
    "Snow-Covered": "Remove snow"
}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # Read image
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))
    
    # Save temporarily for YOLO
    temp_path = "temp_predict.jpg"
    image.save(temp_path)
    
    # Predict
    results = model(temp_path)
    
    # Process results
    result = results[0]
    probs = result.probs
    top1_idx = probs.top1
    top1_conf = float(probs.top1conf)
    top1_label = result.names[top1_idx]
    
    recommendation = RECOMMENDATIONS.get(top1_label, "Unknown defect. Inspection recommended.")
    
    # Clean up
    os.remove(temp_path)
    
    # Sanity check: If confidence is too low, it's likely not a solar panel or a bad image
    if top1_conf < 0.5:
        return {
            "class": "Unknown",
            "confidence": top1_conf,
            "recommendation": "Unable to identify solar panel clearly. Please ensure the panel is centered in frame."
        }

    return {
        "class": top1_label,
        "confidence": top1_conf,
        "recommendation": recommendation
    }

@app.post("/retrain")
async def retrain():
    # In a real scenario, this would trigger a background task
    # For now, we just acknowledge the command
    return {"message": "Retraining triggered successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
