class InspectionModel {
  final String id;
  final String zoneId;
  final String zoneName;
  final String inspectorId;
  final String inspectorName;
  final DateTime timestamp;
  final String findings;
  final int manualCountVerified;
  final String status; // 'resolved' | 'escalated_to_police' | 'false_alarm' | 'surprise_inspection'
  
  // Statutory Government Inspection Dossier Fields
  final bool gpsVerified;
  final double gpsDistanceMeters;
  final String? geoOverrideReason;
  final int reportedBeneficiaries;
  final int aiDetectedCount;
  final int physicalHeadcount;
  final int aiDiscrepancy;
  final int physicalDiscrepancy;
  final int compliancePercent;
  final String verdict; // 'COMPLIANT' | 'NON_COMPLIANT' | 'SHOW_CAUSE' | 'FUNDS_FROZEN'
  final String auditHash; // SHA-256 seal

  const InspectionModel({
    required this.id,
    required this.zoneId,
    this.zoneName = 'Central Assembly Hall',
    required this.inspectorId,
    required this.inspectorName,
    required this.timestamp,
    required this.findings,
    required this.manualCountVerified,
    required this.status,
    this.gpsVerified = true,
    this.gpsDistanceMeters = 73.0,
    this.geoOverrideReason,
    this.reportedBeneficiaries = 92,
    this.aiDetectedCount = 57,
    this.physicalHeadcount = 60,
    this.aiDiscrepancy = 35,
    this.physicalDiscrepancy = 32,
    this.compliancePercent = 71,
    this.verdict = 'NON_COMPLIANT',
    this.auditHash = 'a4f91c98e02d847b2933f11e92da304a',
  });

  InspectionModel copyWith({
    String? id,
    String? zoneId,
    String? zoneName,
    String? inspectorId,
    String? inspectorName,
    DateTime? timestamp,
    String? findings,
    int? manualCountVerified,
    String? status,
    bool? gpsVerified,
    double? gpsDistanceMeters,
    String? geoOverrideReason,
    int? reportedBeneficiaries,
    int? aiDetectedCount,
    int? physicalHeadcount,
    int? aiDiscrepancy,
    int? physicalDiscrepancy,
    int? compliancePercent,
    String? verdict,
    String? auditHash,
  }) {
    return InspectionModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      timestamp: timestamp ?? this.timestamp,
      findings: findings ?? this.findings,
      manualCountVerified: manualCountVerified ?? this.manualCountVerified,
      status: status ?? this.status,
      gpsVerified: gpsVerified ?? this.gpsVerified,
      gpsDistanceMeters: gpsDistanceMeters ?? this.gpsDistanceMeters,
      geoOverrideReason: geoOverrideReason ?? this.geoOverrideReason,
      reportedBeneficiaries: reportedBeneficiaries ?? this.reportedBeneficiaries,
      aiDetectedCount: aiDetectedCount ?? this.aiDetectedCount,
      physicalHeadcount: physicalHeadcount ?? this.physicalHeadcount,
      aiDiscrepancy: aiDiscrepancy ?? this.aiDiscrepancy,
      physicalDiscrepancy: physicalDiscrepancy ?? this.physicalDiscrepancy,
      compliancePercent: compliancePercent ?? this.compliancePercent,
      verdict: verdict ?? this.verdict,
      auditHash: auditHash ?? this.auditHash,
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
