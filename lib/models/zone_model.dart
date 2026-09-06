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
  final String callStatus; // 'idle' | 'ringing' | 'active' | 'ended'
  final String? callerName;
  final String? activeRoomUrl;
  final String? inchargePhone;
  final String? inchargeName;
  final List<int> pastThreeDaysDetected; // e.g. [63, 59, 61]
  final int persistentAnomalyDays; // e.g. 3
  final double cameraUptimePercent; // e.g. 96.7%
  final int totalDowntimeMinutes; // e.g. 19
  final String lastOutageWindow; // e.g. "Today 10:32 AM - 10:51 AM"
  final double targetLatitude; // e.g. 28.6692
  final double targetLongitude; // e.g. 77.4538
  final String noticePolicy; // '2_hours_surprise' | 'routine_scheduled' | 'immediate_verification'
  final DateTime? scheduledInspectionTime;

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
    this.callStatus = 'idle',
    this.callerName,
    this.activeRoomUrl,
    this.inchargePhone,
    this.inchargeName,
    this.pastThreeDaysDetected = const [63, 59, 61],
    this.persistentAnomalyDays = 3,
    this.cameraUptimePercent = 96.7,
    this.totalDowntimeMinutes = 19,
    this.lastOutageWindow = 'Today 10:32 AM – 10:51 AM',
    this.targetLatitude = 28.6692,
    this.targetLongitude = 77.4538,
    this.noticePolicy = '2_hours_surprise',
    this.scheduledInspectionTime,
  });

  bool get isPersistentAnomaly => persistentAnomalyDays >= 3;

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
    String? callStatus,
    String? callerName,
    String? activeRoomUrl,
    String? inchargePhone,
    String? inchargeName,
    List<int>? pastThreeDaysDetected,
    int? persistentAnomalyDays,
    double? cameraUptimePercent,
    int? totalDowntimeMinutes,
    String? lastOutageWindow,
    double? targetLatitude,
    double? targetLongitude,
    String? noticePolicy,
    DateTime? scheduledInspectionTime,
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
      callStatus: callStatus ?? this.callStatus,
      callerName: callerName ?? this.callerName,
      activeRoomUrl: activeRoomUrl ?? this.activeRoomUrl,
      inchargePhone: inchargePhone ?? this.inchargePhone,
      inchargeName: inchargeName ?? this.inchargeName,
      pastThreeDaysDetected: pastThreeDaysDetected ?? this.pastThreeDaysDetected,
      persistentAnomalyDays: persistentAnomalyDays ?? this.persistentAnomalyDays,
      cameraUptimePercent: cameraUptimePercent ?? this.cameraUptimePercent,
      totalDowntimeMinutes: totalDowntimeMinutes ?? this.totalDowntimeMinutes,
      lastOutageWindow: lastOutageWindow ?? this.lastOutageWindow,
      targetLatitude: targetLatitude ?? this.targetLatitude,
      targetLongitude: targetLongitude ?? this.targetLongitude,
      noticePolicy: noticePolicy ?? this.noticePolicy,
      scheduledInspectionTime: scheduledInspectionTime ?? this.scheduledInspectionTime,
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
      callStatus: json['callStatus'] as String? ?? 'idle',
      callerName: json['callerName'] as String?,
      activeRoomUrl: json['activeRoomUrl'] as String?,
      inchargePhone: json['inchargePhone'] as String?,
      inchargeName: json['inchargeName'] as String?,
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
      'callStatus': callStatus,
      'callerName': callerName,
      'activeRoomUrl': activeRoomUrl,
      'inchargePhone': inchargePhone,
      'inchargeName': inchargeName,
    };
  }
}
