import 'dart:ui';

class BoundingBox {
  final Rect rect; // Normalized coordinates (0.0 to 1.0)
  final String label;
  final double confidence;

  const BoundingBox({
    required this.rect,
    required this.label,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'rect': [rect.left, rect.top, rect.right, rect.bottom],
        'label': label,
        'confidence': confidence,
      };

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    final list = (json['rect'] as List).map((e) => (e as num).toDouble()).toList();
    return BoundingBox(
      rect: Rect.fromLTRB(list[0], list[1], list[2], list[3]),
      label: json['label'] as String? ?? 'person',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.90,
    );
  }
}

class AttendanceRecord {
  final String personId;
  final String name;
  final DateTime timestamp;
  final double matchConfidence;

  const AttendanceRecord({
    required this.personId,
    required this.name,
    required this.timestamp,
    required this.matchConfidence,
  });
}

class TelemetryPayload {
  final String zoneId;
  final int gateExpectedCount;
  final int detectedHeadcount;
  final int deficit;
  final bool hasAnomaly;
  final String anomalyType;
  final int fps;
  final DateTime timestamp;

  const TelemetryPayload({
    required this.zoneId,
    required this.gateExpectedCount,
    required this.detectedHeadcount,
    required this.deficit,
    required this.hasAnomaly,
    required this.anomalyType,
    required this.fps,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'gateExpectedCount': gateExpectedCount,
        'detectedHeadcount': detectedHeadcount,
        'deficit': deficit,
        'hasAnomaly': hasAnomaly,
        'anomalyType': anomalyType,
        'fps': fps,
        'timestamp': timestamp.toIso8601String(),
      };
}
