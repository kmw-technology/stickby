import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userDisplayNameKey = 'user_display_name';

  final FlutterSecureStorage _storage;

  StorageService() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Token management
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  // User info
  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userEmailKey, value: email),
      _storage.write(key: _userDisplayNameKey, value: displayName),
    ]);
  }

  Future<Map<String, String?>> getUserInfo() async {
    return {
      'userId': await _storage.read(key: _userIdKey),
      'email': await _storage.read(key: _userEmailKey),
      'displayName': await _storage.read(key: _userDisplayNameKey),
    };
  }

  Future<void> clearUserInfo() async {
    await Future.wait([
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userEmailKey),
      _storage.delete(key: _userDisplayNameKey),
    ]);
  }

  // Clear all
  Future<void> clearAll() async {
    await Future.wait([
      clearTokens(),
      clearUserInfo(),
    ]);
  }
}
