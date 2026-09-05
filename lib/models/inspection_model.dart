class InspectionModel {
  final String id;
  final String zoneId;
  final String inspectorId;
  final String inspectorName;
  final DateTime timestamp;
  final String findings;
  final int manualCountVerified;
  final String status; // 'resolved' | 'escalated_to_police' | 'false_alarm'

  const InspectionModel({
    required this.id,
    required this.zoneId,
    required this.inspectorId,
    required this.inspectorName,
    required this.timestamp,
    required this.findings,
    required this.manualCountVerified,
    required this.status,
  });

  InspectionModel copyWith({
    String? id,
    String? zoneId,
    String? inspectorId,
    String? inspectorName,
    DateTime? timestamp,
    String? findings,
    int? manualCountVerified,
    String? status,
  }) {
    return InspectionModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      timestamp: timestamp ?? this.timestamp,
      findings: findings ?? this.findings,
      manualCountVerified: manualCountVerified ?? this.manualCountVerified,
      status: status ?? this.status,
    );
  }

  factory InspectionModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return InspectionModel(
      id: documentId,
      zoneId: json['zoneId'] as String? ?? '',
      inspectorId: json['inspectorId'] as String? ?? '',
      inspectorName: json['inspectorName'] as String? ?? '',
      timestamp: parseDate(json['timestamp']),
      findings: json['findings'] as String? ?? '',
      manualCountVerified: (json['manualCountVerified'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'resolved',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zoneId': zoneId,
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'timestamp': timestamp.toIso8601String(),
      'findings': findings,
      'manualCountVerified': manualCountVerified,
      'status': status,
    };
  }
}
