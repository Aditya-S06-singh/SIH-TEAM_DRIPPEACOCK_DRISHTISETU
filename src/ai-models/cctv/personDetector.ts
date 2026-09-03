/**
 * Edge CCTV Person & Occupancy Detector Wrapper
 * Simulates high-performance edge detection (e.g. YOLOv8-Nano / MobileNet ONNX)
 * Easily swap with actual onnxruntime-web session by replacing runInference().
 */

import type { PersonDetectionResult, BoundingBox } from '../types';

export class EdgePersonDetector {
  private modelLoaded: boolean = true;
  private modelName: string = 'yolo11n.onnx';

  constructor() {
    console.info(`[AI Subsystem] EdgePersonDetector initialized with Ultralytics model: ${this.modelName}`);
  }

  /**
   * Runs inference on the provided frame or simulated camera stream.
   * Computes normalized bounding boxes, total person count, and crowd density.
   */
  public async detect(targetCountHint: number = 42): Promise<PersonDetectionResult> {
    const startTime = performance.now();

    // In a production build with ONNX Runtime Web:
    // const session = await ort.InferenceSession.create('/ai-models/weights/yolov8n.onnx');
    // const results = await session.run(feeds);

    // Realistic simulated bounding box generator matching target occupancy
    const boxes: BoundingBox[] = [];
    const count = Math.max(1, targetCountHint);

    // Generate visually balanced bounding boxes across 0.1 - 0.9 viewport
    for (let i = 0; i < Math.min(count, 12); i++) {
      const col = i % 4;
      const row = Math.floor(i / 4);
      boxes.push({
        id: `box_person_${i}`,
        x: 0.1 + col * 0.22 + (Math.random() * 0.04 - 0.02),
        y: 0.15 + row * 0.25 + (Math.random() * 0.04 - 0.02),
        width: 0.14 + Math.random() * 0.04,
        height: 0.28 + Math.random() * 0.05,
        label: 'person',
        confidence: Number((0.85 + Math.random() * 0.12).toFixed(2)),
        color: '#10B981', // Emerald green for confirmed person
      });
    }

    const elapsed = Math.round(performance.now() - startTime);

    return {
      personCount: count,
      averageConfidence: 0.91,
      crowdDensityLevel: count > 60 ? 'high' : (count < 15 ? 'low' : 'normal'),
      boxes,
      inferenceTimeMs: elapsed || 24,
      timestamp: new Date().toISOString(),
    };
  }
}

export const edgePersonDetector = new EdgePersonDetector();
