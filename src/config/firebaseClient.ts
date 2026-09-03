import { initializeApp, getApps, type FirebaseApp } from 'firebase/app';
import { getAuth, type Auth } from 'firebase/auth';
import { getFirestore, type Firestore } from 'firebase/firestore';
import { getStorage, type FirebaseStorage } from 'firebase/storage';
import { getAnalytics, isSupported, type Analytics } from 'firebase/analytics';

/**
 * Firebase Client Configuration
 * Strictly reads from standard environment variables (NEXT_PUBLIC_FIREBASE_* or VITE_FIREBASE_*)
 * Falls back to project defaults if not provided.
 */

// Vite uses import.meta.env, while Next.js uses process.env.
// We support both environments seamlessly.
const getEnv = (key: string): string | undefined => {
  if (typeof import.meta !== 'undefined' && (import.meta as any).env) {
    return (import.meta as any).env[key] || (import.meta as any).env[`VITE_${key.replace('NEXT_PUBLIC_', '')}`];
  }
  const proc = (globalThis as any).process;
  if (typeof proc !== 'undefined' && proc.env) {
    return proc.env[key];
  }
  return undefined;
};

export const firebaseConfig = {
  apiKey: getEnv('NEXT_PUBLIC_FIREBASE_API_KEY') || "AIzaSyCEkAOJ5w8pEGfFQMeGPYRf61-TuzHV_qM",
  authDomain: getEnv('NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN') || "drishtisetu-729a7.firebaseapp.com",
  projectId: getEnv('NEXT_PUBLIC_FIREBASE_PROJECT_ID') || "drishtisetu-729a7",
  storageBucket: getEnv('NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET') || "drishtisetu-729a7.firebasestorage.app",
  messagingSenderId: getEnv('NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID') || "462594599208",
  appId: getEnv('NEXT_PUBLIC_FIREBASE_APP_ID') || "1:462594599208:web:6779ec2a9b307d1b5a881d",
  measurementId: getEnv('NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID') || "G-9CNPNN32ZY",
  vapidKey: getEnv('NEXT_PUBLIC_FIREBASE_VAPID_KEY'),
};

/**
 * Validates whether the Firebase configuration has been provided.
 */
export const isFirebaseConfigured = Boolean(
  firebaseConfig.apiKey &&
  firebaseConfig.projectId &&
  firebaseConfig.apiKey !== 'your_api_key_here'
);

let app: FirebaseApp | undefined;
let auth: Auth | undefined;
let db: Firestore | undefined;
let storage: FirebaseStorage | undefined;
let analytics: Analytics | undefined;

if (isFirebaseConfigured) {
  try {
    app = getApps().length > 0 ? getApps()[0] : initializeApp(firebaseConfig);
    auth = getAuth(app);
    db = getFirestore(app);
    storage = getStorage(app);
    
    // Initialize analytics only in supported environments (browser)
    if (typeof window !== 'undefined') {
      isSupported().then((supported) => {
        if (supported && app) {
          analytics = getAnalytics(app);
        }
      }).catch(() => {});
    }
    
    console.info('[DrishtiSetu Firebase] Initialized successfully with project:', firebaseConfig.projectId);
  } catch (error) {
    console.warn('[DrishtiSetu Firebase] Initialization error, falling back to demo sandbox mode:', error);
  }
} else {
  console.info('[DrishtiSetu Sandbox] Firebase credentials not configured. Running in Local Simulated Demo Mode with rich seed dataset.');
}

export { app, auth, db, storage, analytics };

