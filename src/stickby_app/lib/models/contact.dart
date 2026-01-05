enum ContactType {
  // General (0-99)
  email(0),
  phone(1),
  address(2),
  website(3),
  social(4),
  custom(99),

  // Personal Info (100-199)
  nationality(100),
  maritalStatus(101),
  placeOfBirth(102),
  education(103),
  birthday(104),

  // Private Contact (200-299)
  mobile(200),
  emergencyContact(201),

  // Business (300-399)
  company(300),
  position(301),
  businessEmail(302),
  businessPhone(303),

  // Social Networks (400-499)
  facebook(400),
  instagram(401),
  linkedin(402),
  twitter(403),
  tiktok(404),
  snapchat(405),
  xing(406),
  github(407),

  // Gaming (500-599)
  steam(500),
  discord(501);

  final int value;
  const ContactType(this.value);

  static ContactType fromValue(int value) {
    return ContactType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ContactType.custom,
    );
  }

  String get category {
    if (value < 100) return 'General';
    if (value < 200) return 'Personal';
    if (value < 300) return 'Private';
    if (value < 400) return 'Business';
    if (value < 500) return 'Social';
    if (value < 600) return 'Gaming';
    return 'Other';
  }

  String get displayName {
    switch (this) {
      case ContactType.email:
        return 'Email';
      case ContactType.phone:
        return 'Phone';
      case ContactType.address:
        return 'Address';
      case ContactType.website:
        return 'Website';
      case ContactType.social:
        return 'Social';
      case ContactType.custom:
        return 'Custom';
      case ContactType.nationality:
        return 'Nationality';
      case ContactType.maritalStatus:
        return 'Marital Status';
      case ContactType.placeOfBirth:
        return 'Place of Birth';
      case ContactType.education:
        return 'Education';
      case ContactType.birthday:
        return 'Birthday';
      case ContactType.mobile:
        return 'Mobile';
      case ContactType.emergencyContact:
        return 'Emergency Contact';
      case ContactType.company:
        return 'Company';
      case ContactType.position:
        return 'Position';
      case ContactType.businessEmail:
        return 'Business Email';
      case ContactType.businessPhone:
        return 'Business Phone';
      case ContactType.facebook:
        return 'Facebook';
      case ContactType.instagram:
        return 'Instagram';
      case ContactType.linkedin:
        return 'LinkedIn';
      case ContactType.twitter:
        return 'Twitter';
      case ContactType.tiktok:
        return 'TikTok';
      case ContactType.snapchat:
        return 'Snapchat';
      case ContactType.xing:
        return 'Xing';
      case ContactType.github:
        return 'GitHub';
      case ContactType.steam:
        return 'Steam';
      case ContactType.discord:
        return 'Discord';
    }
  }
}

class ReleaseGroup {
  static const int none = 0;
  static const int family = 1;
  static const int friends = 2;
  static const int business = 4;
  static const int leisure = 8;
  static const int all = 15;

  static List<String> getLabels(int value) {
    final labels = <String>[];
    if (value & family != 0) labels.add('Family');
    if (value & friends != 0) labels.add('Friends');
    if (value & business != 0) labels.add('Business');
    if (value & leisure != 0) labels.add('Leisure');
    return labels;
  }
}

class Contact {
  final String id;
  final ContactType type;
  final String label;
  final String value;
  final int sortOrder;
  final int releaseGroups;
  // Owner info (for contacts received from others)
  final String? ownerName;
  final String? ownerImageUrl;

  Contact({
    required this.id,
    required this.type,
    required this.label,
    required this.value,
    this.sortOrder = 0,
    this.releaseGroups = ReleaseGroup.all,
    this.ownerName,
    this.ownerImageUrl,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      type: ContactType.fromValue(json['type'] as int),
      label: json['label'] as String,
      value: json['value'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      releaseGroups: json['releaseGroups'] as int? ?? ReleaseGroup.all,
      ownerName: json['ownerName'] as String?,
      ownerImageUrl: json['ownerImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'label': label,
      'value': value,
      'sortOrder': sortOrder,
      'releaseGroups': releaseGroups,
      'ownerName': ownerName,
      'ownerImageUrl': ownerImageUrl,
    };
  }

  Contact copyWith({
    String? id,
    ContactType? type,
    String? label,
    String? value,
    int? sortOrder,
    int? releaseGroups,
    String? ownerName,
    String? ownerImageUrl,
  }) {
    return Contact(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      value: value ?? this.value,
      sortOrder: sortOrder ?? this.sortOrder,
      releaseGroups: releaseGroups ?? this.releaseGroups,
      ownerName: ownerName ?? this.ownerName,
      ownerImageUrl: ownerImageUrl ?? this.ownerImageUrl,
    );
  }
}
