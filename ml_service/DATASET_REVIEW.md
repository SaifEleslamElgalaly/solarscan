# Dataset Review — SolarScan `ml_service`

**Dataset path:** `D:\xampp\htdocs\solar\ml_service\dataset`
**Consumed by:** `ml_service/train.py` (Ultralytics YOLOv8n-cls, `imgsz=224`, `epochs=10`, `batch=16`)
**Date:** 2026-06-17
**Method:** every number below comes from walking the folder and hashing files (MD5) with Python — no sampling for counts/leakage; all 930 images opened with PIL for property/corruption checks.

---

## 1. Dataset summary

| Property | Value |
|---|---|
| Task / format | **Image classification** — one folder per class (no label files, no bbox/COCO/VOC) |
| Splits present | `train`, `val` — **no `test` split** |
| Classes | **6** |
| Total images | **930** (`.jpg` 921, `.jpeg` 4, `.png` 5) |
| Train / Val | **726 / 204** → ratio **78.1% / 21.9%** (≈ 80/20) |
| Stray files | `train/Bird-drop/desktop.ini` (Windows system file, not an image) + `train.cache`, `val.cache` (Ultralytics) |
| Metadata files | **None** — no `data.yaml`, `README`, or `classes.txt`; class names come only from folder names |
| Corrupt / zero-byte | **0 / 0** |

> Note: the true image count is **930**, not 931. A previous count that reported 727 train included `desktop.ini`; the actual image total is 726 train + 204 val = 930.

---

## 2. Per-class distribution

| Class | Train | Val | **Total** | % of dataset | Flag |
|---|---:|---:|---:|---:|---|
| Bird-drop | 185 | 67 | **252** | 27.1% | largest; **heavy val leakage (see §3)** |
| Clean | 154 | 39 | **193** | 20.8% | — |
| Dusty | 152 | 38 | **190** | 20.4% | — |
| Snow-Covered | 98 | 25 | **123** | 13.2% | — |
| Electrical-damage | 82 | 21 | **103** | 11.1% | ⚠ under-represented |
| Physical-Damage | 55 | 14 | **69** | 7.4% | ⚠ **rarest — only 14 val images** |
| **TOTAL** | **726** | **204** | **930** | 100% | |

- **Imbalance ratio:** largest : smallest = 252 : 69 = **3.65 : 1**.
- Per-class train/val ratios are ~80/20 for every class **except Bird-drop (73/27)** — its val share is inflated by duplicate images (see §3).

---

## 3. Quality findings (evidence-based)

### 3.1 🚩 Train↔Val data leakage (critical)
Byte-identical images (same MD5) appear in **both** train and val:

| Class | Val total | Val images that are exact copies of a train image | % of val leaked |
|---|---:|---:|---:|
| **Bird-drop** | 67 | **63** | **94.0%** |
| Electrical-damage | 21 | 3 | 14.3% |
| Physical-Damage | 14 | 2 | 14.3% |
| Snow-Covered | 25 | 2 | 8.0% |
| Dusty | 38 | 2 | 5.3% |
| Clean | 39 | 1 | 2.6% |
| **TOTAL** | **204** | **73** | **35.8%** |

- **73 of 204 validation images (35.8%) are exact duplicates of training images.** All leaks are same-class.
- 61 of these even share the **same filename** in `train/Bird-drop` and `val/Bird-drop` (e.g. `Bird (101).jpg`, `Bird (102).jpg`, `Bird (12).jpg`).
- **Effective clean validation set = 204 − 73 = 131 images.** For Bird-drop, clean val = 67 − 63 = **4 images**.
- **Consequence:** Bird-drop's "perfect recall (1.00, 67/67)" in the model's confusion matrix is measuring *memorization*, not generalization. The reported **91.67% top-1 accuracy is inflated** because more than a third of the validation set was seen during training.
- **Root cause:** the source collection contains duplicate images saved under different `Word (N)` numbers; `prepare_data.py` splits randomly *per file* with no content-dedup, so copies land on both sides.

### 3.2 🚩 Contradictory labels (same image in two classes)
Two image contents appear under **different class folders** — i.e. the same picture is labeled as two different defects:

1. One image is filed as **both Bird-drop and Physical-Damage**:
   `train/Bird-drop/Bird (176|184|22|46|57).jpg` + `val/Bird-drop/Bird (57).jpg` **and** `train/Physical-Damage/Physical (51).jpg` (all identical bytes).
2. One image is filed as **both Bird-drop and Dusty**:
   `train/Bird-drop/Bird (193).jpg` **and** `train/Dusty/Dust (187).jpg`.

### 3.3 Within-train redundancy
- Train has **726 files but only 648 unique image contents → 78 redundant duplicate copies** inside the training set (wasted/over-weighted samples, concentrated in Bird-drop).

### 3.4 Image properties
- **Resolution is highly inconsistent:** width 149–6240 px (median 720), height 110–5376 px (median 631); **446 distinct resolutions**. Aspect ratios spread across portrait (197), ~square (72), landscape (456), wide (205). (Lower impact for classification since everything is resized to 224×224, but it signals mixed/web-scraped sources.)
- **Mixed color/format:** 911 RGB + **19 RGBA**; 907 JPEG + 21 PNG + **2 MPO** (multi-picture JPEG). RGBA/MPO can cause channel-handling inconsistencies.

### 3.5 Source hints
- No export metadata. **All 930 filenames follow a hand-curated `Word (N)` pattern** (`Bird (12).jpg`, `Dust (10).jpg`, `Snow (1).jpg`) — this is **not a Roboflow export format** (which uses `*_jpg.rf.<hash>` names). The images may still originate from online/Roboflow sources but were manually renamed and sorted into class folders. The thesis cites Roboflow Universe; treat that as the likely *origin* of raw images, not the format of this assembled set.

---

## 4. Strengths (each tied to a number)
- **Clean, simple, correctly-structured classification layout** — 6 class folders consistent across train/val, class names exactly matching the served model's labels (`Bird-drop, Clean, Dusty, Electrical-damage, Physical-Damage, Snow-Covered`).
- **No corrupt or zero-byte files** — 930/930 images open successfully.
- **Reasonable overall split ratio** — 78.1/21.9, close to the intended 80/20, and per-class ratios are ~80/20 (except Bird-drop, distorted by duplicates).
- **Three classes have adequate volume** — Bird-drop (252), Clean (193), Dusty (190) each exceed ~190 images, enough for a transfer-learned classifier to learn the dominant soiling categories.
- **Predominantly RGB JPEG (907/930)** — format is consistent enough for a standard pipeline with only minor outliers.

## 5. Weaknesses (each tied to a number + recommendation)
- **Severe train/val leakage (73/204 = 35.8%; Bird-drop 63/67 = 94%).** → **De-duplicate by content hash, then re-split.** This is the single most important fix; without it, all validation metrics overstate real performance.
- **Inflated headline metric.** The 91.67% top-1 and Bird-drop's perfect recall are not trustworthy because the model is validated on ~36% of images it trained on. → Re-evaluate on the **131 clean val images** (Bird-drop only has 4 clean) after re-splitting; expect lower, honest numbers.
- **Class imbalance 3.65:1; two rare classes.** Physical-Damage = 69 total / **14 val**, Electrical-damage = 103 / **21 val**. With only 14 val samples, a single misclassification swings Physical-Damage recall by ~7 points. → **Collect more samples for these two defects, and/or apply class weighting and targeted augmentation**; report per-class CIs given the tiny support.
- **No test split.** Model selection and reporting both happen on `val`, so there is no truly held-out set. → **Carve out a content-deduplicated test split (e.g. 70/15/15)** and report final numbers only on it.
- **Contradictory labels (§3.2): 2 images appear in two class folders each.** → Manually review and assign each to a single correct class (or remove); audit the rest of Bird-drop, which is the noisiest class.
- **Within-train redundancy (78 duplicate copies).** → Removing them shrinks Bird-drop's effective dominance and reduces over-fitting to repeated samples.
- **Resolution/format inconsistency (446 resolutions, 19 RGBA, 2 MPO).** → **Normalize all images to RGB** and (optionally) cap extreme resolutions on ingest to avoid silent channel/format edge cases.
- **Small absolute size (930 images, 726 for training).** Adequate only for a fine-tuned nano model; thin for robust real-world generalization. → Grow the dataset, especially the damage classes.

---

## 6. Overall verdict

**Is the dataset adequate for the project goal (real-time solar-panel defect detection)?**
**Partially — adequate as a working prototype/classification baseline, but NOT adequate for trustworthy evaluation or robust deployment as-is.** The structure is clean and the three dominant classes have reasonable volume, so a fine-tuned classifier can learn the common soiling cases. However, **35.8% train/val leakage means the reported accuracy cannot be believed**, the two damage classes are too small to evaluate reliably (14 and 21 val images), there is no held-out test set, and a few labels are contradictory. Also note the task name says "detection" but this dataset supports **classification only** (no bounding boxes), consistent with the served ml_service model.

**Top 3 fixes that would most improve real model performance/credibility:**
1. **De-duplicate by content hash and re-split (train/val/test) with no shared images.** Eliminates the 35.8% leakage and produces an honest accuracy figure — the prerequisite for every other measurement.
2. **Grow + balance the two rare damage classes** (Physical-Damage 69, Electrical-damage 103) via more data, class weighting, and augmentation; add per-class confidence intervals given the tiny support.
3. **Add a real held-out test split and normalize inputs** (all → RGB, fix the 2 MPO / 19 RGBA files, resolve the 2 contradictory-label images), so final metrics are measured once, cleanly, on unseen data.

---
*Cross-reference: the leakage here directly affects the metrics quoted in the thesis — see `solar/THESIS_REVIEW_REPORT.md`. The 91.67% top-1 / Bird-drop perfect recall should be read as upper bounds, not generalization estimates.*
