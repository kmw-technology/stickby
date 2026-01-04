import 'user.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
