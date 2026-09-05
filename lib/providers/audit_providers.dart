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
      cctvStreamUrl: 'http://127.0.0.1:8088/stream',
      isCameraOnline: true,
      expectedCount: 142,
      detectedCount: 128,
      discrepancy: 14, // Deficit: 14 people missing
      severity: 'critical',
      lastAuditTimestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      uncheckedSince: DateTime.now().subtract(const Duration(minutes: 18)),
      escalated: false,
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
    // Start live sync with Appwrite
    _appwritePoller.zoneStream.listen((updatedZone) {
      final idx = _zones.indexWhere((z) => z.id == updatedZone.id || z.id == 'zone-101');
      if (idx != -1) {
        final prev = _zones[idx];
        _zones[idx] = ZoneModel(
          id: prev.id,
          name: prev.name,
          floor: prev.floor,
          cctvStreamUrl: prev.cctvStreamUrl.isNotEmpty ? prev.cctvStreamUrl : updatedZone.cctvStreamUrl,
          isCameraOnline: updatedZone.isCameraOnline,
          expectedCount: updatedZone.expectedCount,
          detectedCount: updatedZone.detectedCount,
          discrepancy: updatedZone.discrepancy,
          severity: updatedZone.severity,
          lastAuditTimestamp: updatedZone.lastAuditTimestamp,
          uncheckedSince: prev.uncheckedSince,
          escalated: prev.escalated,
        );
        _emit();
      }
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

  void submitInspectionLog({
    required String zoneId,
    required String findings,
    required int manualCountVerified,
    required String status,
  }) {
    final inspectionId = const Uuid().v4();
    final inspection = InspectionModel(
      id: inspectionId,
      zoneId: zoneId,
      inspectorId: 'auditor-001',
      inspectorName: 'Chief Field Auditor',
      timestamp: DateTime.now(),
      findings: findings,
      manualCountVerified: manualCountVerified,
      status: status,
    );
    _inspections.add(inspection);

    final idx = _zones.indexWhere((z) => z.id == zoneId);
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
          fullName: 'Aditya Singh (Lead Auditor)',
          role: 'security_lead',
        ));

  void signIn(String email, String password) {
    state = AppUser(
      id: 'user-001',
      email: email,
      fullName: 'Field Inspector',
      role: 'security_lead',
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

class InspectionActionController extends StateNotifier<AsyncValue<void>> {
  final SentinelDataRepository _repo;

  InspectionActionController(this._repo) : super(const AsyncValue.data(null));

  Future<void> submitInspectionLog({
    required String zoneId,
    required String findings,
    required int manualCountVerified,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 300));
    _repo.submitInspectionLog(
      zoneId: zoneId,
      findings: findings,
      manualCountVerified: manualCountVerified,
      status: status,
    );
    state = const AsyncValue.data(null);
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
}

final inspectionActionControllerProvider =
    StateNotifierProvider<InspectionActionController, AsyncValue<void>>((ref) {
  return InspectionActionController(ref.watch(sentinelRepositoryProvider));
});
