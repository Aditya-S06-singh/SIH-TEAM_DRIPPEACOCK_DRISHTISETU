/**
 * DrishtiSetu - Core Domain Types
 * Matches production Cloud Firestore schema specifications exactly.
 */

export type UserRole =
  | 'dosje_official'
  | 'pmu_supervisor'
  | 'inspector'
  | 'institute_admin'
  | 'entry_operator';

export interface UserProfile {
  uid: string;
  name: string;
  email: string;
  role: UserRole;
  state?: string;
  district?: string;
  assignedInstituteIds?: string[];
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export type RiskLevel = 'green' | 'amber' | 'red';

export interface Institute {
  instituteId: string;
  name: string;
  scheme: string; // e.g., 'PM-DAKSH', 'SMILE', 'Senior Citizen Homes', 'Residential Special School'
  ngoName: string;
  registrationId: string;
  state: string;
  district: string;
  address: string;
  latitude: number;
  longitude: number;
  projectInchargeId: string;
  projectInchargeName?: string;
  contactNumber?: string;
  expectedAttendance: number;
  verifiedAttendance?: number;
  cctvOccupancy?: number;
  riskScore: number; // 0 - 100
  riskLevel: RiskLevel;
  riskExplanation?: string;
  complianceScore: number; // percentage e.g. 88
  cameraStatus: 'online' | 'degraded' | 'offline';
  lastInspectionAt?: string;
  lastInspectionScore?: number;
  lastVcVerificationAt?: string;
  lastVcStatus?: string;
  createdAt: string;
  updatedAt: string;
}

export interface EdgeDevice {
  deviceId: string;
  instituteId: string;
  instituteName?: string;
  deviceName: string;
  deviceType: 'camera' | 'biometric_scanner' | 'gate_tablet';
  hardwareLabel: string; // 'Raspberry Pi Zero 2 W'
  status: 'online' | 'offline' | 'degraded';
  lastHeartbeatAt: string;
  streamUrlReference: string;
  cameraStatus: 'active' | 'obstructed' | 'offline';
  currentPersonCount: number;
  currentSafetyCompliance: 'compliant' | 'warning' | 'violation';
  firmwareVersion: string;
  locationLabel: string;
  bitrateKbps: number;
  fps: number;
  updatedAt: string;
}

export interface AttendanceEvent {
  eventId: string;
  instituteId: string;
  instituteName?: string;
  personToken: string; // Secure opaque hash, e.g. 'usr_tok_84f91e'
  role: 'beneficiary' | 'student' | 'resident' | 'staff' | 'instructor';
  entryMethod: 'qr_assisted' | 'rfid' | 'manual_fallback';
  verificationStatus: 'verified' | 'failed' | 'manual_override';
  faceMatchStatus: 'matched' | 'uncertain' | 'failed' | 'bypassed';
  livenessStatus: 'passed' | 'failed' | 'bypassed';
  fingerprintMatchStatus: 'matched' | 'failed' | 'bypassed';
  governmentIdReferenceMasked: string; // e.g. 'XXXX-XXXX-4821'
  consentStatus: boolean;
  cameraEntryConfirmed: boolean;
  occurredAt: string;
  createdAt: string;
}

export type AlertSeverity = 'low' | 'medium' | 'high' | 'critical';
export type AlertStatus = 'open' | 'acknowledged' | 'in_review' | 'resolved' | 'escalated';

export interface AlertItem {
  alertId: string;
  instituteId: string;
  instituteName: string;
  severity: AlertSeverity;
  category: 'cctv_offline' | 'attendance_mismatch' | 'liveness_failure' | 'vc_no_response' | 'ppe_violation' | 'overdue_inspection' | 'gps_mismatch';
  title: string;
  explanation: string;
  riskImpact: number; // point change added to risk score
  status: AlertStatus;
  evidenceReference?: string;
  createdAt: string;
  acknowledgedBy?: string;
  resolvedAt?: string;
  recommendedActions: string[];
}

export type VcStatus = 'requested' | 'accepted' | 'in_progress' | 'no_response' | 'completed';
export type VcResult = 'verified' | 'partially_verified' | 'no_response' | 'suspicious_escalated';

export interface VideoVerification {
  verificationId: string;
  instituteId: string;
  instituteName: string;
  initiatedBy: string;
  selectedReason: 'routine_sample' | 'elevated_risk' | 'overdue_audit' | 'attendance_mismatch';
  status: VcStatus;
  requestedAt: string;
  startedAt?: string;
  completedAt?: string;
  result?: VcResult;
  checklist: {
    activityAreaVerified: boolean;
    staffPresenceConfirmed: boolean;
    beneficiariesPresentConfirmed: boolean;
    amenitiesAndFoodChecked: boolean;
  };
  evidenceReferences: string[];
  notes?: string;
}

export interface InspectionAssignment {
  assignmentId: string;
  instituteId: string;
  instituteName: string;
  inspectorId: string;
  inspectorName: string;
  assignedBy: string;
  priority: 'routine' | 'urgent' | 'surprise_high_risk';
  assignmentReason: string;
  status: 'assigned' | 'accepted' | 'in_field' | 'completed' | 'cancelled';
  dueAt: string;
  assignedAt: string;
  acceptedAt?: string;
  createdAt: string;
}

export interface FindingItem {
  findingId: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  category: string;
  description: string;
  evidenceUrl?: string;
  correctiveActionRequired: string;
}

export interface InspectionReport {
  reportId: string;
  assignmentId: string;
  instituteId: string;
  instituteName: string;
  inspectorId: string;
  inspectorName: string;
  gpsLatitude: number;
  gpsLongitude: number;
  gpsValidationStatus: 'validated_within_geofence' | 'warning_distance_mismatch' | 'manual_override';
  checklistScore: number; // 0 - 100
  findings: FindingItem[];
  evidenceReferences: string[];
  digitalSignatureHash: string;
  submittedAt: string;
  reviewStatus: 'pending' | 'accepted' | 'evidence_requested' | 'reinspection_ordered' | 'escalated';
  reviewedBy?: string;
  reviewNotes?: string;
}

export interface CorrectiveAction {
  actionId: string;
  instituteId: string;
  instituteName: string;
  reportId: string;
  findingId: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  requiredAction: string;
  dueAt: string;
  status: 'pending_ngo_response' | 'response_submitted' | 'accepted' | 'reinspection_ordered' | 'escalated';
  instituteResponse?: string;
  evidenceReferences: string[];
  reviewedBy?: string;
  closedAt?: string;
}

export interface AuditLog {
  logId: string;
  actorId: string;
  actorName: string;
  actorRole: UserRole | 'cloud_function';
  action: string;
  entityType: string;
  entityId: string;
  metadata?: Record<string, any>;
  occurredAt: string;
}
