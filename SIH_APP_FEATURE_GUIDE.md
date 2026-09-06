# 🏛️ DrishtiSetu (दृष्टिसेतु) - SIH Sentinel App Architecture & Feature Guide

**SIH Problem Statement 26095**: Centralized Scheme Monitoring, Edge CCTV Vision, Multi-Factor Turnstile Verification, and Real-Time Surprise Inspections for the **Department of Social Justice & Empowerment (DoSJE)**.

---

## 📱 App Overview & Current Screen Breakdown

Here is what each file and screen in `dhristisetu_app` currently does:

### 1. `lib/screens/login_screen.dart` — Multi-Role Authentication Terminal
- **What it does**:
  - Serves as the high-security entrance to the Sentinel platform.
  - Features role switching between **Lead Auditor (DoSJE Console)** and **Site Incharge (Facility Portal)**.
  - Controls access to respective interfaces depending on the authenticated role.
- **Next-Level Design Ideas**:
  - Biometric fingerprint/FaceID lock icon.
  - Animated Government of India / DoSJE digital watermark.
  - Quick PIN login for field inspectors.

---

### 2. `lib/screens/dashboard_screen.dart` — Central Surveillance & Telemetry Center
- **What it does**:
  - Displays real-time operational metrics across all monitored facility zones (Assembly Hall, Vocational Lab, Main Dining, etc.).
  - **Headcount Deficit Card**: Compares Gate scanned biometric count against live YOLO AI camera headcount.
  - **Feed Online & Hardware Telemetry**: Shows live RTSP camera ping, frame drop rate, and hardware acceleration status.
  - **Anomaly Risk Index**: Live threat score (`STABLE`, `ELEVATED`, `CAMERA FAILURE (CRITICAL)`).
  - **Zone Drawer**: Allows switching between different floors and monitored rooms.
- **Next-Level Design Ideas**:
  - Live animated radar scanner sweeping across zones.
  - Interactive 2D/isometric facility floor plan with pulsing camera status nodes.
  - Ghost beneficiary risk thermometer badge (`High Anomaly`, `Funding At Risk`).

---

### 3. `lib/screens/inspection_screen.dart` — Live Audit & Surprise Inspection Console
- **What it does**:
  - Central terminal where the auditor performs on-site or remote verification.
  - **Live CCTV Video Stream**: Integrates phone camera or RTSP edge stream with YOLO bounding boxes.
  - **Two-Way Voice Intercom & Remote VC Hub**:
    - `WHATSAPP VC`: 1-Tap dispatch of surprise inspection notice + instant WhatsApp video dialer to the Site Incharge.
    - `ROOM VC`: Embedded secure WebRTC conference room.
    - `WALKIE`: Push-to-talk live facility microphone intercom.
    - `TTS MSG`: Text-to-speech audio broadcast directly to the facility speaker.
  - **Physical Audit Verification Form**: Manual headcount inputs, field observation notes, discrepancy clearance, and authority escalation.
- **Next-Level Design Ideas**:
  - **Live Geo-Fencing & GPS Watermark**: Displays real-time latitude, longitude, and "Within 25m Perimeter" badge.
  - **UIDAI Masked Aadhaar Turnstile Logs**: Expandable table of student turnstile taps with biometric timestamps.
  - **1-Tap PDF Ministry Dossier Generator**: Exports a formal DoSJE inspection summary signed digitally by the auditor.

---

### 4. `lib/screens/video_conferencing_screen.dart` — Unified Video Inspection Hub
- **What it does**:
  - Provides a dedicated high-tech video inspection chamber.
  - Shows verified Site Incharge profile (`Dr. Ramesh Kumar`, phone number, and DoSJE verification badge).
  - Direct 1-Tap "Start WhatsApp Video Call" action card.
  - Includes camera switch (Selfie / Rear), mic mute/unmute, and encrypted video call status overlays.
- **Next-Level Design Ideas**:
  - Live AI Face-Matching badge overlay ("Incharge Verified: 98.4% Match").
  - On-screen snapshot button to capture visual proof for the audit dossier.

---

### 5. `lib/screens/incharge_portal_screen.dart` — Facility Incharge Companion Portal
- **What it does**:
  - The interface seen by the ground NGO / Center Incharge.
  - Displays facility attendance status, incoming surprise inspection alerts, and hardware stream connectivity.
- **Next-Level Design Ideas**:
  - Daily meal & attendance biometric synchronization checklist.
  - Instant response portal for flagged audit discrepancies.

---

### 6. `lib/services/whatsapp_call_service.dart` — 1-Tap WhatsApp Inspection Dispatcher
- **What it does**:
  - Formulates an official, formatted DoSJE Surprise Inspection Notice with auditor credentials, zone details, and discrepancy counts.
  - Launches WhatsApp (`whatsapp://send`) directly to the incharge's phone number, with fallback to `https://wa.me/`.

---

## 🚀 Recommended Prompts to Design This to the Next Level

You can copy-paste any of the prompts below into the chat to instantly build the corresponding feature:

### Prompt Option A: "Level Up the Dashboard UI to a Futuristic Cyber-Glass Command Center"
> *"Redesign `dashboard_screen.dart` into a sleek glassmorphic command center. Add glowing cyan/emerald telemetry cards, an animated live pulse radar for monitored zones, and a visual ghost-beneficiary anomaly risk gauge."*

### Prompt Option B: "Add GPS Geo-Fencing & Tamper-Proof Watermark to Inspection Screen"
> *"Add a live GPS Geo-Fencing card to `inspection_screen.dart`. Show current latitude, longitude, and an animated green 'WITHIN 20M FACILITY GEO-FENCE' badge to prove physical auditor presence, and overlay an audit watermark on the camera."*

### Prompt Option C: "Add UIDAI Masked Aadhaar Turnstile Attendance Verification"
> *"Add a biometric turnstile attendance log drawer/tab in `inspection_screen.dart`. Display student entry timestamps, masked Aadhaar tokens (XXXX-XXXX-4821), and compare total turnstile check-ins against YOLO camera count."*

### Prompt Option D: "Add 1-Tap Official DoSJE Inspection Dossier & PDF Export"
> *"Add an 'Export Ministry Dossier' modal to `inspection_screen.dart`. Generate a formal Government of India (DoSJE) audit summary complete with discrepancy breakdown, inspection timestamps, and a digital sign-off certificate."*
