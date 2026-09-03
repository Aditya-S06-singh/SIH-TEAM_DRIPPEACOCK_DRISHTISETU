# DrishtiSetu - AI & Computer Vision Architecture Guide

This document defines the complete model registry, directory structure, and edge-to-server workload split for DrishtiSetu (Smart India Hackathon / DoSJE).

---

## 1. Directory Structure for Models

Place your model artifact files (ONNX, data, or config files) into `public/models/`:

```text
drishtisetu/
└── public/
    └── models/
        ├── gate/
        │   ├── face_detector.onnx             <-- MediaPipe Face Detector ONNX
        │   ├── face_detector.onnx.data        <-- Face detector external weights / data
        │   ├── arcface_w600k.onnx             <-- InsightFace ArcFace verification model
        │   └── minifasnet_v2.onnx             <-- MiniFASNet anti-spoofing model
        │
        ├── ocr/
        │   └── ppocrv4_rec.onnx               <-- PaddleOCR PP-OCRv4 text recognition
        │
        ├── cctv/
        │   ├── yolo11n.onnx                   <-- YOLO11n person detector
        │   ├── yolo11n_ppe.onnx               <-- Custom YOLO11n PPE & uniform detector
        │   ├── yolo11n_pose.onnx              <-- YOLO11n-pose activity & fall detector
        │   └── bytetrack.json                 <-- ByteTrack tracker configuration
        │
        └── analytics/
            └── isolation_forest_model.joblib  <-- Rules Engine + Isolation Forest model
```

---

## 2. Feature & Model Allocation Matrix

| Feature | Model | Framework | Target Runtime | Input Size |
| :--- | :--- | :--- | :--- | :--- |
| **ID-card text extraction** | **PaddleOCR (PP-OCRv4)** | PaddleOCR / ONNX | Server / Cloud | 320x48 |
| **Face detection** | **MediaPipe Face Detector** | MediaPipe / ONNX | Edge / Browser / Pi | 128x128 |
| **Face verification at entry** | **ArcFace / InsightFace** | ONNX | Server / Cloud | 112x112 |
| **Photo/video spoof prevention** | **MiniFASNet Anti-Spoofing** | ONNX | Server / Cloud | 80x80 |
| **Person detection & counting** | **YOLO11n** | Ultralytics ONNX | Server / Cloud / Edge | 640x640 |
| **Anonymous movement tracking** | **ByteTrack** | Kalman Filter + IoU | Server / Cloud | 640x640 |
| **Uniform/PPE detection** | **Custom-trained YOLO11n** | Ultralytics ONNX | Server / Cloud | 640x640 |
| **Pose/activity detection** | **YOLO11n-pose / MediaPipe Pose** | ONNX | Server / Cloud | 640x640 |
| **Attendance/CCTV anomaly detection** | **Rules Engine + Isolation Forest** | Scikit-Learn / Python | Server / Cloud | 16-D vector |

---

## 3. Workload Topology Split

### A. Raspberry Pi Zero 2 W (Edge Device)
* **Hardware Specs**: Quad-Core 64-bit ARM Cortex-A53, 512MB LPDDR2 RAM.
* **Workload**:
  1. **Camera capture**: Continuous hardware video ingestion over CSI or V4L2.
  2. **Motion detection**: Fast differential background subtraction (OpenCV MOG2) to stay low-power.
  3. **Device heartbeat**: Periodic telemetry sent to Firestore (`devices/{deviceId}`).
  4. **Low-resolution snapshots**: Captures and triggers upload upon motion or threshold alert.
  5. **Optional lightweight Face Detection**: Runs local MediaPipe Face Detector (BlazeFace) for framing feedback before streaming.

### B. Backend Server / Cloud
* **Infrastructure**: FastAPI microservices + Firebase Cloud Functions + Firestore.
* **Workload**:
  1. **PaddleOCR**: Extracts institute ID number, name, and validity from card images.
  2. **Face Match (ArcFace)**: Computes 512-D cosine distance against stored biometric hashes.
  3. **Liveness Detection (MiniFASNet)**: Evaluates Fourier high-frequency spectra to prevent screen or printed photo replay attacks.
  4. **YOLO11n Person & PPE Detection**: Headcount estimation, mandatory uniform, reflective vest, and badge check.
  5. **ByteTrack**: Single-camera anonymous trajectory and dwell-time calculation.
  6. **Risk Scoring & Anomaly Detection**:
     * Cross-checks Gate Verified Attendance vs. CCTV Headcount.
     * Computes multi-factor Isolation Forest anomaly scores.
  7. **Firebase Updates**: Dispatches real-time alerts to the PMU Command Center.
