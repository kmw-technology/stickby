enum GroupMemberRole {
  owner(0),
  admin(1),
  member(2);

  final int value;
  const GroupMemberRole(this.value);

  static GroupMemberRole fromValue(int value) {
    return GroupMemberRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupMemberRole.member,
    );
  }

  String get displayName {
    switch (this) {
      case GroupMemberRole.owner:
        return 'Owner';
      case GroupMemberRole.admin:
        return 'Admin';
      case GroupMemberRole.member:
        return 'Member';
    }
  }
}

enum GroupMemberStatus {
  pending(0),
  active(1),
  declined(2),
  left(3);

  final int value;
  const GroupMemberStatus(this.value);

  static GroupMemberStatus fromValue(int value) {
    return GroupMemberStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupMemberStatus.pending,
    );
  }
}

class GroupMember {
  final String userId;
  final String displayName;
  final String email;
  final GroupMemberRole role;
  final GroupMemberStatus status;
  final DateTime? joinedAt;

  GroupMember({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      role: GroupMemberRole.fromValue(json['role'] as int),
      status: GroupMemberStatus.fromValue(json['status'] as int),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
    );
  }
}

class Group {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final int memberCount;
  final GroupMemberRole myRole;
  final GroupMemberStatus myStatus;
  final DateTime createdAt;
  final String? createdByUserId;
  final String? createdByUserName;
  final List<GroupMember>? members;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.memberCount = 0,
    required this.myRole,
    required this.myStatus,
    required this.createdAt,
    this.createdByUserId,
    this.createdByUserName,
    this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      memberCount: json['memberCount'] as int? ?? 0,
      myRole: GroupMemberRole.fromValue(json['myRole'] as int? ?? 2),
      myStatus: GroupMemberStatus.fromValue(json['myStatus'] as int? ?? 0),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdByUserId: json['createdByUserId'] as String?,
      createdByUserName: json['createdByUserName'] as String?,
      members: json['members'] != null
          ? (json['members'] as List<dynamic>)
              .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  bool get isPending => myStatus == GroupMemberStatus.pending;
  bool get isActive => myStatus == GroupMemberStatus.active;
  bool get isOwner => myRole == GroupMemberRole.owner;
}
