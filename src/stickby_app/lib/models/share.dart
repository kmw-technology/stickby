class Share {
  final String id;
  final String token;
  final String? name;
  final DateTime? expiresAt;
  final int viewCount;
  final DateTime createdAt;
  final List<String> contactIds;

  Share({
    required this.id,
    required this.token,
    this.name,
    this.expiresAt,
    this.viewCount = 0,
    required this.createdAt,
    required this.contactIds,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      id: json['id'] as String,
      token: json['token'] as String,
      name: json['name'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      viewCount: json['viewCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      contactIds: (json['contactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  String get shareUrl =>
      'https://www.kmw-technology.de/stickby/backend/api/shares/view/$token';

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class ShareView {
  final String ownerDisplayName;
  final List<dynamic> contacts;

  ShareView({
    required this.ownerDisplayName,
    required this.contacts,
  });

  factory ShareView.fromJson(Map<String, dynamic> json) {
    return ShareView(
      ownerDisplayName: json['ownerDisplayName'] as String,
      contacts: json['contacts'] as List<dynamic>,
    );
  }
}
