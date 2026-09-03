import {
  collection,
  doc,
  writeBatch,
  getDocs,
} from 'firebase/firestore';
import { db, isFirebaseConfigured } from '../config/firebaseClient';
import {
  DEMO_USERS,
  DEMO_INSTITUTES,
  DEMO_EDGE_DEVICES,
  DEMO_ALERTS,
  generateDemoAttendanceEvents,
  DEMO_INSPECTIONS,
} from '../data/mockData';

export const seedService = {
  /**
   * Seeds Firestore with realistic initial data when Firebase is connected
   */
  async seedFirestoreDatabase(): Promise<{ success: boolean; message: string }> {
    if (!isFirebaseConfigured || !db) {
      return {
        success: false,
        message: 'Firebase is not yet configured. Please populate .env.local with your Firebase project keys first.',
      };
    }

    try {
      console.info('[DrishtiSetu Seed] Starting Firestore database population...');
      const batch = writeBatch(db);

      // 1. Seed Users
      DEMO_USERS.forEach(user => {
        const ref = doc(db!, 'users', user.uid);
        batch.set(ref, user);
      });

      // 2. Seed Institutes
      DEMO_INSTITUTES.forEach(inst => {
        const ref = doc(db!, 'institutes', inst.instituteId);
        batch.set(ref, inst);
      });

      // 3. Seed Edge Devices
      DEMO_EDGE_DEVICES.forEach(dev => {
        const ref = doc(db!, 'edgeDevices', dev.deviceId);
        batch.set(ref, dev);
      });

      // 4. Seed Alerts
      DEMO_ALERTS.forEach(alt => {
        const ref = doc(db!, 'alerts', alt.alertId);
        batch.set(ref, alt);
      });

      // 5. Seed Attendance Events
      const events = generateDemoAttendanceEvents().slice(0, 30);
      events.forEach(evt => {
        const ref = doc(db!, 'attendanceEvents', evt.eventId);
        batch.set(ref, evt);
      });

      // 6. Seed Inspections
      DEMO_INSPECTIONS.forEach(insp => {
        const ref = doc(db!, 'inspectionReports', insp.reportId);
        batch.set(ref, insp);
      });

      await batch.commit();
      console.info('[DrishtiSetu Seed] Successfully seeded Firestore collections!');
      return {
        success: true,
        message: 'Successfully seeded 12 institutes, edge devices, alerts, and attendance events to Firestore!',
      };
    } catch (err: any) {
      console.error('[DrishtiSetu Seed Error]:', err);
      return {
        success: false,
        message: `Firestore seeding error: ${err?.message || err}`,
      };
    }
  }
};
