class User {
  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final String? bio;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
    };
  }
}
