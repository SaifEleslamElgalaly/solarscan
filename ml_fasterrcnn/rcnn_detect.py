import cv2
import torch
from torchvision import transforms
from torchvision.models.detection import fasterrcnn_resnet50_fpn
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor

# ==========================================
# CONFIG
# ==========================================

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

class_names = [
    "Bird",
    "Dust",
    "Clean",
    "Electrical",
    "Physical"
]

num_classes = len(class_names) + 1

MODEL_PATH = "faster_rcnn.pth"
IMAGE_PATH = "test.jpg"

# ==========================================
# LOAD MODEL
# ==========================================

model = fasterrcnn_resnet50_fpn(weights=None)

in_features = model.roi_heads.box_predictor.cls_score.in_features
model.roi_heads.box_predictor = FastRCNNPredictor(
    in_features,
    num_classes
)

model.load_state_dict(
    torch.load(MODEL_PATH, map_location=device)
)

model.to(device)
model.eval()

# ==========================================
# LOAD IMAGE
# ==========================================

image = cv2.imread(IMAGE_PATH)
orig = image.copy()

image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

transform = transforms.ToTensor()
tensor = transform(image_rgb).to(device)

# ==========================================
# DETECTION
# ==========================================

with torch.no_grad():
    output = model([tensor])[0]

boxes = output["boxes"].cpu().numpy()
labels = output["labels"].cpu().numpy()
scores = output["scores"].cpu().numpy()

# ==========================================
# DRAW RESULTS
# ==========================================

CONF = 0.5

for box, label, score in zip(boxes, labels, scores):

    if score < CONF:
        continue

    x1, y1, x2, y2 = map(int, box)

    cls_name = class_names[label - 1]

    cv2.rectangle(
        orig,
        (x1, y1),
        (x2, y2),
        (0, 255, 0),
        2
    )

    text = f"{cls_name}: {score:.2f}"

    cv2.putText(
        orig,
        text,
        (x1, y1 - 10),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.6,
        (0, 255, 0),
        2
    )

# ==========================================
# SAVE / SHOW
# ==========================================

cv2.imwrite("result.jpg", orig)

cv2.imshow("Detection", orig)
cv2.waitKey(0)
cv2.destroyAllWindows()

print("Saved: result.jpg")