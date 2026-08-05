import os
import io
import sys
import subprocess
from fastapi import FastAPI, UploadFile, File, BackgroundTasks
import torch
import torch.nn as nn
from torchvision import models, transforms
import cv2
import numpy as np
from ultralytics import YOLO

app = FastAPI(title="Solar ResNet Classifier Service")


# Load YOLOv8 model for panel localization (to extract crop and bounding box coordinates)
YOLO_MODEL_PATH = ""
possible_paths = [
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "ml_service", "weights", "best.pt")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "train-8", "weights", "best.pt")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "old_legacy", "ml_service", "weights", "best.pt")),
]
for p in possible_paths:
    if os.path.exists(p):
        YOLO_MODEL_PATH = p
        break

if YOLO_MODEL_PATH:
    yolo_model = YOLO(YOLO_MODEL_PATH)
    print(f"Loaded YOLOv8 model from {YOLO_MODEL_PATH} for panel localization")
else:
    yolo_model = YOLO("yolov8n.pt")
    print("Warning: YOLOv8 trained weights not found. Using yolov8n.pt for localization.")

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
class_names = ["Bird", "Dust", "Clean", "Physical"]

# Re-create model architecture
model = models.resnet50(weights="IMAGENET1K_V1")
model.fc = nn.Linear(model.fc.in_features, len(class_names))

MODEL_PATH = os.path.join(os.path.dirname(__file__), "resnet50_yolo_optimized.pth")

# Load weights if trained, otherwise initialize
if os.path.exists(MODEL_PATH):
    try:
        model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
        print(f"Loaded ResNet-50 model weights from {MODEL_PATH}")
    except Exception as e:
        print(f"Error loading ResNet-50 weights: {e}. Using untrained weights.")
else:
    print(f"Warning: Trained weights not found at {MODEL_PATH}. Using untrained ResNet-50.")

model = model.to(device)
model.eval()

# Preprocessing transforms (To matches training transforms in yolotoresnet.py)
transform = transforms.Compose([
    transforms.ToPILImage(),
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

LABEL_MAPPING = {
    "Bird": "Bird Drop",
    "Dust": "Dusty",
    "Clean": "Clean",
    "Physical": "Physical Damage",
}

RECOMMENDATIONS = {
    "Bird Drop": "Clean the panel surface to restore efficiency",
    "Clean": "No action needed — panel is operating normally",
    "Dusty": "Clean the panel surface to restore efficiency",
    "Physical Damage": "Panel replacement required — structural damage detected",
}

def run_retrain_script():
    script_path = os.path.join(os.path.dirname(__file__), "yolotoresnet.py")
    log_path = os.path.join(os.path.dirname(__file__), "train_log.txt")
    print(f"Starting retraining background process: {script_path}")
    
    # We write training output to train_log.txt in the format required by index.php
    with open(log_path, "w", encoding="utf-8") as log_file:
        process = subprocess.Popen(
            [sys.executable, "-u", script_path],
            stdout=log_file,
            stderr=subprocess.STDOUT,
            cwd=os.path.dirname(__file__)
        )
        process.wait()
    
    # Reload model weights after training is complete
    if os.path.exists(MODEL_PATH):
        try:
            model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
            model.eval()
            print("Retraining finished and new weights loaded successfully!")
        except Exception as e:
            print(f"Error loading new weights after retraining: {e}")

def get_refined_defect_box(img, panel_box_xyxy, defect_type):
    """
    Given the original image and the panel bounding box (x1, y1, x2, y2),
    finds the tightest region representing the actual defect using OpenCV.
    Returns relative coordinates [fx1, fy1, fx2, fy2] relative to the full image.
    """
    try:
        x1, y1, x2, y2 = map(int, panel_box_xyxy)
        h_img, w_img = img.shape[:2]
        x1 = max(0, min(x1, w_img))
        y1 = max(0, min(y1, h_img))
        x2 = max(0, min(x2, w_img))
        y2 = max(0, min(y2, h_img))
        
        crop_img = img[y1:y2, x1:x2]
        h_crop, w_crop = crop_img.shape[:2]
        if h_crop < 10 or w_crop < 10:
            return [x1/w_img, y1/h_img, x2/w_img, y2/h_img]
            
        gray = cv2.cvtColor(crop_img, cv2.COLOR_BGR2GRAY)
        
        if defect_type == "Bird Drop":
            # Threshold to find bright white/grey regions (typical of bird drops)
            _, thresh = cv2.threshold(gray, 175, 255, cv2.THRESH_BINARY)
            contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            
            valid_boxes = []
            for cnt in contours:
                cx, cy, cw, ch = cv2.boundingRect(cnt)
                # Ignore noise, huge areas, and grid lines (elongated)
                if cw < 5 or ch < 5:
                    continue
                if cw > w_crop * 0.60 or ch > h_crop * 0.60:
                    continue
                aspect_ratio = cw / float(ch)
                if aspect_ratio > 4.0 or aspect_ratio < 0.25:
                    continue
                valid_boxes.append((cx, cy, cx + cw, cy + ch, cw * ch))
                    
            if valid_boxes:
                # Select the largest bright region
                valid_boxes.sort(key=lambda b: b[4], reverse=True)
                bx1, by1, bx2, by2, _ = valid_boxes[0]
                
                # Add 8px padding around the box to make it visually pleasing
                padding = 8
                bx1 = max(0, bx1 - padding)
                by1 = max(0, by1 - padding)
                bx2 = min(w_crop, bx2 + padding)
                by2 = min(h_crop, by2 + padding)
                
                fx1 = (x1 + bx1) / w_img
                fy1 = (y1 + by1) / h_img
                fx2 = (x1 + bx2) / w_img
                fy2 = (y1 + by2) / h_img
                return [fx1, fy1, fx2, fy2]
                
        elif defect_type == "Physical Damage":
            # Cracks/damage are high-frequency high-contrast edges. Use Canny.
            edges = cv2.Canny(gray, 50, 150)
            contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            
            valid_boxes = []
            for cnt in contours:
                cx, cy, cw, ch = cv2.boundingRect(cnt)
                # Ignore noise, huge areas, and grid lines (elongated)
                if cw < 5 or ch < 5:
                    continue
                if cw > w_crop * 0.50 or ch > h_crop * 0.50:
                    continue
                aspect_ratio = cw / float(ch)
                if aspect_ratio > 4.0 or aspect_ratio < 0.25:
                    continue
                valid_boxes.append((cx, cy, cx + cw, cy + ch, cw * ch))
                    
            if valid_boxes:
                # Sort by area descending and take the single largest defect contour
                valid_boxes.sort(key=lambda b: b[4], reverse=True)
                bx1, by1, bx2, by2, _ = valid_boxes[0]
                
                # Add 8px padding
                padding = 8
                bx1 = max(0, bx1 - padding)
                by1 = max(0, by1 - padding)
                bx2 = min(w_crop, bx2 + padding)
                by2 = min(h_crop, by2 + padding)
                
                fx1 = (x1 + bx1) / w_img
                fy1 = (y1 + by1) / h_img
                fx2 = (x1 + bx2) / w_img
                fy2 = (y1 + by2) / h_img
                return [fx1, fy1, fx2, fy2]
                
    except Exception as e:
        print(f"Error refining defect box: {e}")
        
    return [x1/w_img, y1/h_img, x2/w_img, y2/h_img]

CLASS_THRESHOLDS = {
    0: 0.05,  # Bird drop -> lowered to 0.05 for ultimate responsiveness
    1: 0.10,  # Clean
    2: 0.05,  # Dusty
    3: 0.05,  # Electrical Damage
    4: 0.05,  # Physical Damage
}

MAX_BOX_AREA_RATIO = 0.85

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    contents = await file.read()
    
    # Decode image as BGR to match opencv training loader
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if img is None:
        return {
            "class": "Unknown",
            "confidence": 0.0,
            "recommendation": "Unable to identify solar panel clearly. Please ensure the panel is centered in frame.",
            "box": None
        }

    # Convert image to grayscale first, and replicate to 3 channels to match YOLOv8 training distribution (Roboflow)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    yolo_input = cv2.merge([gray, gray, gray])

    # 1. Run YOLOv8 on grayscale/3-channel input to localize the panel and obtain bounding box coordinates
    yolo_results = yolo_model(yolo_input, conf=0.05)
    yolo_result = yolo_results[0]
    yolo_boxes = yolo_result.boxes

    if len(yolo_boxes) == 0:
        print(">>> ResNet API predicted: Unknown (no YOLO detections)")
        return {
            "class": "Unknown",
            "confidence": 0.0,
            "recommendation": "Unable to identify solar panel clearly. Please ensure the panel is centered in frame.",
            "box": None
        }

    # Filter detections using class-specific thresholds and background hallucination filters
    valid_boxes = []
    for i in range(len(yolo_boxes)):
        cls_idx = int(yolo_boxes.cls[i])
        conf_val = float(yolo_boxes.conf[i])
        w = float(yolo_boxes.xywhn[i][2])
        h = float(yolo_boxes.xywhn[i][3])
        area = w * h

        threshold = CLASS_THRESHOLDS.get(cls_idx, 0.15)
        if conf_val < threshold:
            continue

        # Skip massive bounding boxes ONLY if confidence is low (indicates background hallucination)
        if cls_idx != 1 and area > MAX_BOX_AREA_RATIO and conf_val < 0.35:
            continue

        valid_boxes.append((cls_idx, conf_val, i))

    if len(valid_boxes) == 0:
        print(">>> ResNet API predicted: Unknown (all detections filtered out below thresholds)")
        return {
            "class": "Unknown",
            "confidence": 0.0,
            "recommendation": "Unable to identify solar panel clearly. Please ensure the panel is centered in frame.",
            "box": None
        }

    # Select the box with the largest area to crop, matching ResNet's panel-level training crops
    best_idx = -1
    max_area = -1.0
    for cls_idx, conf_val, idx in valid_boxes:
        w = float(yolo_boxes.xywhn[idx][2])
        h = float(yolo_boxes.xywhn[idx][3])
        area = w * h
        if area > max_area:
            max_area = area
            best_idx = idx

    box_coords = [float(val) for val in yolo_boxes.xyxyn[best_idx].tolist()]

    # Crop the localized panel region from the ORIGINAL COLOR BGR image
    x1, y1, x2, y2 = yolo_boxes.xyxy[best_idx].tolist()
    x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
    h_img, w_img = img.shape[:2]
    x1 = max(0, min(x1, w_img))
    y1 = max(0, min(y1, h_img))
    x2 = max(0, min(x2, w_img))
    y2 = max(0, min(y2, h_img))

    if x2 > x1 and y2 > y1:
        crop_img = img[y1:y2, x1:x2]
    else:
        crop_img = img
        
    # 2. Preprocess crop and run inference with ResNet-50
    input_tensor = transform(crop_img).unsqueeze(0).to(device)
    
    with torch.no_grad():
        outputs = model(input_tensor)
        probabilities = torch.softmax(outputs, dim=1)[0]
        cls_idx = torch.argmax(probabilities).item()
        confidence = probabilities[cls_idx].item()
        
    raw_class = class_names[cls_idx]
    mapped_label = LABEL_MAPPING.get(raw_class, "Unknown")
    recommendation = RECOMMENDATIONS.get(mapped_label, "Inspection recommended.")
    
    # 3. Find the most appropriate bounding box coordinate for the predicted class
    panel_coords = [float(val) for val in yolo_boxes.xyxyn[best_idx].tolist()]
    panel_xyxy = yolo_boxes.xyxy[best_idx].tolist()
    box_coords = None
    
    if mapped_label == "Bird Drop":
        # Look for YOLO boxes of class 0 (Bird drop) in all raw yolo_boxes with confidence >= 0.02
        matching_boxes = []
        for i in range(len(yolo_boxes)):
            if int(yolo_boxes.cls[i]) == 0 and float(yolo_boxes.conf[i]) >= 0.02:
                matching_boxes.append(i)
        if matching_boxes:
            best_box_idx = max(matching_boxes, key=lambda i: float(yolo_boxes.conf[i]))
            
            # Check size of the best box. If it's a huge box (area >= 0.20 or w >= 0.80), refine it!
            w = float(yolo_boxes.xywhn[best_box_idx][2])
            h = float(yolo_boxes.xywhn[best_box_idx][3])
            area = w * h
            
            if area < 0.20 and w < 0.80 and h < 0.80:
                box_coords = [float(val) for val in yolo_boxes.xyxyn[best_box_idx].tolist()]
            else:
                # Refine using OpenCV
                box_coords = get_refined_defect_box(img, yolo_boxes.xyxy[best_box_idx].tolist(), "Bird Drop")
        else:
            # Fallback to refining the panel coordinates
            box_coords = get_refined_defect_box(img, panel_xyxy, "Bird Drop")
                
    elif mapped_label == "Dusty":
        # Look for YOLO boxes of class 2 (Dusty) in all raw yolo_boxes with confidence >= 0.02
        matching_boxes = []
        for i in range(len(yolo_boxes)):
            if int(yolo_boxes.cls[i]) == 2 and float(yolo_boxes.conf[i]) >= 0.02:
                matching_boxes.append(i)
        if matching_boxes:
            best_box_idx = max(matching_boxes, key=lambda i: float(yolo_boxes.conf[i]))
            box_coords = [float(val) for val in yolo_boxes.xyxyn[best_box_idx].tolist()]
        else:
            box_coords = panel_coords
                
    elif mapped_label == "Physical Damage":
        # Look for YOLO boxes of class 3 (Electrical Damage) or 4 (Physical Damage) with confidence >= 0.02
        matching_boxes = []
        for i in range(len(yolo_boxes)):
            if int(yolo_boxes.cls[i]) in (3, 4) and float(yolo_boxes.conf[i]) >= 0.02:
                matching_boxes.append(i)
        if matching_boxes:
            best_box_idx = max(matching_boxes, key=lambda i: float(yolo_boxes.conf[i]))
            
            # Check size of the best box. If it's a huge box, refine it!
            w = float(yolo_boxes.xywhn[best_box_idx][2])
            h = float(yolo_boxes.xywhn[best_box_idx][3])
            area = w * h
            
            if area < 0.20 and w < 0.80 and h < 0.80:
                box_coords = [float(val) for val in yolo_boxes.xyxyn[best_box_idx].tolist()]
            else:
                # Refine using OpenCV
                box_coords = get_refined_defect_box(img, yolo_boxes.xyxy[best_box_idx].tolist(), "Physical Damage")
        else:
            # Fallback to refining the panel coordinates
            box_coords = get_refined_defect_box(img, panel_xyxy, "Physical Damage")
                
    elif mapped_label == "Clean":
        # For clean panel, we do not draw any bounding box (sets it to None)
        box_coords = None
    
    print(f">>> ResNet API predicted: raw_class={raw_class}, mapped={mapped_label}, confidence={confidence:.4f}, box={box_coords}")
    
    return {
        "class": mapped_label,
        "confidence": round(confidence, 4),
        "recommendation": recommendation,
        "box": box_coords
    }

@app.post("/retrain")
async def retrain(background_tasks: BackgroundTasks):
    background_tasks.add_task(run_retrain_script)
    return {"message": "Retraining triggered successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
