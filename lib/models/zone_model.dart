class ZoneModel {
  final String id;
  final String name;
  final String floor;
  final String cctvStreamUrl;
  final bool isCameraOnline;
  final int expectedCount;
  final int detectedCount;
  final int discrepancy;
  final String severity; // 'normal' | 'warning' | 'critical'
  final DateTime lastAuditTimestamp;
  final DateTime? uncheckedSince;
  final bool escalated;

  const ZoneModel({
    required this.id,
    required this.name,
    required this.floor,
    required this.cctvStreamUrl,
    required this.isCameraOnline,
    required this.expectedCount,
    required this.detectedCount,
    required this.discrepancy,
    required this.severity,
    required this.lastAuditTimestamp,
    this.uncheckedSince,
    required this.escalated,
  });

  ZoneModel copyWith({
    String? id,
    String? name,
    String? floor,
    String? cctvStreamUrl,
    bool? isCameraOnline,
    int? expectedCount,
    int? detectedCount,
    int? discrepancy,
    String? severity,
    DateTime? lastAuditTimestamp,
    DateTime? uncheckedSince,
    bool? escalated,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      cctvStreamUrl: cctvStreamUrl ?? this.cctvStreamUrl,
      isCameraOnline: isCameraOnline ?? this.isCameraOnline,
      expectedCount: expectedCount ?? this.expectedCount,
      detectedCount: detectedCount ?? this.detectedCount,
      discrepancy: discrepancy ?? this.discrepancy,
      severity: severity ?? this.severity,
      lastAuditTimestamp: lastAuditTimestamp ?? this.lastAuditTimestamp,
      uncheckedSince: uncheckedSince ?? this.uncheckedSince,
      escalated: escalated ?? this.escalated,
    );
  }

  factory ZoneModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final exp = (json['expectedCount'] as num?)?.toInt() ?? 0;
    final det = (json['detectedCount'] as num?)?.toInt() ?? 0;

    return ZoneModel(
      id: documentId,
      name: json['name'] as String? ?? 'Unnamed Zone',
      floor: json['floor'] as String? ?? 'Ground Floor',
      cctvStreamUrl: json['cctvStreamUrl'] as String? ?? '',
      isCameraOnline: json['isCameraOnline'] as bool? ?? false,
      expectedCount: exp,
      detectedCount: det,
      discrepancy: (json['discrepancy'] as num?)?.toInt() ?? (exp - det),
      severity: json['severity'] as String? ?? 'normal',
      lastAuditTimestamp: parseDate(json['lastAuditTimestamp']),
      uncheckedSince: json['uncheckedSince'] != null ? parseDate(json['uncheckedSince']) : null,
      escalated: json['escalated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'floor': floor,
      'cctvStreamUrl': cctvStreamUrl,
      'isCameraOnline': isCameraOnline,
      'expectedCount': expectedCount,
      'detectedCount': detectedCount,
      'discrepancy': discrepancy,
      'severity': severity,
      'lastAuditTimestamp': lastAuditTimestamp.toIso8601String(),
      'uncheckedSince': uncheckedSince?.toIso8601String(),
      'escalated': escalated,
    };
  }
}
