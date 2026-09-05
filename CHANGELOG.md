# Changelog

All notable changes to the **DrishtiSetu** (Attendance & Surveillance Sentinel) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] - 2026-09-05 (version-0.1)

### Added
- **Core Architecture & State Management**:
  - Implemented Riverpod providers for real-time audit zones, live streams, metrics, and alerts.
  - Added zone data models (`ZoneModel`, `AlertModel`, `InspectionAction`).
- **Sentinel Dashboard (`DashboardScreen`)**:
  - Real-time audit zone switcher with floor, gate vs. YOLO camera tally metrics, and sync status.
  - Anomaly detection status with dynamic Ghost Attendance / Deficit alerts and risk indices.
  - Camera feed status indicators (online / offline, ping latency, packet drops).
  - Unacknowledged anomaly alerts bottom sheet with one-click resolution.
  - Interactive multi-zone overview modal for swift zone switching and status checking.
- **Live Inspection Console (`LiveInspectionScreen`)**:
  - Camera feed simulator with inspection status overlays and telemetry.
  - Quick action dispatch (Trigger Inspection, Request Security Audit, Force Re-Sync).
  - Detailed audit discrepancy logs and alert dismissals.
- **Authentication (`LoginScreen`)**:
  - Sleek dark cyber-sentinel UI with credential validation and secure access state.

### Changed
- **UI & Layout Optimization**:
  - Compacted the AppBar zone selection dropdown (`isExpanded`, `isDense`, `ConstrainedBox`, and text ellipsis) to prevent RenderFlex overflow across various screen resolutions.
  - Polished dark cyber theme palette (`0xFF090D12` scaffold background, cyan and red status indicators).

### Removed
- Removed legacy presentation info icon button from the AppBar to declutter the sentinel navigation header.
