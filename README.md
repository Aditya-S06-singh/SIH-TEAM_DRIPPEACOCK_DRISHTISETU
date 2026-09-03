# DrishtiSetu (दृष्टिसेतु) - Smart Real-Time Monitoring & Inspection Platform

**SIH Problem Statement 26095**: Centralized Scheme Monitoring, Edge CCTV Vision, Multi-Factor Gate Verification & Transparent AI Risk Intelligence for the Department of Social Justice & Empowerment (DoSJE).

---

## 1. Quick Start Guide

### Running Locally in Sandbox / Demo Mode (Out of the box)
The application automatically starts in rich simulated demo mode with 12 Indian institutes, edge Raspberry Pi video streams, 100+ masked attendance records, and active anomaly alerts:

```bash
cd drishtisetu
npm install
npm run dev
```

Visit `http://localhost:5173` to experience the full platform!

---

## 2. Connecting to Your Production Firebase Project

When you are ready to connect to your live Firebase project:

1. Copy `.env.example` to `.env.local`:
   ```bash
   cp .env.example .env.local
   ```
2. Paste your project values into `.env.local`:
   ```env
   NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSy...
   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your-app.firebaseapp.com
   NEXT_PUBLIC_FIREBASE_PROJECT_ID=your-app
   NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your-app.appspot.com
   NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=1234567890
   NEXT_PUBLIC_FIREBASE_APP_ID=1:1234567890:web:abcde
   NEXT_PUBLIC_FIREBASE_VAPID_KEY=BMx...
   ```
3. Restart the development server (`npm run dev`).
4. Click the **"Seed Data"** button in the top banner to populate your Firestore database with the 12 sample institutes, devices, and records in one click!

---

## 3. Integrating Your Custom AI Recognition Models (`/src/ai-models`)

Place your model files (ONNX, TFLite, MediaPipe) into `src/ai-models/weights/`:

- **Edge CCTV Person & Crowd Density**: `src/ai-models/cctv/personDetector.ts`
  - Reconciles headcount against gate attendance logs.
- **Safety / PPE Uniform Compliance**: `src/ai-models/cctv/safetyCompliance.ts`
  - Detects Helmets, Vests, Masks, and Institute ID Badges.
- **Gate Optical Liveness (Anti-Spoof)**: `src/ai-models/gate/faceLiveness.ts`
  - Tests micro-motion and eye-blink reflex without storing raw facial images.
- **Cryptographic Token Verification**: `src/ai-models/gate/biometricHashVerifier.ts`
  - Salted one-way HMAC matching keeping Aadhaar numbers strictly masked (`XXXX-XXXX-4821`).

See [`src/ai-models/README.md`](file:///c:/Users/Aditya%20Singh/Downloads/New%20folder%20(4)/flutter_application_1/drishtisetu/src/ai-models/README.md) for full instructions.

---

## 4. Role-Based Access Control (RBAC) Demo Accounts
Switch between roles at any time using the header role selector:
- **DoSJE Official**: `official@drishtisetu.gov.in`
- **PMU Supervisor**: `supervisor@drishtisetu.gov.in`
- **PMU Inspector**: `inspector@drishtisetu.gov.in`
- **Institute / NGO Project Incharge**: `admin@ngo-demo.org`
- **Gate Entry Operator**: `operator@ngo-demo.org`

---

## 5. Security Rules & Serverless Cloud Functions
- **Firestore Security Rules**: Defined in `firestore.rules` enforcing strict RBAC permissions and immutable audit logs.
- **Storage Security Rules**: Defined in `storage.rules` enforcing MIME validation and 15MB file limits.
- **Cloud Functions**: Defined in `functions/src/index.ts` handling automated attendance reconciliation, heartbeat outage detection, risk calculations, and random inspection dispatches.
