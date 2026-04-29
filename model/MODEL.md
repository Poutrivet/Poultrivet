# YOLOv8 Disease Detection Model

## Overview
YOLOv8-based classification model trained on poultry dropping images 
for automated disease detection.

## Classes
| Index | Class | Disease | Severity |
|-------|-------|---------|----------|
| 0 | COCCI | Coccidiosis | HIGH |
| 1 | NCD | Newcastle Disease | HIGH |
| 2 | SALMONELLA | Salmonella | HIGH |
| 3 | SEHAT | Healthy | LOW |

## Architecture
- Base: YOLOv8 (Ultralytics)
- Task: Classification
- Framework: PyTorch 2.11
- Model size: 5.96 MB

## Performance
- Average confidence: 94.2%
- Inference time: ~4.2 seconds on CPU
- Input size: 640 × 640

## Training
- Framework: Google Colab
- Dataset: Poultry dropping images (field + augmented)
- Classes: 4

## Usage
The model is served through the FastAPI backend.
Send a POST request to `/analyse-dropping` with an image file.
