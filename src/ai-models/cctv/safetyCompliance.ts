/**
 * Safety & PPE Uniform Compliance Classifier
 * Detects Helmets, Reflective Vests, Face Masks, and Institute ID Badges.
 */

import type { SafetyComplianceResult, BoundingBox } from '../types';

export class SafetyComplianceClassifier {
  public evaluate(boxes: BoundingBox[]): SafetyComplianceResult {
    let helmetCount = 0;
    let vestCount = 0;
    let maskCount = 0;
    let idCardCount = 0;

    boxes.forEach(box => {
      if (box.label === 'helmet') helmetCount++;
      if (box.label === 'vest') vestCount++;
      if (box.label === 'mask') maskCount++;
      if (box.label === 'id_card') idCardCount++;
    });

    const personCount = boxes.filter(b => b.label === 'person').length || 1;
    const missingRatio = Math.max(0, personCount - Math.max(helmetCount, idCardCount));

    const overall: 'compliant' | 'warning' | 'violation' =
      missingRatio === 0 ? 'compliant' : (missingRatio < 3 ? 'warning' : 'violation');

    const detectedViolations: string[] = [];
    if (overall === 'violation') {
      detectedViolations.push(`${missingRatio} individuals detected without mandatory Institute ID badge.`);
    }

    return {
      overallCompliance: overall,
      helmetCount,
      vestCount,
      maskCount,
      idCardCount,
      missingSafetyGearCount: missingRatio,
      detectedViolations,
    };
  }
}

export const safetyComplianceClassifier = new SafetyComplianceClassifier();
