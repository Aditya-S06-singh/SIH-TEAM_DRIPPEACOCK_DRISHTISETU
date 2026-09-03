/**
 * Standardized AI Model Inference Types
 * Used across CCTV Edge devices and Gate Entry verification tablets.
 */

export interface BoundingBox {
  id: string;
  x: number; // Normalized 0.0 to 1.0
  y: number; // Normalized 0.0 to 1.0
  width: number; // Normalized 0.0 to 1.0
  height: number; // Normalized 0.0 to 1.0
  label: 'person' | 'helmet' | 'vest' | 'mask' | 'id_card';
  confidence: number; // 0.0 to 1.0
  color: string;
}

export interface PersonDetectionResult {
  personCount: number;
  averageConfidence: number;
  crowdDensityLevel: 'low' | 'normal' | 'high' | 'overcrowded';
  boxes: BoundingBox[];
  inferenceTimeMs: number;
  timestamp: string;
}

export interface SafetyComplianceResult {
  overallCompliance: 'compliant' | 'warning' | 'violation';
  helmetCount: number;
  vestCount: number;
  maskCount: number;
  idCardCount: number;
  missingSafetyGearCount: number;
  detectedViolations: string[];
}

export interface LivenessVerificationResult {
  passed: boolean;
  confidence: number;
  blinkDetected: boolean;
  microMotionDetected: boolean;
  antiSpoofScore: number; // Higher is more authentic
  reason?: string;
}

export interface BiometricHashVerificationResult {
  matched: boolean;
  opaquePersonToken: string;
  maskedIdDisplay: string;
  consentRecorded: boolean;
  timestamp: string;
}
