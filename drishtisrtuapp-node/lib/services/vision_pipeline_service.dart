import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../constants/appwrite_constants.dart';
import '../models/detection_models.dart';
import 'appwrite_sync_service.dart';

class VisionPipelineService {
  final Random _random = Random();
  final AppwriteDirectSyncService _appwriteSync = AppwriteDirectSyncService();
  
  // Dashboard bridge configuration
  String dashboardEndpoint = 'http://127.0.0.1:8080/api/telemetry';
  String currentZoneId = AppwriteConfig.defaultDocumentId;

  // State
  int gateExpectedCount = 22;
  int detectedHeadcount = 22;
  int get deficit => gateExpectedCount - detectedHeadcount;
  bool get isGhostAnomaly => deficit > 5;
  bool get isBreachAnomaly => deficit < -3;

  // Stream controllers for UI updates
  final _boxesController = StreamController<List<BoundingBox>>.broadcast();
  Stream<List<BoundingBox>> get boxesStream => _boxesController.stream;

  final _attendanceController = StreamController<AttendanceRecord>.broadcast();
  Stream<AttendanceRecord> get attendanceStream => _attendanceController.stream;

  Timer? _inferenceTimer;
  Timer? _syncTimer;

  void startInferencePipeline() {
    _inferenceTimer?.cancel();
    // Simulate real-time YOLO11n inference loop (300ms intervals ~ 3-4 FPS throttled to save power & heat)
    _inferenceTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      _runYolo11nInference();
    });

    _syncTimer?.cancel();
    // Broadcast telemetry to dashboard every 2 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _syncTelemetry();
    });
  }

  void stopInferencePipeline() {
    _inferenceTimer?.cancel();
    _syncTimer?.cancel();
  }

  /// Phase 1: Face Recognition (DeepFace) Log-in
  Future<AttendanceRecord> processFaceLogin({String? overrideName}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final names = ['Aditya S.', 'Vikram R.', 'Neha Sharma', 'Aarav Patel', 'Rohan Verma'];
    final name = overrideName ?? names[_random.nextInt(names.length)];
    final record = AttendanceRecord(
      personId: 'EMP-${_random.nextInt(9000) + 1000}',
      name: name,
      timestamp: DateTime.now(),
      matchConfidence: 0.94 + (_random.nextDouble() * 0.05),
    );

    // Increment gate scan count upon biometric verification
    gateExpectedCount++;
    _attendanceController.add(record);
    _syncTelemetry();
    return record;
  }

  /// Phase 2: YOLO11n Crowd Headcount Detection
  void _runYolo11nInference() {
    // Generate realistic person bounding boxes for detection preview
    final int count = detectedHeadcount;
    final List<BoundingBox> boxes = [];

    // Natural human portrait proportions
    final List<Rect> anchorRects = [
      const Rect.fromLTRB(0.12, 0.25, 0.45, 0.58),
      const Rect.fromLTRB(0.55, 0.22, 0.88, 0.55),
      const Rect.fromLTRB(0.30, 0.40, 0.70, 0.75),
      const Rect.fromLTRB(0.08, 0.35, 0.42, 0.70),
    ];

    for (int i = 0; i < min(count, 4); i++) {
      final anchor = anchorRects[i];
      final jitterX = (_random.nextDouble() - 0.5) * 0.015;
      final jitterY = (_random.nextDouble() - 0.5) * 0.015;
      final conf = 0.88 + (_random.nextDouble() * 0.10);

      boxes.add(
        BoundingBox(
          rect: Rect.fromLTRB(
            (anchor.left + jitterX).clamp(0.0, 1.0),
            (anchor.top + jitterY).clamp(0.0, 1.0),
            (anchor.right + jitterX).clamp(0.0, 1.0),
            (anchor.bottom + jitterY).clamp(0.0, 1.0),
          ),
          label: 'person',
          confidence: double.parse(conf.toStringAsFixed(2)),
        ),
      );
    }

    _boxesController.add(boxes);
  }

  void adjustCounts({int? expected, int? detected}) {
    if (expected != null) gateExpectedCount = max(0, expected);
    if (detected != null) detectedHeadcount = max(0, detected);
    _runYolo11nInference();
    _syncTelemetry();
  }

  Future<void> _syncTelemetry() async {
    final payload = TelemetryPayload(
      zoneId: currentZoneId,
      gateExpectedCount: gateExpectedCount,
      detectedHeadcount: detectedHeadcount,
      deficit: deficit,
      hasAnomaly: isGhostAnomaly || isBreachAnomaly,
      anomalyType: isGhostAnomaly
          ? 'GHOST_ATTENDANCE'
          : (isBreachAnomaly ? 'UNAUTHORIZED_ENTRY' : 'NORMAL'),
      fps: 30,
      timestamp: DateTime.now(),
    );

    try {
      // 1. Fire-and-forget sync to Dashboard
      http.post(
        Uri.parse(dashboardEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload.toJson()),
      ).timeout(const Duration(milliseconds: 800)).ignore();

      // 2. Real-time sync to Appwrite Database
      _appwriteSync.syncZoneTelemetry(
        zoneDocId: currentZoneId,
        expectedCount: gateExpectedCount,
        detectedCount: detectedHeadcount,
      ).ignore();
    } catch (_) {
      // Offline resilient
    }
  }

  void dispose() {
    stopInferencePipeline();
    _boxesController.close();
    _attendanceController.close();
  }
}
