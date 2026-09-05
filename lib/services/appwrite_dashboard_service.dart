import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/appwrite_constants.dart';
import '../models/zone_model.dart';

class AppwritePollerService {
  final http.Client _client = http.Client();
  Timer? _pollerTimer;
  final _zoneStreamController = StreamController<ZoneModel>.broadcast();

  Stream<ZoneModel> get zoneStream => _zoneStreamController.stream;

  void startPolling({String? zoneDocId}) {
    final docId = zoneDocId ?? AppwriteConfig.defaultDocumentId;
    _pollerTimer?.cancel();
    fetchOnce(zoneDocId: docId);
    // Poll every 1.5 seconds for instant real-time telemetry updates
    _pollerTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      fetchOnce(zoneDocId: docId);
    });
  }

  void stopPolling() {
    _pollerTimer?.cancel();
  }

  Future<ZoneModel?> fetchOnce({String? zoneDocId}) async {
    final docId = zoneDocId ?? AppwriteConfig.defaultDocumentId;
    final url = Uri.parse(
      '${AppwriteConfig.endpoint}/databases/${AppwriteConfig.databaseId}/collections/${AppwriteConfig.zonesCollectionId}/documents/$docId',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'X-Appwrite-Project': AppwriteConfig.projectId,
        },
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final detected = (data['detectedCount'] as num?)?.toInt() ?? 0;
        final expected = (data['expectedCount'] as num?)?.toInt() ?? 0;
        final discrepancy = (data['discrepancy'] as num?)?.toInt() ?? (expected - detected);
        final zone = ZoneModel(
          id: data['zoneId'] ?? 'zone-101',
          name: data['name'] ?? 'Central Assembly Hall',
          floor: data['floor'] ?? 'Floor 1',
          cctvStreamUrl: 'http://127.0.0.1:8088/stream',
          isCameraOnline: data['isCameraOnline'] == true,
          expectedCount: expected,
          detectedCount: detected,
          discrepancy: discrepancy,
          severity: (data['severity'] as String?) ?? (discrepancy > 5 ? 'critical' : (discrepancy > 0 ? 'warning' : 'normal')),
          lastAuditTimestamp: DateTime.tryParse(data['lastAuditTimestamp'] ?? '') ?? DateTime.now(),
          uncheckedSince: null,
          escalated: false,
        );
        _zoneStreamController.add(zone);
        return zone;
      }
    } catch (_) {
      // Offline fallback: retains last state
    }
    return null;
  }

  void dispose() {
    stopPolling();
    _zoneStreamController.close();
  }
}
