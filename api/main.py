import os
import json
import tempfile
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import uvicorn

# ── 1. LOAD RISK DATA FROM JSON ──────────────────────────────

print("Loading satellite risk data...")

with open('uganda_risk_data.json', 'r') as f:
risk_json = json.load(f)

risk_data = risk_json['districts']
meta =      risk_json['meta']

print(f"Loaded {len(risk_data)} districts!")

# ── 2. LOAD YOLOV8 MODEL ─────────────────────────────────────

print("Loading YOLOv8 model...")

model = YOLO('best.pt')

print("Model loaded!")

# ── 3. CLASS DEFINITIONS ─────────────────────────────────────

CLASS_LABELS = {
'COCCI':     'Coccidiosis',
'NCD':       'Newcastle Disease',
'SALMONELLA': 'Salmonella',
'SEHAT':     'Healthy'
}

RECOMMENDATIONS = {
'COCCI': (
'Coccidiosis detected. Isolate affected birds immediately. '
'Improve litter dryness and ventilation. '
'Consult a veterinarian for anticoccidial treatment.'
),
'NCD': (
'Newcastle Disease detected. This is highly contagious. '
'Isolate flock immediately and report to your district '
'veterinary officer. Do not move birds.'
),
'SALMONELLA': (
'Salmonella detected. Isolate affected birds. '
'Improve hygiene and sanitation. '
'Consult veterinarian for antibiotic treatment.'
),
'SEHAT': (
'Your flock appears healthy. Continue good biosecurity '
'practices and monitor regularly.'
)
}

RISK_LEVELS = {
'COCCI':      'HIGH',
'NCD':        'HIGH',
'SALMONELLA': 'HIGH',
'SEHAT':      'LOW'
}

# ── 4. DROPPING ANALYSIS FUNCTION ────────────────────────────

def analyse_dropping(image_bytes):
with tempfile.NamedTemporaryFile(
suffix='.jpg', delete=False
) as tmp:
tmp.write(image_bytes)
tmp_path = tmp.name

try:
results = model.predict(
source=tmp_path,
conf=0.25,
verbose=False
)
result = results[0]

if len(result.boxes) > 0:
confidences = result.boxes.conf.tolist()
classes =     result.boxes.cls.tolist()
best_idx =    confidences.index(max(confidences))
detected =    model.names[int(classes[best_idx])]
confidence =  round(confidences[best_idx] * 100, 2)
else:
detected =   'SEHAT'
confidence = 85.0

finally:
os.unlink(tmp_path)

return {
'disease':        CLASS_LABELS.get(detected, detected),
'raw_class':      detected,
'confidence':     confidence,
'risk_level':     RISK_LEVELS.get(detected, 'UNKNOWN'),
'is_healthy':     detected == 'SEHAT',
'recommendation': RECOMMENDATIONS.get(
detected, 'Consult a veterinarian.'
)
}

# ── 5. FASTAPI APP ───────────────────────────────────────────

app = FastAPI(
title="PoultryGuard API",
description=(
"Satellite risk mapping and AI dropping analysis "
"for Uganda poultry farmers"
),
version="1.0.0"
)

app.add_middleware(
CORSMiddleware,
allow_origins=["*"],
allow_methods=["*"],
allow_headers=["*"]
)

# ── 6. ENDPOINTS ─────────────────────────────────────────────

@app.get("/")
def home():
return {
"status":  "PoultryGuard API is running",
"version": "1.0.0",
"endpoints": {
"GET  /risk-map":          "All Uganda district risk scores",
"GET  /district/{name}":   "Specific district details",
"GET  /summary":           "National risk summary",
"POST /analyse-dropping":  "Upload dropping image for diagnosis"
}
}

@app.get("/risk-map")
def get_risk_map():
return {
"status":          "success",
"total_districts": len(risk_data),
"summary": {
"high_risk":   meta['high_risk_count'],
"medium_risk": meta['medium_risk_count'],
"low_risk":    meta['low_risk_count']
},
"districts":   risk_data,
"data_source": "Sentinel-2 & MODIS Satellite Imagery",
"last_updated": meta['last_updated']
}

@app.get("/summary")
def get_summary():
return {
"status":              "success",
"total_monitored":     meta['total_districts'],
"high_risk_count":     meta['high_risk_count'],
"medium_risk_count":   meta['medium_risk_count'],
"low_risk_count":      meta['low_risk_count'],
"most_common_disease": meta['most_common_disease'],
"disease_frequency":   meta['disease_frequency'],
"top5_risk_districts": meta['top5_risk_districts'],
"last_updated":        meta['last_updated']
}

@app.get("/district/{district_name}")
def get_district(district_name: str):
district = next(
(d for d in risk_data
if d['district'].lower() == district_name.lower()),
None
)

if not district:
raise HTTPException(
status_code=404,
detail=f"District '{district_name}' not found"
)

return {
"status":          "success",
"district":        district['district'],
"risk_level":      district['risk_level'],
"risk_score":      district['risk_score'],
"diseases_flagged": district['diseases_flagged'],
"environmental_conditions": {
"vegetation_ndvi":      district['ndvi'],
"moisture_index":       district['moisture'],
"temperature_celsius":  district['temperature'],
"water_presence_percent": district['water']
},
"farmer_advice": (
f"Your district has {district['risk_level']} disease risk. "
f"Watch for: {district['diseases_flagged']}. "
f"Current temperature is {district['temperature']}°C."
)
}

@app.post("/analyse-dropping")
async def analyse_dropping_endpoint(
file: UploadFile = File(...)
):
if not file.content_type.startswith('image/'):
raise HTTPException(
status_code=400,
detail="File must be an image"
)

image_bytes = await file.read()
result =      analyse_dropping(image_bytes)

return {
"status":         "success",
"diagnosis":      result['disease'],
"raw_class":      result['raw_class'],
"confidence":     f"{result['confidence']}%",
"risk_level":     result['risk_level'],
"is_healthy":     result['is_healthy'],
"recommendation": result['recommendation'],
"model":          "YOLOv8 PoultryGuard v1.0"
}

# ── 7. RUN ───────────────────────────────────────────────────

if __name__ == "__main__":
uvicorn.run(
"main:app",
host="0.0.0.0",
port=int(os.environ.get("PORT", 8000))
)


