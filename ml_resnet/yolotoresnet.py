import os
import cv2
import torch

from torch.utils.data import Dataset, DataLoader
from torchvision import transforms, models
import torch.nn as nn
import torch.optim as optim

from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from tqdm import tqdm
from collections import defaultdict, Counter

# ======================
# CONFIG
# ======================
data_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "solar panel dataset"))
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ❗ FIXED: DO NOT SORT CLASS NAMES
class_names = ["Bird", "Dust", "Clean", "Physical"]
class_to_idx = {c: i for i, c in enumerate(class_names)}

# ======================
# CLASS PARSING (ROBUST)
# ======================
def get_class_from_filename(name):
    name = name.lower()
    for c in class_names:
        if c.lower() in name:
            return c
    return None

# ======================
# TRANSFORMS
# ======================
transform = transforms.Compose([
    transforms.ToPILImage(),
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

# =========================================================
# 1. COLLECT DATASET
# =========================================================
def collect_dataset(folder):
    samples = []

    images = [f for f in os.listdir(folder)
              if f.lower().endswith((".jpg", ".png", ".jpeg"))]

    stats = defaultdict(int)
    class_counts = defaultdict(int)

    print("\n=========== DATASET COLLECTION ===========\n")

    for img_name in images:
        base = os.path.splitext(img_name)[0]
        txt_path = os.path.join(folder, base + ".txt")

        if not os.path.exists(txt_path):
            stats["missing"] += 1
            continue

        try:
            with open(txt_path, "r") as f:
                lines = [l.strip() for l in f.readlines() if l.strip()]
        except:
            stats["read_error"] += 1
            continue

        if len(lines) == 0:
            stats["empty"] += 1
            continue

        class_name = get_class_from_filename(base)
        if class_name is None:
            stats["no_class"] += 1
            continue

        valid = False
        for l in lines:
            p = l.split()
            if len(p) >= 5:
                try:
                    list(map(float, p[:5]))
                    valid = True
                    break
                except:
                    pass

        if not valid:
            stats["bad_format"] += 1
            continue

        samples.append(img_name)
        class_counts[class_name] += 1
        stats["ok"] += 1

    print("\n=========== SUMMARY ===========")
    for k, v in stats.items():
        print(f"{k:12s}: {v}")

    print("\n=========== CLASS DISTRIBUTION ===========")
    for c in class_names:
        print(f"{c:15s}: {class_counts[c]}")

    return samples, class_counts


# =========================================================
# 2. DATASET CLASS
# =========================================================
class YOLOCropDataset(Dataset):
    def __init__(self, folder, samples):
        self.folder = folder
        self.samples = samples
        self.cached_data = []
        
        print(f"Pre-loading and caching {len(samples)} samples in memory...")
        for idx in range(len(samples)):
            try:
                img_name = self.samples[idx]
                base = os.path.splitext(img_name)[0]

                img_path = os.path.join(self.folder, img_name)
                txt_path = os.path.join(self.folder, base + ".txt")

                img = cv2.imread(img_path)
                if img is None:
                    continue

                h, w = img.shape[:2]

                class_name = get_class_from_filename(base)
                label = class_to_idx[class_name]

                with open(txt_path, "r") as f:
                    lines = [l.strip().split() for l in f.readlines()]

                boxes = []
                for p in lines:
                    if len(p) < 5:
                        continue
                    try:
                        _, xc, yc, bw, bh = map(float, p[:5])
                        boxes.append((xc, yc, bw, bh))
                    except:
                        continue

                if len(boxes) == 0:
                    continue

                # largest box
                xc, yc, bw, bh = max(boxes, key=lambda b: b[2] * b[3])

                xc, yc, bw, bh = xc * w, yc * h, bw * w, bh * h

                x1 = max(0, int(xc - bw / 2))
                y1 = max(0, int(yc - bh / 2))
                x2 = min(w, int(xc + bw / 2))
                y2 = min(h, int(yc + bh / 2))

                if x2 <= x1 or y2 <= y1:
                    continue

                crop = img[y1:y2, x1:x2]

                if crop is None or crop.size == 0:
                    continue
                
                tensor_crop = transform(crop)
                self.cached_data.append((tensor_crop, torch.tensor(label, dtype=torch.long)))
            except Exception as e:
                continue
        print(f"Successfully cached {len(self.cached_data)} valid samples.")

    def __len__(self):
        return len(self.cached_data)

    def __getitem__(self, idx):
        return self.cached_data[idx]


# =========================================================
# 3. LOAD DATA
# =========================================================
all_samples, class_counts = collect_dataset(data_dir)

# =========================================================
# 4. CLASS WEIGHTS (IMPORTANT FIX)
# =========================================================
total = sum(class_counts[c] for c in class_names)

class_weights = []
for c in class_names:
    freq = class_counts[c]
    weight = total / (freq + 1e-6)
    class_weights.append(weight)

class_weights = torch.tensor(class_weights, dtype=torch.float).to(device)

print("\nClass weights:", class_weights)

# =========================================================
# 5. TRAIN / VAL SPLIT
# =========================================================
train_samples, val_samples = train_test_split(
    all_samples,
    test_size=0.2,
    random_state=42,
    shuffle=True
)

train_ds = YOLOCropDataset(data_dir, train_samples)
val_ds = YOLOCropDataset(data_dir, val_samples)

train_loader = DataLoader(train_ds, batch_size=32, shuffle=True)
val_loader = DataLoader(val_ds, batch_size=32, shuffle=False)

print(f"\nTrain: {len(train_ds)} | Val: {len(val_ds)}")

# =========================================================
# 6. MODEL
# =========================================================
model = models.resnet50(weights="IMAGENET1K_V1")

# Freeze early layers for extremely fast training on CPU
for name, param in model.named_parameters():
    if "layer4" in name or "fc" in name:
        param.requires_grad = True
    else:
        param.requires_grad = False

model.fc = nn.Linear(model.fc.in_features, len(class_names))
model = model.to(device)

criterion = nn.CrossEntropyLoss(weight=class_weights)
optimizer = optim.Adam(filter(lambda p: p.requires_grad, model.parameters()), lr=1e-4)

# =========================================================
# 7. EVALUATION
# =========================================================
def evaluate(model, loader):
    model.eval()

    preds_all, labels_all = [], []
    correct, total = 0, 0

    with torch.no_grad():
        for imgs, labels in loader:
            imgs, labels = imgs.to(device), labels.to(device)

            outputs = model(imgs)
            preds = torch.argmax(outputs, dim=1)

            preds_all.extend(preds.cpu().numpy())
            labels_all.extend(labels.cpu().numpy())

            correct += (preds == labels).sum().item()
            total += labels.size(0)

    print("\nAccuracy:", correct / total)
    print(classification_report(labels_all, preds_all, target_names=class_names))
    print(confusion_matrix(labels_all, preds_all))


# =========================================================
# 8. TRAIN LOOP
# =========================================================
for epoch in range(5):

    print(f"\n======== EPOCH {epoch+1}/5 ========\n")

    model.train()

    running_loss = 0
    correct = 0
    total = 0

    loop = tqdm(train_loader, desc="Training")

    for imgs, labels in loop:
        imgs, labels = imgs.to(device), labels.to(device)

        optimizer.zero_grad()
        outputs = model(imgs)

        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()

        running_loss += loss.item()

        preds = torch.argmax(outputs, dim=1)
        correct += (preds == labels).sum().item()
        total += labels.size(0)

        loop.set_postfix(loss=loss.item(), acc=correct / total)

    print(f"\nLoss: {running_loss/len(train_loader):.4f}")
    print(f"Train Acc: {correct/total:.4f}")

    print("\nValidation:")
    evaluate(model, val_loader)


# =========================================================
# 9. SAVE MODEL
# =========================================================
torch.save(model.state_dict(), "resnet50_yolo_optimized.pth")
print("Training complete.")