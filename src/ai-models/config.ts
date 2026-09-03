/**
 * Central AI Model & Edge-Server Pipeline Architecture Configuration
 * Configured according to the DrishtiSetu MVP Computer Vision & ML Specifications.
 *
 * Distribution Architecture:
 * - Edge (Raspberry Pi Zero 2 W):
 *     Camera capture, motion detection, device heartbeat, low-res snapshots, optional MediaPipe face detection.
 * - Server / Cloud Backend:
 *     PaddleOCR, InsightFace ArcFace, MiniFASNet anti-spoofing, YOLO11n person counting,
 *     ByteTrack trajectory tracking, Custom YOLO11n PPE/Uniform, YOLO11n-pose / MediaPipe Pose,
 *     Isolation Forest + Rules engine anomaly scoring, and Firebase real-time synchronization.
 */

export interface ModelMetadata {
  id: string;
  name: string;
  framework: 'ONNX' | 'TFLite' | 'MediaPipe' | 'PaddleOCR' | 'PyTorch' | 'Scikit-Learn';
  targetRuntime: 'edge_rpi_zero_2w' | 'server_cloud' | 'browser_wasm';
  modelPath: string;
  externalWeightsPath?: string;
  task:
    | 'ocr_id_extraction'
    | 'face_detection'
    | 'face_verification'
    | 'anti_spoofing'
    | 'person_counting'
    | 'anonymous_tracking'
    | 'ppe_uniform_detection'
    | 'pose_activity_detection'
    | 'anomaly_detection';
  inputResolution: [number, number]; // [width, height]
  confidenceThreshold: number;
  nmsIouThreshold?: number;
}

export const AI_MODELS_REGISTRY: Record<string, ModelMetadata> = {
  // 1. ID-Card Text Extraction
  paddleOcr: {
    id: 'paddleocr-ch-en-v4',
    name: 'PaddleOCR v4 (Mobile / PP-OCRv4)',
    framework: 'PaddleOCR',
    targetRuntime: 'server_cloud',
    modelPath: '/models/ocr/ppocrv4_rec.onnx',
    task: 'ocr_id_extraction',
    inputResolution: [320, 48],
    confidenceThreshold: 0.85,
  },

  // 2. Face Detection
  mediaPipeFace: {
    id: 'mediapipe-face-detector-short-range',
    name: 'MediaPipe Face Detector (BlazeFace Short Range)',
    framework: 'MediaPipe',
    targetRuntime: 'edge_rpi_zero_2w',
    modelPath: '/models/gate/face_detector.onnx',
    externalWeightsPath: '/models/gate/face_detector.onnx.data',
    task: 'face_detection',
    inputResolution: [128, 128],
    confidenceThreshold: 0.70,
    nmsIouThreshold: 0.3,
  },

  // 3. Face Verification at Entry
  insightFaceArcFace: {
    id: 'arcface-w600k-r50',
    name: 'InsightFace ArcFace (ResNet50-Edge)',
    framework: 'ONNX',
    targetRuntime: 'server_cloud',
    modelPath: '/models/gate/arcface_w600k.onnx',
    task: 'face_verification',
    inputResolution: [112, 112],
    confidenceThreshold: 0.68, // Cosine similarity threshold >= 0.68
  },

  // 4. Photo / Video Spoof Prevention
  miniFASNetAntiSpoof: {
    id: 'minifasnet-v2-se',
    name: 'MiniFASNetV2 Anti-Spoofing (Fourier Spectrum)',
    framework: 'ONNX',
    targetRuntime: 'server_cloud',
    modelPath: '/models/gate/minifasnet_v2.onnx',
    task: 'anti_spoofing',
    inputResolution: [80, 80],
    confidenceThreshold: 0.88,
  },

  // 5. Person Detection & Headcount
  yolo11nPerson: {
    id: 'yolo11n-person-fp16',
    name: 'Ultralytics YOLO11n (Person Headcount)',
    framework: 'ONNX',
    targetRuntime: 'server_cloud',
    modelPath: '/models/cctv/yolo11n.onnx',
    task: 'person_counting',
    inputResolution: [640, 640],
    confidenceThreshold: 0.55,
    nmsIouThreshold: 0.45,
  },

  // 6. Anonymous Movement Tracking in One Camera
  byteTrack: {
    id: 'bytetrack-kalman-iou',
    name: 'ByteTrack Multi-Object Tracker',
    framework: 'ONNX',
    targetRuntime: 'server_cloud',
    modelPath: '/models/cctv/bytetrack.json',
    task: 'anonymous_tracking',
    inputResolution: [640, 640],
    confidenceThreshold: 0.60,
  },

  // 7. Uniform & PPE Detection
  customYolo11nPPE: {
    id: 'custom-yolo11n-ppe-uniform',
    name: 'Custom YOLO11n (Helmet, Vest, ID Badge, Uniform)',
    framework: 'ONNX',
    targetRuntime: 'server_cloud',
    modelPath: '/models/cctv/yolo11n_ppe.onnx',
    task: 'ppe_uniform_detection',
    inputResolution: [640, 640],
    confidenceThreshold: 0.60,
    nmsIouThreshold: 0.45,
  },

  // 8. Pose & Activity Detection
  yolo11nPose: {
    id: 'yolo11n-pose-17kpts',
    name: 'YOLO11n-Pose / MediaPipe Pose (Fall & Inactivity)',
    framework: 'ONNX',
    targetRuntime: 'server_cloud',
    modelPath: '/models/cctv/yolo11n_pose.onnx',
    task: 'pose_activity_detection',
    inputResolution: [640, 640],
    confidenceThreshold: 0.50,
  },

  // 9. Attendance & CCTV Anomaly Detection
  isolationForestRules: {
    id: 'rules-isolation-forest-ensemble',
    name: 'Rules Engine + Scikit-Learn Isolation Forest',
    framework: 'Scikit-Learn',
    targetRuntime: 'server_cloud',
    modelPath: '/models/analytics/isolation_forest_model.joblib',
    task: 'anomaly_detection',
    inputResolution: [16, 1], // Vector feature dimension
    confidenceThreshold: -0.15, // Outlier score cutoff
  },
};

/**
 * Edge vs. Cloud Server Deployment Matrix
 */
export const DEPLOYMENT_TOPOLOGY = {
  edgeRpiZero2W: {
    deviceHardware: 'Raspberry Pi Zero 2 W (Quad-Core 64-bit ARM Cortex-A53, 512MB LPDDR2)',
    responsibilities: [
      'Camera hardware capture (V4L2 / CSI camera interface)',
      'Differential motion detection (OpenCV BackgroundSubtractorMOG2)',
      'Device heartbeat & telemetry beacon to Firestore every 30s',
      'Low-resolution event snapshots on trigger',
      'Local MediaPipe Face Detection for immediate capture alignment',
    ],
  },
  backendServerCloud: {
    infrastructure: 'FastAPI / Python Microservice + Firebase Cloud Functions & Firestore',
    responsibilities: [
      'PaddleOCR: ID-Card text extraction & field parsing',
      'InsightFace ArcFace: 512-D Biometric embedding & cosine similarity match',
      'MiniFASNet: Photo/video screen replay & 3D liveness evaluation',
      'YOLO11n: Real-time CCTV headcount extraction',
      'ByteTrack: Single-camera spatio-temporal trajectory & dwell-time tracking',
      'Custom YOLO11n PPE: Mandatory uniform, vest, and ID badge enforcement',
      'YOLO11n-pose / MediaPipe Pose: Beneficiary welfare, fall detection, and distress alert',
      'Rules Engine + Isolation Forest: Multimodal anomaly score computation',
      'Live Cloud Firestore updates & PMU / State Alert dispatching',
    ],
  },
};
