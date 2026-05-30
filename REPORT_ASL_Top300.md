# 📊 BÁO CÁO DATASET: ASL_Top300

> **Ngày tạo:** 05/03/2026  
> **Nguồn gốc:** ASL Citizen Dataset (`archive (2).zip`)  
> **Script tạo:** `extract_asl_v2.py`  
> **Mục đích:** Fine-tune / Training mô hình nhận dạng ngôn ngữ ký hiệu Mỹ (ASL)

---

## 1. 🎯 Tổng quan

Trích xuất **Top 300 từ/ký hiệu phổ biến nhất** từ bộ dữ liệu ASL Citizen gốc (~2700 từ), tổ chức lại theo cấu trúc phù hợp cho việc fine-tune model nhận dạng ngôn ngữ ký hiệu.

| Thông số | Giá trị |
|----------|---------|
| **Tổng classes** | **300** |
| **Tổng video** | **9,885** |
| **Train** | 4,698 videos (300 classes) |
| **Validation** | 1,081 videos (300 classes) |
| **Test** | 4,106 videos (300 classes) |
| **Tổng dung lượng** | **5.29 GB** (5,414 MB) |
| **Tổng participants (signers)** | **48 người** |
| **Label IDs** | 0 – 299 |

---

## 2. 📁 Cấu trúc thư mục

```
ASL_Top300/                          ← 5.29 GB
├── train/                           ← 4,698 videos, 300 folders
│   ├── 5DOLLARS/
│   │   ├── 015674395394813967-5 DOLLARS.mp4
│   │   └── ...
│   ├── ABOUT1/
│   ├── DOG1/
│   └── ... (300 class folders)
├── val/                             ← 1,081 videos, 300 folders
│   ├── 5DOLLARS/
│   └── ... (300 class folders)
├── test/                            ← 4,106 videos, 300 folders
│   ├── 5DOLLARS/
│   └── ... (300 class folders)
└── annotations/                     ← metadata & labels
    ├── train.csv                    (4,698 rows)
    ├── val.csv                      (1,081 rows)
    ├── test.csv                     (4,106 rows)
    ├── label_map.json               (300 entries)
    ├── label_map.txt                (300 lines)
    └── stats.csv                    (301 rows = header + 300 classes)
```

---

## 3. 👥 Phân chia Participants (Signer-Independent)

| Split | Số participants | Danh sách |
|-------|----------------|-----------|
| **Train** | 32 | P1, P2, P3, P4, P7, P8, P10, P11, P14, P15, P16, P20, P22, P23, P24, P25, P27, P28, P29, P30, P31, P32, P33, P34, P36, P37, P38, P40, P41, P46, P50, P51 |
| **Val** | 5 | P5, P12, P21, P26, P39 |
| **Test** | 11 | P6, P9, P17, P18, P35, P42, P43, P47, P48, P49, P52 |

> ⚠️ **Overlap giữa các split = 0** → Hoàn toàn **signer-independent**.  
> Người ký trong train KHÔNG xuất hiện trong val/test → Model học ký hiệu, không học phong cách cá nhân.

---

## 4. 📊 Thống kê video/class

### Phân bố video trên mỗi split

| Split | Min video/class | Max video/class | Mean | Median |
|-------|----------------|-----------------|------|--------|
| **Train** | 13 | 24 | 15.7 | 15.0 |
| **Val** | 2 | 7 | 3.6 | 3.5 |
| **Test** | 10 | 20 | 13.7 | 14.0 |

### Top 10 classes (nhiều video nhất)

| Gloss | Train | Val | Test | **Total** |
|-------|-------|-----|------|-----------|
| DOG1 | 24 | 4 | 17 | **45** |
| BASKETBALL1 | 19 | 5 | 20 | **44** |
| WHATFOR1 | 20 | 5 | 18 | **43** |
| BELT1 | 19 | 3 | 18 | **40** |
| BEE1 | 19 | 6 | 14 | **39** |
| DARK1 | 21 | 3 | 15 | **39** |
| DEAF1 | 20 | 4 | 15 | **39** |
| BITE1 | 21 | 4 | 14 | **39** |
| BREAKFAST1 | 21 | 3 | 15 | **39** |
| ELEVATOR1 | 19 | 5 | 15 | **39** |

### Bottom 10 classes (ít video nhất)

| Gloss | Train | Val | Test | **Total** |
|-------|-------|-----|------|-----------|
| CANNOT | 16 | 3 | 12 | **31** |
| CATCH2 | 16 | 3 | 12 | **31** |
| BATHROOM | 14 | 3 | 14 | **31** |
| BISON | 16 | 3 | 12 | **31** |
| BOLT | 15 | 3 | 13 | **31** |
| THREE | 14 | 3 | 14 | **31** |
| UNDERWEAR1 | 17 | 2 | 12 | **31** |
| AFRICA | 15 | 3 | 13 | **31** |
| ZOO | 16 | 3 | 12 | **31** |
| ACTOR | 15 | 3 | 13 | **31** |

> 📌 Class imbalance nhẹ: 31–45 video/class → Không cần oversampling cho hầu hết trường hợp.

---

## 5. 📄 Mô tả chi tiết từng file

### 5.1. `train.csv` / `val.csv` / `test.csv`

**Annotation file** — Mỗi row = 1 video, chứa đầy đủ thông tin cho training pipeline.

| Cột | Kiểu | Ví dụ | Mô tả |
|-----|------|-------|--------|
| `video_path` | string | `train\5DOLLARS\015674...-5 DOLLARS.mp4` | Đường dẫn tương đối đến file video |
| `gloss` | string | `5DOLLARS` | Tên từ vựng ASL (nhãn text cho con người đọc) |
| `label_id` | int | `0` | Nhãn số nguyên (0–299), dùng cho classification head |
| `participant_id` | string | `P30` | Mã người ký — xem giải thích ở mục 6 |
| `asl_lex_code` | string | `B_01_062` | Mã từ điển ASL-LEX — xem giải thích ở mục 6 |

**Mục đích:**
- Dùng trực tiếp làm input cho `DataLoader` (PyTorch / TensorFlow)
- `video_path` + `label_id` là đủ cho training cơ bản
- `participant_id` dùng để phân tích per-signer accuracy
- `asl_lex_code` dùng cho nghiên cứu ngôn ngữ học (optional)

---

### 5.2. `label_map.json`

**Ánh xạ Gloss → Label ID** (300 entries, sắp xếp alphabetical).

```json
{
  "5DOLLARS": 0,
  "ABOUT1": 1,
  "ACTION": 2,
  "ACTOR": 3,
  "ADVERTISE": 4,
  ...
  "WORKOUT": 295,
  "WORM": 296,
  "WRISTWATCH3": 297,
  "ZOO": 298,
  "ZOOMOFF": 299
}
```

**Mục đích:** Load vào model config, decode prediction số → text.

---

### 5.3. `label_map.txt`

**Ánh xạ Label ID → Gloss** (format tương thích MMAction2, SlowFast,...).

```
0 5DOLLARS
1 ABOUT1
2 ACTION
...
298 ZOO
299 ZOOMOFF
```

**Mục đích:** Nhiều framework (MMAction2, SlowFast, TimeSformer) dùng format `.txt` này.

---

### 5.4. `stats.csv`

**Thống kê số video theo class × split** (301 rows = header + 300 classes).

| Cột | Mô tả |
|-----|--------|
| `Gloss` | Tên từ vựng (index column) |
| `test` | Số video trong tập test |
| `train` | Số video trong tập train |
| `val` | Số video trong tập val |
| `total` | Tổng video của class đó |

**Mục đích:** Phân tích class imbalance, quyết định oversampling/undersampling, QA kiểm tra dữ liệu.

---

## 6. 📋 Giải thích các trường dữ liệu

### `participant_id` — Mã người tham gia
- Mỗi participant là một **người điếc/khiếm thính** tham gia quay video cho ASL Citizen
- Tổng cộng **48 signers** trong Top 300 (32 train + 5 val + 11 test)
- **0 overlap** giữa các split → **Signer-independent evaluation**
- Giúp model học **ký hiệu** chứ không "nhớ mặt" từng người
- Dùng để phân tích: "Model nhận đúng bao nhiêu % cho signer P6?"

### `asl_lex_code` — Mã ASL-LEX
- Mã tham chiếu đến [ASL-LEX Database](https://asl-lex.org/)
- Tổng **300 mã duy nhất** (1 mã = 1 class)
- Ví dụ: `B_01_062` (5DOLLARS), `B_02_072` (ABOUT1)
- Liên kết từ vựng ASL với thông tin ngôn ngữ học (tần suất, iconicity, v.v.)
- **Optional** cho fine-tune, hữu ích cho nghiên cứu

### `gloss` vs `label_id`
- `gloss` = tên text (`DOG1`), dễ đọc → dùng cho logging, visualization
- `label_id` = số nguyên (`0–299`) → dùng làm target cho `CrossEntropyLoss`

---

## 7. 🚀 Cách sử dụng cho Training

### 7.1. PyTorch — Ví dụ cơ bản

```python
import pandas as pd
import json

# Load annotations
train_df = pd.read_csv('ASL_Top300/annotations/train.csv')  # 4,698 rows
val_df   = pd.read_csv('ASL_Top300/annotations/val.csv')    # 1,081 rows
test_df  = pd.read_csv('ASL_Top300/annotations/test.csv')   # 4,106 rows

# Load label map
with open('ASL_Top300/annotations/label_map.json') as f:
    label_map = json.load(f)  # 300 classes

# Trong Dataset class:
# - Load video từ row['video_path']
# - Target = row['label_id'] (int, 0-299)

# Model config
num_classes = 300
```

### 7.2. Config tham khảo

```python
config = {
    'num_classes': 300,
    'train_videos': 4698,
    'val_videos': 1081,
    'test_videos': 4106,
    'input_size': (224, 224),    # tùy model
    'num_frames': 16,            # tùy model
    'label_map': 'ASL_Top300/annotations/label_map.json',
}
```

---

## 8. 📌 Các file scripts hỗ trợ

| File | Mô tả |
|------|--------|
| `extract_asl_v2.py` | **Script chính** — Trích xuất Top 300 từ ZIP gốc → tạo toàn bộ folder + annotations |
| `extract_asl.py` | Script v1 (cũ), chỉ trích video, không có annotation đầy đủ |
| `gen_report.py` | Thu thập thông tin từ folder → tạo `report_data.txt` |
| `inspect_zip.py` | Khám phá nội dung file ZIP gốc (CSV, cấu trúc, metadata) |
| `collect_stats.py` | Thu thập thống kê thực tế → `report_stats.txt` |

---

## 9. ✅ Checklist

- [x] Chạy `extract_asl_v2.py` → tạo folder `ASL_Top300/`
- [x] 300 classes, 9,885 videos tổng
- [x] Signer-independent: 0 overlap giữa train/val/test
- [x] Annotations đầy đủ: train.csv, val.csv, test.csv
- [x] Label map: JSON + TXT
- [x] Stats: phân tích class distribution
- [ ] Cấu hình model: `num_classes = 300`
- [ ] Test load video từ `video_path`

---

## 10. 🔗 Nguồn tham khảo

- **ASL Citizen Dataset:** Desai et al., "ASL Citizen: A Community-Sourced Dataset for Advancing Isolated Sign Language Recognition"
- **ASL-LEX Database:** https://asl-lex.org/
- **Script tạo dữ liệu:** `extract_asl_v2.py`

---

*Báo cáo tạo ngày 05/03/2026 với dữ liệu thực tế từ folder ASL_Top300.*
