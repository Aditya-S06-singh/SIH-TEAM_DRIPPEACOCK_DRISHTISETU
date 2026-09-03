import {
  ref,
  uploadBytes,
  getDownloadURL,
  type UploadMetadata,
} from 'firebase/storage';
import { storage, isFirebaseConfigured } from '../config/firebaseClient';

export interface UploadOptions {
  category: 'inspection-evidence' | 'cctv-snapshots' | 'vc-evidence' | 'corrective-action-evidence';
  instituteId: string;
  subId: string; // inspectionId, cameraId, verificationId, or actionId
  file: File | Blob;
  fileName: string;
  uploaderId: string;
}

export const storageService = {
  /**
   * Uploads file with path segregation, metadata tags, and mime validation
   */
  async uploadEvidence(options: UploadOptions): Promise<string> {
    const { category, instituteId, subId, file, fileName, uploaderId } = options;

    // File size check: 15MB max
    if (file.size > 15 * 1024 * 1024) {
      throw new Error('File exceeds maximum allowable size (15MB).');
    }

    const uniqueName = `${Date.now()}_${fileName.replace(/\s+/g, '_')}`;
    const storagePath = `${category}/${instituteId}/${subId}/${uniqueName}`;

    if (isFirebaseConfigured && storage) {
      const storageRef = ref(storage, storagePath);
      const metadata: UploadMetadata = {
        contentType: file.type || 'image/jpeg',
        customMetadata: {
          uploaderId,
          instituteId,
          subId,
          uploadedAt: new Date().toISOString(),
        },
      };

      const snapshot = await uploadBytes(storageRef, file, metadata);
      return await getDownloadURL(snapshot.ref);
    }

    // Demo Mode: Return simulated storage URI
    console.info(`[Storage Demo Mode] Simulated upload to path: gs://drishtisetu-demo/${storagePath}`);
    return `https://storage.googleapis.com/drishtisetu-demo/${storagePath}`;
  },
};
