class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'admin' | 'field_auditor' | 'security_lead'
  final String? fcmToken;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.fcmToken,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? fcmToken,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json, String documentId) {
    return AppUser(
      id: documentId,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'field_auditor',
      fcmToken: json['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'fcmToken': fcmToken,
    };
  }
}
