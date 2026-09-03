import { initializeApp } from 'firebase/app';
import { getFirestore, writeBatch, doc } from 'firebase/firestore';
import {
  DEMO_USERS,
  DEMO_INSTITUTES,
  DEMO_EDGE_DEVICES,
  DEMO_ALERTS,
  generateDemoAttendanceEvents,
  DEMO_INSPECTIONS,
} from './src/data/mockData.ts';

const firebaseConfig = {
  apiKey: "AIzaSyCEkAOJ5w8pEGfFQMeGPYRf61-TuzHV_qM",
  authDomain: "drishtisetu-729a7.firebaseapp.com",
  projectId: "drishtisetu-729a7",
  storageBucket: "drishtisetu-729a7.firebasestorage.app",
  messagingSenderId: "462594599208",
  appId: "1:462594599208:web:6779ec2a9b307d1b5a881d",
  measurementId: "G-9CNPNN32ZY"
};

async function seed() {
  console.log('Connecting to Firebase Project: ' + firebaseConfig.projectId + '...');
  const app = initializeApp(firebaseConfig);
  const db = getFirestore(app);

  console.log('Populating Firestore database collections...');
  const batch = writeBatch(db);

  // 1. Users
  DEMO_USERS.forEach(u => batch.set(doc(db, 'users', u.uid), u));
  // 2. Institutes
  DEMO_INSTITUTES.forEach(i => batch.set(doc(db, 'institutes', i.instituteId), i));
  // 3. Edge Devices
  DEMO_EDGE_DEVICES.forEach(d => batch.set(doc(db, 'edgeDevices', d.deviceId), d));
  // 4. Alerts
  DEMO_ALERTS.forEach(a => batch.set(doc(db, 'alerts', a.alertId), a));
  // 5. Attendance
  const events = generateDemoAttendanceEvents().slice(0, 30);
  events.forEach(e => batch.set(doc(db, 'attendanceEvents', e.eventId), e));
  // 6. Inspections
  DEMO_INSPECTIONS.forEach(insp => batch.set(doc(db, 'inspectionReports', insp.reportId), insp));

  await batch.commit();
  console.log('SUCCESS: All datasets stored in Cloud Firestore!');
  process.exit(0);
}

seed().catch(err => {
  console.error('SEEDING FAILED:', err);
  process.exit(1);
});
