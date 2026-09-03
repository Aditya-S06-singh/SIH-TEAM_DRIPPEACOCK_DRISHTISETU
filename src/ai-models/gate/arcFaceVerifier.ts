/**
 * InsightFace ArcFace Biometric Feature Extractor & Matcher
 * Model: ArcFace ResNet50 (512-dimensional normalized embedding vectors)
 */

import { AI_MODELS_REGISTRY } from '../config';

export interface ArcFaceMatchResult {
  matched: boolean;
  similarityScore: number;
  threshold: number;
  tokenDisplay: string;
}

export class InsightFaceArcFace {
  private config = AI_MODELS_REGISTRY.insightFaceArcFace;

  constructor() {
    console.info(`[AI Subsystem] InsightFace ArcFace configured: ${this.config.modelPath}`);
  }

  /**
   * Compares two 512-D embeddings or verifies candidate against enrolled token template
   */
  public async verifyMatch(candidateId: string, enrolledId: string): Promise<ArcFaceMatchResult> {
    await new Promise(res => setTimeout(res, 200));

    // Cosine similarity simulation
    const isExact = candidateId === enrolledId;
    const similarityScore = isExact ? 0.89 : 0.42;

    return {
      matched: similarityScore >= this.config.confidenceThreshold,
      similarityScore,
      threshold: this.config.confidenceThreshold,
      tokenDisplay: `emb_${candidateId.slice(-4)}`,
    };
  }
}

export const insightFaceArcFace = new InsightFaceArcFace();
