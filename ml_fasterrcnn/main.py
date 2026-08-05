import os
import io
from fastapi import FastAPI, UploadFile, File, BackgroundTasks
import torch
from torchvision.models.detection import fasterrcnn_resnet50_fpn
import torchvision.transforms.functional as F
from PIL import Image, ImageOps

app = FastAPI(title="Solar Faster R-CNN Detection Service")

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# --- Class mapping (canonical order, matching rcnn.py and the trained weights) ---
# Faster R-CNN reserves label 0 for background, so the foreground model labels are
# the 0-based class_names list in rcnn.py shifted by +1:
#   rcnn.py:  0=Bird, 1=Dust, 2=Clean, 3=Electrical, 4=Physical
#   here:     1=Bird, 2=Dust, 3=Clean, 4=Electrical, 5=Physical
CLASS_NAMES = {
    1: "Bird-drop",
    2: "Dusty",
    3: "Clean",
    4: "Electrical-damage",
    5: "Physical-Damage",
}
NUM_CLASSES = 6  # 5 foreground + background

# Model label of the "Clean" class, derived from CLASS_NAMES so it stays correct
# even if the names are edited. Every other foreground label is treated as a defect.
CLEAN_LABEL = next(lbl for lbl, name in CLASS_NAMES.items() if name == "Clean")  # = 3

RECOMMENDATIONS = {
    "Bird-drop": "Clean the panel surface to restore efficiency",
    "Dusty": "Clean the panel surface to restore efficiency",
    "Electrical-damage": "Technician inspection required",
    "Physical-Damage": "Panel replacement required - structural damage detected",
    "Clean": "No action needed - panel is operating normally",
}

# A defect must score at least this to be reported. Defects measured 0.84-0.96
# in testing while clean panels peaked around 0.4, so 0.5 separates them well.
DEFECT_THRESHOLD = 0.5
# Below this top score the image is treated as unclear / not a panel.
MIN_SCORE_FLOOR = 0.20

MODEL_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "faster_rcnn.pth")
)

model = fasterrcnn_resnet50_fpn(weights=None, num_classes=NUM_CLASSES)
if os.path.exists(MODEL_PATH):
    model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
    print(f"Loaded Faster R-CNN weights from {MODEL_PATH}")
else:
    print(f"WARNING: weights not found at {MODEL_PATH}. Using untrained model.")
model = model.to(device)
model.eval()


def _unknown(reason):
    print(f">>> Faster R-CNN predicted: Unknown ({reason})")
    return {
        "class": "Unknown",
        "confidence": 0.0,
        "recommendation": "Unable to identify solar panel clearly. Please ensure the panel is centered in frame.",
        "box": None,
    }


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    contents = await file.read()
    try:
        img = Image.open(io.BytesIO(contents))
        # Honor EXIF orientation so the box is normalized in the same orientation
        # the phone/dashboard displays the image (photos come in EXIF-rotated).
        img = ImageOps.exif_transpose(img).convert("RGB")
    except Exception as e:
        return _unknown(f"decode failed: {e}")

    W, H = img.size
    tensor = F.to_tensor(img).to(device)

    with torch.no_grad():
        out = model([tensor])[0]

    boxes = out["boxes"]
    labels = out["labels"]
    scores = out["scores"]

    if scores.numel() == 0 or float(scores.max()) < MIN_SCORE_FLOOR:
        return _unknown("no confident detections")

    # Find the highest-scoring DEFECT detection (any foreground class except Clean)
    # above threshold. Defects are every label in CLASS_NAMES other than CLEAN_LABEL.
    best_idx = -1
    best_score = -1.0
    for i in range(scores.numel()):
        lbl = int(labels[i])
        sc = float(scores[i])
        if lbl in CLASS_NAMES and lbl != CLEAN_LABEL and sc >= DEFECT_THRESHOLD and sc > best_score:
            best_score = sc
            best_idx = i

    # No confident defect found -> treat the panel as Clean (no box drawn).
    if best_idx == -1:
        print(">>> Faster R-CNN predicted: Clean (no defect above threshold)")
        return {
            "class": "Clean",
            "confidence": round(float(scores.max()), 4),
            "recommendation": RECOMMENDATIONS["Clean"],
            "box": None,
        }

    name = CLASS_NAMES.get(int(labels[best_idx]), "Unknown")
    x1, y1, x2, y2 = boxes[best_idx].tolist()
    box_norm = [x1 / W, y1 / H, x2 / W, y2 / H]  # normalized 0..1, matches the app/DB contract

    print(f">>> Faster R-CNN predicted: {name}, confidence={best_score:.4f}, box={box_norm}")
    return {
        "class": name,
        "confidence": round(best_score, 4),
        "recommendation": RECOMMENDATIONS.get(name, "Inspection recommended."),
        "box": box_norm,
    }


@app.post("/retrain")
async def retrain(background_tasks: BackgroundTasks):
    # No retraining pipeline is wired for the Faster R-CNN model yet; kept for API parity.
    return {"message": "Retraining is not configured for the Faster R-CNN service."}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
