import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/alert_model.dart';
import '../models/app_user_model.dart';
import '../models/inspection_model.dart';
import '../models/zone_model.dart';
import '../services/appwrite_dashboard_service.dart';

// -------------------------------------------------------------
// Mock Data Repository & In-Memory Backend Store
// -------------------------------------------------------------
class SentinelDataRepository {
  final _zonesController = StreamController<List<ZoneModel>>.broadcast();
  final _alertsController = StreamController<List<AlertModel>>.broadcast();

  final List<ZoneModel> _zones = [
    ZoneModel(
      id: 'zone-101',
      name: 'Central Assembly Hall',
      floor: 'Floor 1',
      cctvStreamUrl: 'http://127.0.0.1:8089/stream',
      isCameraOnline: false,
      expectedCount: 92,
      detectedCount: 57,
      discrepancy: 35,
      severity: 'critical',
      lastAuditTimestamp: DateTime.now(),
      uncheckedSince: null,
      escalated: false,
      inchargeName: 'Dr. Ramesh Kumar',
      inchargePhone: '+919876543210',
      pastThreeDaysDetected: const [63, 59, 61],
      persistentAnomalyDays: 3,
      cameraUptimePercent: 96.7,
      totalDowntimeMinutes: 19,
      lastOutageWindow: 'Today 10:32 AM – 10:51 AM',
      targetLatitude: 28.6692,
      targetLongitude: 77.4538,
      noticePolicy: '2_hours_surprise',
    ),
    ZoneModel(
      id: 'zone-102',
      name: 'Robotics Workshop Block B',
      floor: 'Basement 1',
      cctvStreamUrl: 'rtsp://sentinel.internal/stream/zone102',
      isCameraOnline: false, // Camera offline scenario
      expectedCount: 45,
      detectedCount: 0,
      discrepancy: 45,
      severity: 'critical',
      lastAuditTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      uncheckedSince: DateTime.now().subtract(const Duration(minutes: 32)),
      escalated: true,
      inchargeName: 'Er. Rajesh Varma',
      inchargePhone: '+919811223344',
      pastThreeDaysDetected: const [12, 5, 0],
      persistentAnomalyDays: 3,
      cameraUptimePercent: 78.4,
      totalDowntimeMinutes: 142,
      lastOutageWindow: 'Yesterday 14:00 PM – 16:22 PM',
      targetLatitude: 31.6340,
      targetLongitude: 74.8723,
      noticePolicy: '2_hours_surprise',
    ),
    ZoneModel(
      id: 'zone-103',
      name: 'Server Room & Telecom Hub',
      floor: 'Floor 3',
      cctvStreamUrl: 'rtsp://sentinel.internal/stream/zone103',
      isCameraOnline: true,
      expectedCount: 8,
      detectedCount: 6,
      discrepancy: 2,
      severity: 'warning',
      lastAuditTimestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      uncheckedSince: null,
      escalated: false,
      inchargeName: 'Ms. Anita Sharma',
      inchargePhone: '+919899887766',
      pastThreeDaysDetected: const [8, 8, 6],
      persistentAnomalyDays: 1,
      cameraUptimePercent: 99.2,
      totalDowntimeMinutes: 4,
      lastOutageWindow: '3 days ago 04:10 AM – 04:14 AM',
      targetLatitude: 26.8467,
      targetLongitude: 80.9462,
      noticePolicy: 'routine_scheduled',
    ),
    ZoneModel(
      id: 'zone-104',
      name: 'Executive Boardroom',
      floor: 'Floor 4',
      cctvStreamUrl: 'rtsp://sentinel.internal/stream/zone104',
      isCameraOnline: true,
      expectedCount: 22,
      detectedCount: 22,
      discrepancy: 0,
      severity: 'normal',
      lastAuditTimestamp: DateTime.now(),
      uncheckedSince: null,
      escalated: false,
      inchargeName: 'Shri Vikram Malhotra',
      inchargePhone: '+919822334455',
      pastThreeDaysDetected: const [22, 22, 22],
      persistentAnomalyDays: 0,
      cameraUptimePercent: 99.9,
      totalDowntimeMinutes: 0,
      lastOutageWindow: 'None in last 30 days',
      targetLatitude: 28.6139,
      targetLongitude: 77.2090,
      noticePolicy: 'routine_scheduled',
    ),
  ];

  final List<AlertModel> _alerts = [
    AlertModel(
      id: 'alert-01',
      zoneId: 'zone-101',
      zoneName: 'Central Assembly Hall',
      type: 'missing_persons',
      severity: 'critical',
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      acknowledged: false,
    ),
    AlertModel(
      id: 'alert-02',
      zoneId: 'zone-102',
      zoneName: 'Robotics Workshop Block B',
      type: 'camera_tamper_offline',
      severity: 'critical',
      timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
      acknowledged: false,
    ),
  ];

  final List<InspectionModel> _inspections = [];

  final AppwritePollerService _appwritePoller = AppwritePollerService();

  SentinelDataRepository() {
    // Initial emit
    _emit();
    // Start live sync with Appwrite database (all zones)
    _appwritePoller.zonesStream.listen((updatedZones) {
      for (final updatedZone in updatedZones) {
        final idx = _zones.indexWhere((z) => z.id == updatedZone.id);
        if (idx != -1) {
          _zones[idx] = updatedZone;
        } else {
          _zones.add(updatedZone);
        }
      }
      _emit();
    });
    _appwritePoller.startPolling();
  }

  void _emit() {
    _zonesController.add(List.unmodifiable(_zones));
    _alertsController.add(List.unmodifiable(_alerts));
  }

  Stream<List<ZoneModel>> watchZones() async* {
    yield List.unmodifiable(_zones);
    yield* _zonesController.stream;
  }

  Stream<List<AlertModel>> watchAlerts() async* {
    yield List.unmodifiable(_alerts);
    yield* _alertsController.stream;
  }

  Stream<ZoneModel?> watchZone(String zoneId) async* {
    ZoneModel? find(List<ZoneModel> list) =>
        list.where((z) => z.id == zoneId || (zoneId == 'zone-101' && z.name == 'Central Assembly Hall')).firstOrNull;
    yield find(_zones);
    await for (final zones in _zonesController.stream) {
      yield find(zones);
    }
  }

  Stream<List<InspectionModel>> watchInspections() async* {
    yield List.unmodifiable(_inspections);
  }

  void submitInspectionLog({
    required String zoneId,
    required String findings,
    required int manualCountVerified,
    required String status,
    bool gpsVerified = true,
    double gpsDistanceMeters = 73.0,
    String? geoOverrideReason,
  }) {
    final inspectionId = const Uuid().v4();
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    final currentZone = idx != -1 ? _zones[idx] : null;

    final reported = currentZone?.expectedCount ?? 92;
    final aiDetected = currentZone?.detectedCount ?? 57;
    final aiDisc = reported - aiDetected;
    final physDisc = reported - manualCountVerified;
    final compliance = ((manualCountVerified / (reported > 0 ? reported : 1)) * 100).clamp(0, 100).toInt();

    final inspection = InspectionModel(
      id: inspectionId,
      zoneId: zoneId,
      zoneName: currentZone?.name ?? 'Central Assembly Hall',
      inspectorId: 'auditor-001',
      inspectorName: 'Aditya Singh (Lead PMU Auditor)',
      timestamp: DateTime.now(),
      findings: findings,
      manualCountVerified: manualCountVerified,
      status: status,
      gpsVerified: gpsVerified,
      gpsDistanceMeters: gpsDistanceMeters,
      geoOverrideReason: geoOverrideReason,
      reportedBeneficiaries: reported,
      aiDetectedCount: aiDetected,
      physicalHeadcount: manualCountVerified,
      aiDiscrepancy: aiDisc,
      physicalDiscrepancy: physDisc,
      compliancePercent: compliance,
      verdict: physDisc > 5 ? 'NON_COMPLIANT' : 'COMPLIANT',
      auditHash: 'sha256_${DateTime.now().millisecondsSinceEpoch}_${zoneId.hashCode}',
    );
    _inspections.insert(0, inspection);

    if (idx != -1) {
      final current = _zones[idx];
      if (status == 'resolved') {
        _zones[idx] = current.copyWith(
          detectedCount: manualCountVerified,
          discrepancy: 0,
          severity: 'normal',
          uncheckedSince: null,
          escalated: false,
          lastAuditTimestamp: DateTime.now(),
        );
      }
    }
    _emit();
  }

  void verifyManualAnomaly({
    required String zoneId,
    required String decision, // 'false_alarm' | 'continue_monitoring' | 'surprise_inspection'
    required String reason,
  }) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    if (idx != -1) {
      final current = _zones[idx];
      if (decision == 'false_alarm') {
        _zones[idx] = current.copyWith(
          severity: 'normal',
          discrepancy: 0,
          escalated: false,
        );
      } else if (decision == 'surprise_inspection') {
        _zones[idx] = current.copyWith(
          severity: 'critical',
          escalated: true,
          noticePolicy: '2_hours_surprise',
          scheduledInspectionTime: DateTime.now().add(const Duration(hours: 2)),
        );
        _alerts.insert(
          0,
          AlertModel(
            id: const Uuid().v4(),
            zoneId: zoneId,
            zoneName: current.name,
            type: 'surprise_inspection_triggered',
            severity: 'critical',
            timestamp: DateTime.now(),
            acknowledged: false,
          ),
        );
      }
      _emit();
    }
  }

  void updateNoticePolicy(String zoneId, String policy) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    if (idx != -1) {
      _zones[idx] = _zones[idx].copyWith(noticePolicy: policy);
      _emit();
    }
  }

  void triggerEscalation(String zoneId, String reason) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    if (idx != -1) {
      final current = _zones[idx];
      _zones[idx] = current.copyWith(
        escalated: true,
        severity: 'critical',
        uncheckedSince: DateTime.now(),
      );

      _alerts.insert(
        0,
        AlertModel(
          id: const Uuid().v4(),
          zoneId: zoneId,
          zoneName: current.name,
          type: 'missing_persons',
          severity: 'critical',
          timestamp: DateTime.now(),
          acknowledged: false,
        ),
      );
    }
    _emit();
  }

  void acknowledgeAlert(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _alerts[idx] = _alerts[idx].copyWith(acknowledged: true);
      _emit();
    }
  }

  void toggleCameraStatus(String zoneId) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    if (idx != -1) {
      final current = _zones[idx];
      final newOnline = !current.isCameraOnline;
      _zones[idx] = current.copyWith(
        isCameraOnline: newOnline,
        detectedCount: newOnline ? current.expectedCount - current.discrepancy : 0,
      );
      _emit();
    }
  }

  void setStreamUrl(String zoneId, String streamUrl) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    if (idx != -1) {
      _zones[idx] = _zones[idx].copyWith(
        cctvStreamUrl: streamUrl,
        isCameraOnline: true,
      );
      _emit();
    }
  }

  void updateTelemetryFromNode({
    required String zoneId,
    required int expectedCount,
    required int detectedCount,
  }) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    final discrepancy = expectedCount - detectedCount;
    final severity = discrepancy > 5 ? 'critical' : (discrepancy > 0 ? 'warning' : 'normal');

    if (idx != -1) {
      _zones[idx] = _zones[idx].copyWith(
        expectedCount: expectedCount,
        detectedCount: detectedCount,
        discrepancy: discrepancy,
        severity: severity,
        isCameraOnline: true,
        lastAuditTimestamp: DateTime.now(),
      );
    }
    _emit();
  }

  void startVideoCall(String zoneId, String callerName) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    final roomName = 'dosje_audit_${zoneId.replaceAll('-', '_')}';
    final jitsiUrl = 'https://meet.jit.si/$roomName';

    if (idx != -1) {
      _zones[idx] = _zones[idx].copyWith(
        callStatus: 'ringing',
        callerName: callerName,
        activeRoomUrl: jitsiUrl,
      );
      _emit();
    }
  }

  void acceptVideoCall(String zoneId) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    if (idx != -1) {
      _zones[idx] = _zones[idx].copyWith(callStatus: 'active');
      _emit();
    }
  }

  void endVideoCall(String zoneId) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    if (idx != -1) {
      _zones[idx] = _zones[idx].copyWith(
        callStatus: 'ended',
        activeRoomUrl: null,
      );
      _emit();
    }
  }
}

// -------------------------------------------------------------
// Riverpod Providers
// -------------------------------------------------------------
final sentinelRepositoryProvider = Provider<SentinelDataRepository>((ref) {
  return SentinelDataRepository();
});

class AuthStateNotifier extends StateNotifier<AppUser?> {
  AuthStateNotifier()
      : super(const AppUser(
          id: 'user-001',
          email: 'lead.auditor@sentinel.org',
          fullName: 'Aditya Singh (Lead PMU Auditor)',
          role: 'official', // 'official' | 'inspector' | 'incharge'
        ));

  void signIn(String email, String password, {String role = 'official'}) {
    state = AppUser(
      id: 'user-001',
      email: email,
      fullName: role == 'official'
          ? 'Aditya Singh (DoSJE Lead Official)'
          : (role == 'inspector' ? 'Er. Vikram Sharma (PMU-04 Inspector)' : 'Dr. Ramesh Kumar (Project Incharge)'),
      role: role,
    );
  }

  void signOut() {
    state = null;
  }
}

final currentUserProvider = StateNotifierProvider<AuthStateNotifier, AppUser?>((ref) {
  return AuthStateNotifier();
});

final zonesStreamProvider = StreamProvider<List<ZoneModel>>((ref) {
  final repo = ref.watch(sentinelRepositoryProvider);
  return repo.watchZones();
});

final selectedZoneProvider = StateProvider<String?>((ref) => 'zone-101');

final zoneDetailStreamProvider = StreamProvider.family<ZoneModel?, String>((ref, zoneId) {
  final repo = ref.watch(sentinelRepositoryProvider);
  return repo.watchZone(zoneId);
});

final criticalAlertsStreamProvider = StreamProvider<List<AlertModel>>((ref) {
  final repo = ref.watch(sentinelRepositoryProvider);
  return repo.watchAlerts().map((list) => list.where((a) => !a.acknowledged).toList());
});

final criticalAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(criticalAlertsStreamProvider);
  return alerts.maybeWhen(
    data: (list) => list.where((a) => a.severity == 'critical').length,
    orElse: () => 0,
  );
});

final recentInspectionsStreamProvider = StreamProvider<List<InspectionModel>>((ref) {
  final repo = ref.watch(sentinelRepositoryProvider);
  return repo.watchInspections();
});

class InspectionActionController extends StateNotifier<AsyncValue<void>> {
  final SentinelDataRepository _repo;

  InspectionActionController(this._repo) : super(const AsyncValue.data(null));

  Future<void> submitInspectionLog({
    required String zoneId,
    required String findings,
    required int manualCountVerified,
    required String status,
    bool gpsVerified = true,
    double gpsDistanceMeters = 73.0,
    String? geoOverrideReason,
  }) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 300));
    _repo.submitInspectionLog(
      zoneId: zoneId,
      findings: findings,
      manualCountVerified: manualCountVerified,
      status: status,
      gpsVerified: gpsVerified,
      gpsDistanceMeters: gpsDistanceMeters,
      geoOverrideReason: geoOverrideReason,
    );
    state = const AsyncValue.data(null);
  }

  Future<void> verifyManualAnomaly({
    required String zoneId,
    required String decision,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 300));
    _repo.verifyManualAnomaly(zoneId: zoneId, decision: decision, reason: reason);
    state = const AsyncValue.data(null);
  }

  Future<void> updateNoticePolicy(String zoneId, String policy) async {
    _repo.updateNoticePolicy(zoneId, policy);
  }

  Future<void> triggerManualEscalation(String zoneId, String reason) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 300));
    _repo.triggerEscalation(zoneId, reason);
    state = const AsyncValue.data(null);
  }

  Future<void> acknowledgeAlert(String alertId) async {
    _repo.acknowledgeAlert(alertId);
  }

  Future<void> toggleCamera(String zoneId) async {
    _repo.toggleCameraStatus(zoneId);
  }

  Future<void> setStreamUrl(String zoneId, String streamUrl) async {
    _repo.setStreamUrl(zoneId, streamUrl);
  }

  void startVideoCall(String zoneId, String callerName) {
    _repo.startVideoCall(zoneId, callerName);
  }

  void acceptVideoCall(String zoneId) {
    _repo.acceptVideoCall(zoneId);
  }

  void endVideoCall(String zoneId) {
    _repo.endVideoCall(zoneId);
  }
}

final inspectionActionControllerProvider =
    StateNotifierProvider<InspectionActionController, AsyncValue<void>>((ref) {
  return InspectionActionController(ref.watch(sentinelRepositoryProvider));
});

