import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/appwrite_constants.dart';

class AppwriteDirectSyncService {
  final http.Client _httpClient = http.Client();

  /// Updates the zone document directly via Appwrite REST API
  Future<bool> syncZoneTelemetry({
    required String zoneDocId,
    required int expectedCount,
    required int detectedCount,
  }) async {
    final deficit = expectedCount - detectedCount;
    final severity = deficit > 5 ? 'critical' : (deficit > 0 ? 'warning' : 'normal');

    final url = Uri.parse(
      '${AppwriteConfig.endpoint}/databases/${AppwriteConfig.databaseId}/collections/${AppwriteConfig.zonesCollectionId}/documents/$zoneDocId',
    );

    final payload = {
      'data': {
        'expectedCount': expectedCount,
        'detectedCount': detectedCount,
        'discrepancy': deficit,
        'severity': severity,
        'isCameraOnline': true,
        'lastAuditTimestamp': DateTime.now().toIso8601String(),
      }
    };

    try {
      final response = await _httpClient
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Appwrite-Project': AppwriteConfig.projectId,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Creates initial zone document if it doesn't exist yet
  Future<bool> createInitialZoneDoc({
    required String zoneDocId,
    required String name,
    required String floor,
  }) async {
    final url = Uri.parse(
      '${AppwriteConfig.endpoint}/databases/${AppwriteConfig.databaseId}/collections/${AppwriteConfig.zonesCollectionId}/documents',
    );

    final payload = {
      'documentId': zoneDocId,
      'data': {
        'zoneId': zoneDocId,
        'name': name,
        'floor': floor,
        'expectedCount': 22,
        'detectedCount': 22,
        'discrepancy': 0,
        'severity': 'normal',
        'isCameraOnline': true,
        'lastAuditTimestamp': DateTime.now().toIso8601String(),
      }
    };

    try {
      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': AppwriteConfig.projectId,
        },
        body: jsonEncode(payload),
      );
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
