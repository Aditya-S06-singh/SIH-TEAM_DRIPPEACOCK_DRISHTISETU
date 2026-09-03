# DrishtiSetu - AI Recognition & Computer Vision Hub (`/src/ai-models`)

This directory is the dedicated, standardized plug-and-play architecture for integrating custom Machine Learning and Computer Vision models into the DrishtiSetu operational platform.

---

## 1. Where to Place Your Custom Models

Place your model artifact files (ONNX, TFLite, MediaPipe models, or weights) into the corresponding subdirectories:

```
src/ai-models/
├── weights/                       <-- DROP YOUR .onnx, .tflite, or .bin MODEL FILES HERE
│   ├── yolov8n-seg.onnx           (CCTV Edge person & safety gear detector)
│   ├── face_liveness_depth.tflite (Gate optical liveness validator)
│   └── ppe_compliance.onnx        (Helmet / Vest / ID card classifier)
│
├── types.ts                       <-- Standardized TypeScript input/output inference interfaces
│
├── cctv/                          <-- Edge CCTV Inference Wrappers
│   ├── personDetector.ts          (Counts persons, estimates spatial crowd density)
│   └── safetyCompliance.ts        (Detects Helmets, Vests, Masks, ID Badges)
│
└── gate/                          <-- Gate Tablet / Mobile Verification Wrappers
    ├── faceLiveness.ts            (Optical anti-spoofing & eye-blink detection)
    └── biometricHashVerifier.ts   (HMAC-SHA256 privacy token verification)
```

---

## 2. Model Integration Guide & Best Practices

### A. CCTV Edge Person & Density Detection (`cctv/personDetector.ts`)
- **Recommended Models**: YOLOv8-Nano (`yolov8n.onnx`), MobileNet SSD v3, or MediaPipe Object Detector.
- **Role**: Feeds real-time person count to the Edge Gateway running on Raspberry Pi Zero 2 W or browser canvas simulation.
- **Cross-Check Rule**: Reconciles the detected headcount against the gate's `verifiedAttendance`. If `|gateCount - cctvCount| / gateCount > 0.25`, a high-risk anomaly is flagged.

### B. Safety & Uniform Compliance (`cctv/safetyCompliance.ts`)
- **Target Classes**:
  - `person` (0)
  - `safety_helmet` (1)
  - `reflective_vest` (2)
  - `face_mask` (3)
  - `id_card_badge` (4)
- **Bounding Boxes**: Provides normalized `[xMin, yMin, width, height, confidence, label]` bounding boxes rendered live onto the video canvas.

### C. Gate Optical Liveness (`gate/faceLiveness.ts`)
- **Strict Privacy Compliance (DPDP Act)**:
  - Runs 100% locally on the device (WebAssembly / GPU accelerated).
  - **No raw facial images or biometric embeddings are stored or transmitted.**
  - Tests for blink rate, micro-motion, and texture reflection to prevent photograph or screen replay attacks.
  - Emits boolean `passed | failed` with confidence score.

### D. Cryptographic Token Matching (`gate/biometricHashVerifier.ts`)
- Implements one-way salted HMAC hashing:
  - Input: Scanned QR credential + salt
  - Output: Masked reference `XXXX-XXXX-4821` and opaque person token `tok_sha256_...`
  - Zero Aadhaar or biometric data is ever stored in plaintext.

---

## 3. How to Execute Inferences with Your Models
```typescript
import { personDetector } from '@/ai-models/cctv/personDetector';

// Run inference on a video frame or HTMLCanvasElement
const result = await personDetector.detect(videoElement);
console.log(`Detected ${result.personCount} individuals with confidence ${result.averageConfidence}`);
```
