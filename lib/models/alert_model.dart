class AlertModel {
  final String id;
  final String zoneId;
  final String zoneName;
  final String type; // 'missing_persons' | 'camera_tamper_offline' | 'unauthorized_entry'
  final String severity; // 'warning' | 'critical'
  final DateTime timestamp;
  final bool acknowledged;

  const AlertModel({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.acknowledged,
  });

  AlertModel copyWith({
    String? id,
    String? zoneId,
    String? zoneName,
    String? type,
    String? severity,
    DateTime? timestamp,
    bool? acknowledged,
  }) {
    return AlertModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  factory AlertModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AlertModel(
      id: documentId,
      zoneId: json['zoneId'] as String? ?? '',
      zoneName: json['zoneName'] as String? ?? '',
      type: json['type'] as String? ?? 'missing_persons',
      severity: json['severity'] as String? ?? 'warning',
      timestamp: parseDate(json['timestamp']),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zoneId': zoneId,
      'zoneName': zoneName,
      'type': type,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged,
    };
  }
}
