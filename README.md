# 🛰️ PoultriVet — Poultry Disease Early Warning System

<div align="center">

![PoultriVet Banner](docs/screenshots/banner.png)

[![API Status](https://img.shields.io/badge/API-Live-brightgreen)](https://poulivetapi.onrender.com)
[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://python.org)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Made in Uganda](https://img.shields.io/badge/Made%20in-Uganda%20🇺🇬-red)](https://github.com/Iyundhu)

**An integrated satellite imagery and deep learning system for proactive 
poultry disease risk prediction serving 4.2 million smallholder farmers across Uganda.**

[🌐 Live API](https://poulivetapi.onrender.com) · 
[📖 API Docs](https://poulivetapi.onrender.com/docs) · 
[📊 Risk Summary](https://poulivetapi.onrender.com/summary)

</div>

---

## 🌍 The Problem

Uganda's 4.2 million smallholder poultry farmers lose over **UGX 350 billion annually** 
to preventable disease outbreaks. 73% of poultry mortality occurs with **zero prior warning**, 
and 61% of farmers are more than 20km from the nearest veterinary officer.

## 💡 The Solution

PoultriVet combines two powerful technologies into one system:

| Component | Technology | What It Does |
|-----------|-----------|--------------|
| 🛰️ Satellite Risk Mapping | Sentinel-2, MODIS, GEE | Weekly environmental risk scores for 164 Uganda districts |
| 🔬 Disease Detection | YOLOv8 Deep Learning | AI diagnosis from poultry dropping photos |
| 📡 Backend API | FastAPI + Render | Permanent REST API serving all data |
| 📱 Mobile App | Flutter + Dart | Android app for farmers |

---

## 🏗️ System Architecture
Sentinel-2 (ESA) ──┐

MODIS (NASA)    ──┤──► Google Earth Engine ──► Risk Scoring ──► FastAPI ──► Flutter App

JRC Water Data  ──┘                                              YOLOv8 ──►

---

## 🚀 Live API

Base URL: `https://poulivetapi.onrender.com`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API status and endpoint directory |
| `/summary` | GET | National risk summary — 164 districts |
| `/risk-map` | GET | Full district-level satellite risk data |
| `/district/{name}` | GET | Single district risk lookup |
| `/analyse-dropping` | POST | YOLOv8 disease detection from image |

**Quick test — open in your browser:**
https://poulivetapi.onrender.com/summary

---

## 🛰️ Satellite Pipeline

Environmental indicators extracted weekly for all 164 Uganda districts:

- **NDVI** — Vegetation density (Sentinel-2 B8/B4) → Newcastle Disease risk
- **NDMI** — Moisture index (Sentinel-2 B8A/B11) → Coccidiosis risk  
- **LST** — Land surface temperature (MODIS MOD11A1) → Immune stress
- **Water** — Water body presence (JRC Global Surface Water) → Fowl Typhoid risk

**Risk Distribution (Feb 2025):**
- 🔴 HIGH Risk: 74 districts (45%)
- 🟡 MEDIUM Risk: 83 districts (51%)
- 🟢 LOW Risk: 7 districts (4%)

---

## 🔬 Disease Detection Model

YOLOv8-based classification model detecting 4 categories:

| Class | Disease | Risk Level |
|-------|---------|-----------|
| COCCI | Coccidiosis | HIGH |
| NCD | Newcastle Disease | HIGH |
| SALMONELLA | Salmonella | HIGH |
| SEHAT | Healthy | LOW |

---

## 📱 Flutter App Screens

| Screen | Description | Data Source |
|--------|-------------|-------------|
| Home | Health overview + scan button | Local |
| Statistics | 3 live charts from satellite data | `/summary` |
| Maps | District risk lookup | `/district/{name}` |
| Alerts | Disease warning cards | `/summary` |
| Scan | YOLOv8 dropping analysis | `/analyse-dropping` |

---

## ⚙️ Tech Stack
Backend:    Python 3.11 · FastAPI · Uvicorn · PyTorch 2.11 · Ultralytics YOLOv8
Satellite:  Google Earth Engine · Sentinel-2 · MODIS · JRC Surface Water
Mobile:     Flutter · Dart · fl_chart · http
Deployment: Render.com · GitHub

---

## 🗂️ Repository Structure

PoultriVet/

│

├── 📁 satellite/                  ← Your GEE satellite pipeline

│   ├── satellite_pipeline.ipynb   ← Your full Colab notebook

│   ├── risk_scoring.py            ← Risk scoring function

│   └── uganda_risk_data.json      ← Pre-computed risk data


│

├── 📁 api/                        ← Your FastAPI backend

│   ├── main.py                    ← FastAPI app

│   ├── requirements.txt           ← Dependencies

│   ├── runtime.txt                ← Python version

│   └── .python-version            ← Python version file

│

├── 📁 flutter/                    ← Flutter screens you built

│   ├── lib/

│   │   ├── api_service.dart

│   │   ├── statistics_screen.dart

│   │   ├── maps_screen.dart

│   │   ├── alerts_screen.dart

│   │   └── main.dart


│   └── pubspec.yaml

│

├── 📁 model/                      ← YOLOv8 model info

│   └── MODEL.md                   ← Model description and metrics

│
├── 📁 docs/                       ← Documentation and screenshots

│   ├── screenshots/               ← App screenshots

│   ├── architecture.png           ← System architecture diagram

│   └── questionnaire.pdf          ← Farmer questionnaire

|
├── 📁 poulipal/                   ←Chatbot logic

│   ├── lib/services/

│   ├── PouliService.dart


│
├── 📁 research/                   ← Research documents

│   └── project_report.pdf         ← Your project report

│
├── README.md                      ← Main readme (we write this next)


├── .gitignore                     ← Auto generated


└── LICENSE                        ← MIT license

---

## 🚦 Getting Started

### Run the API Locally

```bash
cd api
pip install -r requirements.txt
uvicorn main:app --reload
```

### Run the Satellite Pipeline

Open `satellite/satellite_pipeline.ipynb` in Google Colab and run all cells.
Requires a Google Earth Engine account.

---

## 📊 Impact

- **164** Uganda districts monitored weekly
- **4** poultry diseases detected by AI
- **4.2M** smallholder farmers served
- **UGX 350B** annual losses targeted
- **< 5s** average disease diagnosis time

---

## 👥 Team

Built at Makerere University, Uganda · 2026

_Iyundhu Kennedy Kisame_ - **Geosptial Systems Lead**

_Mukisa Rachel Jovia_ - **Systems architect**

_Nsubuga Jeremiah_ - **Research and Innovation Lead**

_Yiga Marvin Isaac_ - **Machine Learning Lead**

---
  Demo video available at :  https://youtu.be/rpjzk3fj5Qw?si=JZp0in2gpMkZnteC

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">
<i>Watching Uganda's farms from the sky 🛰️🐔</i>
</div>
