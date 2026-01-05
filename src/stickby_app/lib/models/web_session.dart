/// Represents an active web session (StickBy Web connection).
class WebSession {
  final String id;
  final String? deviceName;
  final String? userAgent;
  final String? ipAddress;
  final DateTime authorizedAt;
  final DateTime? lastActivityAt;
  final bool isActive;

  WebSession({
    required this.id,
    this.deviceName,
    this.userAgent,
    this.ipAddress,
    required this.authorizedAt,
    this.lastActivityAt,
    required this.isActive,
  });

  factory WebSession.fromJson(Map<String, dynamic> json) {
    return WebSession(
      id: json['id'] as String,
      deviceName: json['deviceName'] as String?,
      userAgent: json['userAgent'] as String?,
      ipAddress: json['ipAddress'] as String?,
      authorizedAt: DateTime.parse(json['authorizedAt'] as String),
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': deviceName,
      'userAgent': userAgent,
      'ipAddress': ipAddress,
      'authorizedAt': authorizedAt.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'isActive': isActive,
    };
  }
}
