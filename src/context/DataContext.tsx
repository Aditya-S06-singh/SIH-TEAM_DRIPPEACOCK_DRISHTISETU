import React, { createContext, useContext, useState, useEffect } from 'react';
import { collection, onSnapshot, query, orderBy, limit } from 'firebase/firestore';
import { db, isFirebaseConfigured } from '../config/firebaseClient';
import type {
  Institute,
  EdgeDevice,
  AttendanceEvent,
  AlertItem,
  InspectionReport,
  VideoVerification,
  InspectionAssignment,
} from '../types';
import {
  DEMO_INSTITUTES,
  DEMO_EDGE_DEVICES,
  DEMO_ALERTS,
  generateDemoAttendanceEvents,
  DEMO_INSPECTIONS,
} from '../data/mockData';

interface DataContextType {
  institutes: Institute[];
  edgeDevices: EdgeDevice[];
  alerts: AlertItem[];
  attendanceEvents: AttendanceEvent[];
  inspections: InspectionReport[];
  selectedInstitute: Institute | null;
  setSelectedInstitute: (inst: Institute | null) => void;
  isLiveFirebase: boolean;
  addAttendanceEvent: (event: Partial<AttendanceEvent>) => Promise<void>;
  updateAlertStatus: (alertId: string, status: AlertItem['status']) => void;
  updateDeviceHeartbeat: (deviceId: string, status: EdgeDevice['status']) => void;
  triggerRandomVc: (instituteId: string) => Promise<VideoVerification>;
  assignSurpriseInspection: (assignment: Partial<InspectionAssignment>) => Promise<void>;
  activeVc: VideoVerification | null;
  setActiveVc: (vc: VideoVerification | null) => void;
}

const DataContext = createContext<DataContextType | undefined>(undefined);

export const DataProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [institutes, setInstitutes] = useState<Institute[]>(DEMO_INSTITUTES);
  const [edgeDevices, setEdgeDevices] = useState<EdgeDevice[]>(DEMO_EDGE_DEVICES);
  const [alerts, setAlerts] = useState<AlertItem[]>(DEMO_ALERTS);
  const [attendanceEvents, setAttendanceEvents] = useState<AttendanceEvent[]>(() => generateDemoAttendanceEvents());
  const [inspections, setInspections] = useState<InspectionReport[]>(DEMO_INSPECTIONS);
  const [selectedInstitute, setSelectedInstitute] = useState<Institute | null>(DEMO_INSTITUTES[0]);
  const [activeVc, setActiveVc] = useState<VideoVerification | null>(null);

  // Bind live Firestore listeners when Firebase is configured
  useEffect(() => {
    if (!isFirebaseConfigured || !db) return;

    console.info('[DrishtiSetu Live] Subscribing to Cloud Firestore collections...');

    const unsubInstitutes = onSnapshot(collection(db, 'institutes'), snapshot => {
      if (!snapshot.empty) {
        const live = snapshot.docs.map(doc => ({ instituteId: doc.id, ...doc.data() } as Institute));
        setInstitutes(live);
      }
    });

    const unsubDevices = onSnapshot(collection(db, 'edgeDevices'), snapshot => {
      if (!snapshot.empty) {
        const live = snapshot.docs.map(doc => ({ deviceId: doc.id, ...doc.data() } as EdgeDevice));
        setEdgeDevices(live);
      }
    });

    const unsubAlerts = onSnapshot(collection(db, 'alerts'), snapshot => {
      if (!snapshot.empty) {
        const live = snapshot.docs.map(doc => ({ alertId: doc.id, ...doc.data() } as AlertItem));
        setAlerts(live);
      }
    });

    const qAttendance = query(collection(db, 'attendanceEvents'), orderBy('occurredAt', 'desc'), limit(50));
    const unsubAttendance = onSnapshot(qAttendance, snapshot => {
      if (!snapshot.empty) {
        const live = snapshot.docs.map(doc => ({ eventId: doc.id, ...doc.data() } as AttendanceEvent));
        setAttendanceEvents(live);
      }
    });

    return () => {
      unsubInstitutes();
      unsubDevices();
      unsubAlerts();
      unsubAttendance();
    };
  }, []);

  // Real-time simulated telemetry ticks (heartbeat, CCTV counts)
  useEffect(() => {
    const interval = setInterval(() => {
      setEdgeDevices(prev =>
        prev.map(dev => {
          if (dev.status === 'online') {
            // Slight natural occupancy variance
            const variance = Math.floor(Math.random() * 3) - 1;
            return {
              ...dev,
              currentPersonCount: Math.max(0, dev.currentPersonCount + variance),
              lastHeartbeatAt: new Date().toISOString(),
              fps: 24 + Math.floor(Math.random() * 3),
            };
          }
          return dev;
        })
      );
    }, 8000);

    return () => clearInterval(interval);
  }, []);

  const addAttendanceEvent = async (eventData: Partial<AttendanceEvent>) => {
    const newEvent: AttendanceEvent = {
      eventId: `att_ev_${Date.now()}`,
      instituteId: eventData.instituteId || 'inst_del_01',
      instituteName: eventData.instituteName || 'Samarpan Senior Citizens Integrated Home',
      personToken: eventData.personToken || `tok_sha256_${Math.random().toString(36).substring(2, 8)}`,
      role: eventData.role || 'beneficiary',
      entryMethod: eventData.entryMethod || 'qr_assisted',
      verificationStatus: eventData.verificationStatus || 'verified',
      faceMatchStatus: eventData.faceMatchStatus || 'matched',
      livenessStatus: eventData.livenessStatus || 'passed',
      fingerprintMatchStatus: eventData.fingerprintMatchStatus || 'matched',
      governmentIdReferenceMasked: eventData.governmentIdReferenceMasked || 'XXXX-XXXX-4821',
      consentStatus: eventData.consentStatus ?? true,
      cameraEntryConfirmed: eventData.cameraEntryConfirmed ?? true,
      occurredAt: new Date().toISOString(),
      createdAt: new Date().toISOString(),
    };

    setAttendanceEvents(prev => [newEvent, ...prev]);

    // Live update of institute attendance counter
    setInstitutes(prev =>
      prev.map(inst => {
        if (inst.instituteId === newEvent.instituteId) {
          const updatedCount = (inst.verifiedAttendance || 0) + 1;
          return {
            ...inst,
            verifiedAttendance: updatedCount,
          };
        }
        return inst;
      })
    );

    // Persist to Cloud Firestore when live
    if (isFirebaseConfigured && db) {
      try {
        const { doc, setDoc } = await import('firebase/firestore');
        await setDoc(doc(db, 'attendanceEvents', newEvent.eventId), newEvent);
      } catch (err) {
        console.error('[Firestore Error] Failed to write attendance event to database:', err);
      }
    }
  };

  const updateAlertStatus = async (alertId: string, status: AlertItem['status']) => {
    const resolvedAt = status === 'resolved' ? new Date().toISOString() : undefined;
    setAlerts(prev =>
      prev.map(a => (a.alertId === alertId ? { ...a, status, resolvedAt } : a))
    );

    if (isFirebaseConfigured && db) {
      try {
        const { doc, updateDoc } = await import('firebase/firestore');
        await updateDoc(doc(db, 'alerts', alertId), {
          status,
          ...(resolvedAt ? { resolvedAt } : {}),
        });
      } catch (err) {
        console.error('[Firestore Error] Failed to update alert in database:', err);
      }
    }
  };

  const updateDeviceHeartbeat = async (deviceId: string, status: EdgeDevice['status']) => {
    const cameraStatus = status === 'online' ? 'active' : 'offline';
    setEdgeDevices(prev =>
      prev.map(dev => (dev.deviceId === deviceId ? { ...dev, status, cameraStatus } : dev))
    );

    if (isFirebaseConfigured && db) {
      try {
        const { doc, updateDoc } = await import('firebase/firestore');
        await updateDoc(doc(db, 'edgeDevices', deviceId), {
          status,
          cameraStatus,
          lastHeartbeatAt: new Date().toISOString(),
        });
      } catch (err) {
        console.error('[Firestore Error] Failed to update device in database:', err);
      }
    }
  };

  const triggerRandomVc = async (instituteId: string): Promise<VideoVerification> => {
    const inst = institutes.find(i => i.instituteId === instituteId) || institutes[0];
    const vc: VideoVerification = {
      verificationId: `vc_${Date.now()}`,
      instituteId: inst.instituteId,
      instituteName: inst.name,
      initiatedBy: 'PMU Central Automation Engine',
      selectedReason: inst.riskScore > 50 ? 'elevated_risk' : 'routine_sample',
      status: 'requested',
      requestedAt: new Date().toISOString(),
      checklist: {
        activityAreaVerified: false,
        staffPresenceConfirmed: false,
        beneficiariesPresentConfirmed: false,
        amenitiesAndFoodChecked: false,
      },
      evidenceReferences: [],
    };
    setActiveVc(vc);

    if (isFirebaseConfigured && db) {
      try {
        const { doc, setDoc } = await import('firebase/firestore');
        await setDoc(doc(db, 'videoVerifications', vc.verificationId), vc);
      } catch (err) {
        console.error('[Firestore Error] Failed to persist VC session to database:', err);
      }
    }

    return vc;
  };

  const assignSurpriseInspection = async (assignmentData: Partial<InspectionAssignment>) => {
    const assignmentId = `asgn_${Date.now()}`;
    const newAssignment: InspectionAssignment = {
      assignmentId,
      instituteId: assignmentData.instituteId || institutes[0].instituteId,
      instituteName: assignmentData.instituteName || institutes[0].name,
      inspectorId: assignmentData.inspectorId || 'usr_insp_01',
      assignedBy: assignmentData.assignedBy || 'Dr. Sunita Rao (PMU)',
      assignedAt: new Date().toISOString(),
      deadlineAt: new Date(Date.now() + 48 * 3600 * 1000).toISOString(),
      priority: assignmentData.priority || 'routine',
      status: 'assigned',
      assignmentReason: assignmentData.assignmentReason || 'Automated risk-based inspection protocol',
    };

    if (assignmentData.instituteId) {
      setInstitutes(prev =>
        prev.map(i =>
          i.instituteId === assignmentData.instituteId
            ? { ...i, lastInspectionAt: new Date().toISOString() }
            : i
        )
      );
    }

    if (isFirebaseConfigured && db) {
      try {
        const { doc, setDoc } = await import('firebase/firestore');
        await setDoc(doc(db, 'inspectionAssignments', assignmentId), newAssignment);
      } catch (err) {
        console.error('[Firestore Error] Failed to save inspection assignment to database:', err);
      }
    }
  };

  return (
    <DataContext.Provider
      value={{
        institutes,
        edgeDevices,
        alerts,
        attendanceEvents,
        inspections,
        selectedInstitute,
        setSelectedInstitute,
        isLiveFirebase: isFirebaseConfigured,
        addAttendanceEvent,
        updateAlertStatus,
        updateDeviceHeartbeat,
        triggerRandomVc,
        assignSurpriseInspection,
        activeVc,
        setActiveVc,
      }}
    >
      {children}
    </DataContext.Provider>
  );
};

export const useData = () => {
  const context = useContext(DataContext);
  if (!context) {
    throw new Error('useData must be used within a DataProvider');
  }
  return context;
};
