import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/appwrite_constants.dart';
import '../models/zone_model.dart';

class AppwritePollerService {
  final http.Client _client = http.Client();
  Timer? _pollerTimer;
  final _zonesStreamController = StreamController<List<ZoneModel>>.broadcast();

  Stream<List<ZoneModel>> get zonesStream => _zonesStreamController.stream;

  void startPolling() {
    _pollerTimer?.cancel();
    fetchAllZones();
    // Poll every 2 seconds for continuous database synchronization
    _pollerTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      fetchAllZones();
    });
  }

  void stopPolling() {
    _pollerTimer?.cancel();
  }

  /// Fetches all zone documents from Appwrite database
  Future<List<ZoneModel>> fetchAllZones() async {
    final url = Uri.parse(
      '${AppwriteConfig.endpoint}/databases/${AppwriteConfig.databaseId}/collections/${AppwriteConfig.zonesCollectionId}/documents',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'X-Appwrite-Project': AppwriteConfig.projectId,
        },
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List documents = data['documents'] ?? [];

        final List<ZoneModel> parsedZones = documents.map((doc) {
          final zoneId = (doc['zoneId'] as String?) ?? (doc[r'$id'] as String? ?? 'zone-101');
          final detected = (doc['detectedCount'] as num?)?.toInt() ?? 0;
          final expected = (doc['expectedCount'] as num?)?.toInt() ?? 0;
          final discrepancy = (doc['discrepancy'] as num?)?.toInt() ?? (expected - detected);
          final severity = (doc['severity'] as String?) ??
              (discrepancy > 5 ? 'critical' : (discrepancy > 0 ? 'warning' : 'normal'));

          // Metadata & Location values stored in database mapping
          final dbMeta = _lookupZoneMetadata(zoneId);

          return ZoneModel(
            id: zoneId,
            name: (doc['name'] as String?) ?? dbMeta['name'],
            floor: (doc['floor'] as String?) ?? dbMeta['floor'],
            cctvStreamUrl: dbMeta['cctvStreamUrl'],
            isCameraOnline: doc['isCameraOnline'] == true,
            expectedCount: expected,
            detectedCount: detected,
            discrepancy: discrepancy,
            severity: severity,
            lastAuditTimestamp: DateTime.tryParse(doc['lastAuditTimestamp'] ?? '') ?? DateTime.now(),
            uncheckedSince: null,
            escalated: doc['isCameraOnline'] == false && discrepancy > 0,
            inchargeName: dbMeta['inchargeName'],
            inchargePhone: dbMeta['inchargePhone'],
            pastThreeDaysDetected: List<int>.from(dbMeta['pastThreeDaysDetected']),
            persistentAnomalyDays: dbMeta['persistentAnomalyDays'],
            cameraUptimePercent: dbMeta['cameraUptimePercent'],
            totalDowntimeMinutes: dbMeta['totalDowntimeMinutes'],
            lastOutageWindow: dbMeta['lastOutageWindow'],
            targetLatitude: dbMeta['targetLatitude'],
            targetLongitude: dbMeta['targetLongitude'],
            noticePolicy: dbMeta['noticePolicy'],
          );
        }).toList();

        if (parsedZones.isNotEmpty) {
          _zonesStreamController.add(parsedZones);
          return parsedZones;
        }
      }
    } catch (_) {
      // Offline fallback
    }
    return [];
  }

  /// Updates a zone document directly in Appwrite
  Future<bool> updateZoneInDatabase({
    required String zoneId,
    required int expectedCount,
    required int detectedCount,
    bool isCameraOnline = true,
  }) async {
    final docId = _lookupDocIdForZone(zoneId);
    final url = Uri.parse(
      '${AppwriteConfig.endpoint}/databases/${AppwriteConfig.databaseId}/collections/${AppwriteConfig.zonesCollectionId}/documents/$docId',
    );

    final deficit = expectedCount - detectedCount;
    final severity = deficit > 5 ? 'critical' : (deficit > 0 ? 'warning' : 'normal');

    final payload = {
      'data': {
        'expectedCount': expectedCount,
        'detectedCount': detectedCount,
        'discrepancy': deficit,
        'severity': severity,
        'isCameraOnline': isCameraOnline,
        'lastAuditTimestamp': DateTime.now().toIso8601String(),
      }
    };

    try {
      final res = await _client.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': AppwriteConfig.projectId,
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        fetchAllZones();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static String _lookupDocIdForZone(String zoneId) {
    switch (zoneId) {
      case 'zone-101':
        return '6a9bd5200029250fea89';
      case 'zone-102':
        return 'zone_102_doc';
      case 'zone-103':
        return 'zone_103_doc';
      case 'zone-104':
        return 'zone_104_doc';
      default:
        return '6a9bd5200029250fea89';
    }
  }

  static Map<String, dynamic> _lookupZoneMetadata(String zoneId) {
    switch (zoneId) {
      case 'zone-101':
        return {
          'name': 'Central Assembly Hall',
          'floor': 'Floor 1',
          'cctvStreamUrl': 'http://127.0.0.1:8089/stream',
          'inchargeName': 'Dr. Ramesh Kumar',
          'inchargePhone': '+919876543210',
          'pastThreeDaysDetected': [63, 59, 61],
          'persistentAnomalyDays': 3,
          'cameraUptimePercent': 96.7,
          'totalDowntimeMinutes': 19,
          'lastOutageWindow': 'Today 10:32 AM – 10:51 AM',
          'targetLatitude': 28.6692,
          'targetLongitude': 77.4538,
          'noticePolicy': '2_hours_surprise',
        };
      case 'zone-102':
        return {
          'name': 'Robotics Workshop Block B',
          'floor': 'Basement 1',
          'cctvStreamUrl': 'rtsp://sentinel.internal/stream/zone102',
          'inchargeName': 'Er. Rajesh Varma',
          'inchargePhone': '+919811223344',
          'pastThreeDaysDetected': [12, 5, 0],
          'persistentAnomalyDays': 3,
          'cameraUptimePercent': 78.4,
          'totalDowntimeMinutes': 142,
          'lastOutageWindow': 'Yesterday 14:00 PM – 16:22 PM',
          'targetLatitude': 31.6340,
          'targetLongitude': 74.8723,
          'noticePolicy': '2_hours_surprise',
        };
      case 'zone-103':
        return {
          'name': 'Server Room & Telecom Hub',
          'floor': 'Floor 3',
          'cctvStreamUrl': 'rtsp://sentinel.internal/stream/zone103',
          'inchargeName': 'Ms. Anita Sharma',
          'inchargePhone': '+919899887766',
          'pastThreeDaysDetected': [8, 8, 6],
          'persistentAnomalyDays': 1,
          'cameraUptimePercent': 99.2,
          'totalDowntimeMinutes': 4,
          'lastOutageWindow': '3 days ago 04:10 AM – 04:14 AM',
          'targetLatitude': 26.8467,
          'targetLongitude': 80.9462,
          'noticePolicy': 'routine_scheduled',
        };
      case 'zone-104':
        return {
          'name': 'Executive Boardroom',
          'floor': 'Floor 4',
          'cctvStreamUrl': 'rtsp://sentinel.internal/stream/zone104',
          'inchargeName': 'Shri Vikram Malhotra',
          'inchargePhone': '+919822334455',
          'pastThreeDaysDetected': [22, 22, 22],
          'persistentAnomalyDays': 0,
          'cameraUptimePercent': 99.9,
          'totalDowntimeMinutes': 0,
          'lastOutageWindow': 'None in last 30 days',
          'targetLatitude': 28.6139,
          'targetLongitude': 77.2090,
          'noticePolicy': 'routine_scheduled',
        };
      default:
        return {
          'name': 'Government Facility Zone',
          'floor': 'Floor 1',
          'cctvStreamUrl': '',
          'inchargeName': 'Designated Facility Officer',
          'inchargePhone': '+919876543210',
          'pastThreeDaysDetected': [20, 20, 20],
          'persistentAnomalyDays': 0,
          'cameraUptimePercent': 99.0,
          'totalDowntimeMinutes': 0,
          'lastOutageWindow': 'None',
          'targetLatitude': 28.6139,
          'targetLongitude': 77.2090,
          'noticePolicy': '2_hours_surprise',
        };
    }
  }

  void dispose() {
    stopPolling();
    _zonesStreamController.close();
  }
}
