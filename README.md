# SolarScan

Smart mobile AI solar panel inspection system. Point a phone at a solar panel,
get its condition and the maintenance action for it — capture → classify →
recommendation → dashboard.

Graduation project, Canadian International College. Five-member team; I owned the
ML pipeline end to end — dataset preparation, annotation, training, benchmarking
and evaluation.

**Try the model:** <https://saifeleslamelgalaly.github.io/> (runs in your browser)
**Weights + model card:** <https://huggingface.co/saifElgalaly/solarscan-yolov8n-cls>

---

## What it does

A photograph is classified into one of six panel conditions, each mapped to an action:

| Class | Action |
|---|---|
| Bird-drop | Cleaning required |
| Clean | No action needed |
| Dusty | Cleaning required |
| Electrical-damage | Technician inspection required |
| Physical-Damage | Panel replacement required |
| Snow-Covered | Remove snow |

Top-1 confidence below **0.5** returns `Unknown` instead of a class — without that
floor, an image that isn't a solar panel gets forced into one of the six.

## Architecture

```
Flutter app  ──upload──▶  PHP API (service_api.php)  ──▶  FastAPI ml_service
                                   │                            │
                                   │◀──── {class, confidence, ──┘
                                   ▼       recommendation}
                              MySQL  ──▶  PHP admin dashboard
```

## The model

Three architectures were trained and compared before one was chosen:

| Model | Task | Reported | Outcome |
|---|---|---|---|
| **YOLOv8n-cls** | Classification | **91.67% top-1** | **Deployed** — best on real phone photos, simplest to serve |
| ResNet-50 (+ crop) | Classification | ~97% val accuracy | Higher on paper, but two-stage and covered only 4 classes |
| Faster R-CNN + ResNet-50 FPN | Detection | 0.91 weighted acc / 0.86 macro-F1 | Produces boxes, but heavier and the box went unused |

The figures are not directly comparable — different tasks and class counts.
YOLOv8n-cls was selected on real-world smartphone performance and deployment
simplicity, not on the highest validation number.

### Read the accuracy honestly

**91.67% is an upper bound, not field accuracy.** Two measured reasons:

- The train/validation split has **35.8% overlap** — some validation images also
  appear in training. Bird-drop is the tell: 94% of its validation set is leaked.
- There is **no held-out test split**. Every figure is validation-set.

The documented next step is an MD5-deduplicated split and a retrain. See
[`ml_service/DATASET_REVIEW.md`](ml_service/DATASET_REVIEW.md).

## Layout

```
ml_service/        FastAPI service + YOLOv8n-cls training (the deployed model)
ml_fasterrcnn/     Faster R-CNN + ResNet-50 FPN detection experiment
ml_resnet/         Two-stage ResNet-50 classification experiment
backend_php/       Mobile API and admin dashboard (PHP, PDO, RBAC)
mobile/            Flutter app (Riverpod + Dio)
diagrams/          Data flow, ERD and class diagrams
db/schema.sql      MySQL schema
```

## Running it

**1. ML service**

```bash
cd ml_service
pip install -r requirements.txt
# Download best.pt from the Hugging Face repo above into
# runs/classify/solar_defect_classifier/weights/
python main.py            # serves on :8000
```

**2. Database** — create `solar_defect_db` and import `db/schema.sql`.

**3. PHP backend** — serve `backend_php/` under Apache (XAMPP). It calls the ML
service at `127.0.0.1:8000`.

**4. Flutter app**

```bash
cd mobile
flutter pub get
flutter run
```

## Training data

A **public solar panel image dataset** — 930 images across the six classes, split
726 train / 204 validation, with a 3.65:1 class imbalance (Bird-drop 252 …
Physical-Damage 69).

**The dataset is not my work and is not included in this repository.** Credit
belongs to its original authors.

## Notes on this repository

- **Model weights are not committed.** They live on the Hugging Face repo linked
  above — 159 MB of `.pth` and `.pt` files do not belong in git.
- **The database dump is schema only.** The demo admin account, its password hash
  and the scan rows are deliberately not published.
- `backend_php/db.php` carries the stock XAMPP development credentials
  (`root`, empty password). That is a local development default and **must** be
  changed for any real deployment.
- Known limitations from the project's own audit: mobile auth uses a dummy token
  rather than JWT, and the ML service URL is hardcoded. Both are documented as
  next steps rather than hidden.

---

Built by Saif Elgalaly. More work: <https://saifeleslamelgalaly.github.io/>
