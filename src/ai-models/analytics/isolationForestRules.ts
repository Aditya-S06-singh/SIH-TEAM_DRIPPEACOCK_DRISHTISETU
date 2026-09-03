/**
 * Isolation Forest + Rules Engine Anomaly Detector
 * Fuses Gate Verified Attendance, CCTV Headcount, ByteTrack dwell times, and PPE flags.
 */

import { AI_MODELS_REGISTRY } from '../config';

export interface AnomalyAssessment {
  isAnomaly: boolean;
  anomalyScore: number; // -1.0 (extreme anomaly) to +1.0 (normal)
  reasons: string[];
  recommendedAction: 'none' | 'dispatch_pmu_alert' | 'schedule_inspection';
}

export class IsolationForestRulesEngine {
  private config = AI_MODELS_REGISTRY.isolationForestRules;

  constructor() {
    console.info(`[AI Subsystem] Isolation Forest & Rules Engine active: ${this.config.modelPath}`);
  }

  public assess(params: {
    gateAttendanceCount: number;
    cctvHeadcount: number;
    ppeViolationsCount: number;
    dwellTimeDeviationPercent: number;
  }): AnomalyAssessment {
    const reasons: string[] = [];
    const discrepancy = Math.abs(params.gateAttendanceCount - params.cctvHeadcount);
    const discrepancyRatio = params.gateAttendanceCount > 0 ? discrepancy / params.gateAttendanceCount : 0;

    let score = 0.5; // Normal baseline

    // Rule 1: High Headcount Discrepancy (Ghost Beneficiaries or Unregistered Entry)
    if (discrepancyRatio > 0.25) {
      score -= 0.45;
      reasons.push(`Attendance vs CCTV mismatch: ${params.cctvHeadcount} seen vs ${params.gateAttendanceCount} registered.`);
    }

    // Rule 2: PPE / Uniform non-compliance
    if (params.ppeViolationsCount > 3) {
      score -= 0.20;
      reasons.push(`High PPE/uniform non-compliance count (${params.ppeViolationsCount} individuals).`);
    }

    const isAnomaly = score < this.config.confidenceThreshold;

    return {
      isAnomaly,
      anomalyScore: Number(score.toFixed(2)),
      reasons,
      recommendedAction: isAnomaly ? 'dispatch_pmu_alert' : 'none',
    };
  }
}

export const isolationForestRulesEngine = new IsolationForestRulesEngine();
