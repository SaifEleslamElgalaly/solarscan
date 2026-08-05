import os
os.environ["CUDA_LAUNCH_BLOCKING"] = "1"

import cv2
import math
import torch
import numpy as np

from torch.utils.data import Dataset, DataLoader
from torchvision import transforms

from torchvision.models.detection import fasterrcnn_resnet50_fpn
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor

import torch.optim as optim
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
from tqdm import tqdm

# =========================================================
# CONFIG
# =========================================================

data_dir = "dataset"
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

class_names = ["Bird", "Dust", "Clean", "Electrical", "Physical"]
num_classes = len(class_names) + 1  # + background

transform = transforms.ToTensor()

# =========================================================
# DATASET COLLECTION
# =========================================================

def collect_dataset(folder):
    samples = []

    images = [f for f in os.listdir(folder)
              if f.lower().endswith((".jpg", ".png", ".jpeg"))]

    for img in images:
        base = os.path.splitext(img)[0]
        txt = os.path.join(folder, base + ".txt")

        if os.path.exists(txt):
            samples.append(img)

    return samples

# =========================================================
# DATASET
# =========================================================

class RCNN_Dataset(Dataset):
    def __init__(self, folder, samples):
        self.folder = folder
        self.samples = samples

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):

        img_name = self.samples[idx]
        base = os.path.splitext(img_name)[0]

        img_path = os.path.join(self.folder, img_name)
        txt_path = os.path.join(self.folder, base + ".txt")

        image = cv2.imread(img_path)
        if image is None:
            return self.__getitem__((idx + 1) % len(self))

        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        h, w = image.shape[:2]

        boxes = []
        labels = []

        with open(txt_path, "r") as f:
            lines = f.readlines()

        for line in lines:
            p = line.strip().split()
            if len(p) < 5:
                continue

            try:
                cls = int(float(p[0]))

                # VALID CLASS CHECK
                if cls < 0 or cls >= len(class_names):
                    continue

                xc, yc, bw, bh = map(float, p[1:5])

                if bw <= 0 or bh <= 0:
                    continue

                xc *= w
                yc *= h
                bw *= w
                bh *= h

                x1 = xc - bw / 2
                y1 = yc - bh / 2
                x2 = xc + bw / 2
                y2 = yc + bh / 2

                if x2 <= x1 or y2 <= y1:
                    continue

                boxes.append([x1, y1, x2, y2])
                labels.append(cls + 1)  # IMPORTANT SHIFT

            except:
                continue

        if len(boxes) == 0:
            return self.__getitem__((idx + 1) % len(self))

        boxes = torch.tensor(boxes, dtype=torch.float32)
        labels = torch.tensor(labels, dtype=torch.int64)

        target = {"boxes": boxes, "labels": labels}

        return transform(image), target

# =========================================================
# COLLATE
# =========================================================

def collate_fn(batch):
    return tuple(zip(*batch))

# =========================================================
# LOAD DATA
# =========================================================

samples = collect_dataset(data_dir)

train, val = train_test_split(samples, test_size=0.2, random_state=42)

train_ds = RCNN_Dataset(data_dir, train)
val_ds = RCNN_Dataset(data_dir, val)

train_loader = DataLoader(train_ds, batch_size=2, shuffle=True, collate_fn=collate_fn)
val_loader = DataLoader(val_ds, batch_size=2, shuffle=False, collate_fn=collate_fn)

# =========================================================
# MODEL
# =========================================================

model = fasterrcnn_resnet50_fpn(weights="DEFAULT")

in_features = model.roi_heads.box_predictor.cls_score.in_features
model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)

model = model.to(device)

optimizer = optim.Adam(model.parameters(), lr=1e-4)

# =========================================================
# TRAIN
# =========================================================

def train_one_epoch():
    model.train()
    total_loss = 0

    for images, targets in tqdm(train_loader):

        images = [img.to(device) for img in images]
        targets = [{k: v.to(device) for k, v in t.items()} for t in targets]

        loss_dict = model(images, targets)
        loss = sum(loss for loss in loss_dict.values())

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        total_loss += loss.item()

    return total_loss / len(train_loader)

# =========================================================
# EVALUATION (FIXED)
# =========================================================

def evaluate():

    model.eval()

    y_true = []
    y_pred = []

    with torch.no_grad():

        for images, targets in val_loader:

            images = [img.to(device) for img in images]
            outputs = model(images)

            for out, tgt in zip(outputs, targets):

                gt = tgt["labels"].cpu().numpy()
                pr = out["labels"].cpu().numpy()
                sc = out["scores"].cpu().numpy()

                keep = sc > 0.5
                pr = pr[keep]

                gt = gt - 1
                pr = pr - 1

                n = min(len(gt), len(pr))
                if n == 0:
                    continue

                y_true.extend(gt[:n])
                y_pred.extend(pr[:n])

    if len(y_true) == 0:
        print("No predictions")
        return

    labels = list(range(len(class_names)))

    print("\nACCURACY (approx):", np.mean(np.array(y_true) == np.array(y_pred)))

    print("\nCLASSIFICATION REPORT:\n")

    print(classification_report(
        y_true,
        y_pred,
        labels=labels,
        target_names=class_names,
        zero_division=0
    ))

    print("\nCONFUSION MATRIX:\n")

    print(confusion_matrix(
        y_true,
        y_pred,
        labels=labels
    ))

# =========================================================
# TRAIN LOOP
# =========================================================

for epoch in range(10):

    print(f"\nEPOCH {epoch+1}")

    loss = train_one_epoch()
    print("Loss:", loss)

    evaluate()

# =========================================================
# SAVE
# =========================================================
torch.save(model.state_dict(), "faster_rcnn_fixed.pth")
print("Saved model")
