import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userDisplayNameKey = 'user_display_name';
  static const _onboardingCompletedKey = 'onboarding_completed';

  // P2P Privacy Mode keys
  static const _masterIdentityKeyKey = 'master_identity_key';
  static const _p2pPublicKeyKey = 'p2p_public_key';
  static const _p2pPrivateKeyKey = 'p2p_private_key';
  static const _privacyModeEnabledKey = 'privacy_mode_enabled';

  // Usage tracking keys
  static const _usageStatsKey = 'usage_stats';
  static const _navigationHistoryKey = 'navigation_history';

  // Demo mode keys
  static const _demoModeEnabledKey = 'demo_mode_enabled';
  static const _demoModeInitializedKey = 'demo_mode_initialized';

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

  // Onboarding
  Future<void> setOnboardingCompleted(bool completed) async {
    await _storage.write(key: _onboardingCompletedKey, value: completed.toString());
  }

  Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(key: _onboardingCompletedKey);
    return value == 'true';
  }

  Future<void> clearOnboarding() async {
    await _storage.delete(key: _onboardingCompletedKey);
  }

  // P2P Privacy Mode - Master Identity Key
  Future<void> saveMasterIdentityKey(String keyHex) async {
    await _storage.write(key: _masterIdentityKeyKey, value: keyHex);
  }

  Future<String?> getMasterIdentityKey() async {
    return _storage.read(key: _masterIdentityKeyKey);
  }

  Future<bool> hasMasterIdentityKey() async {
    final key = await getMasterIdentityKey();
    return key != null && key.isNotEmpty;
  }

  // P2P Privacy Mode - Key Pair (Ed25519)
  Future<void> saveP2PKeyPair({
    required String publicKeyHex,
    required String privateKeyHex,
  }) async {
    await Future.wait([
      _storage.write(key: _p2pPublicKeyKey, value: publicKeyHex),
      _storage.write(key: _p2pPrivateKeyKey, value: privateKeyHex),
    ]);
  }

  Future<String?> getP2PPublicKey() async {
    return _storage.read(key: _p2pPublicKeyKey);
  }

  Future<String?> getP2PPrivateKey() async {
    return _storage.read(key: _p2pPrivateKeyKey);
  }

  Future<Map<String, String?>> getP2PKeyPair() async {
    return {
      'publicKey': await getP2PPublicKey(),
      'privateKey': await getP2PPrivateKey(),
    };
  }

  // P2P Privacy Mode - Enabled flag
  Future<void> setPrivacyModeEnabled(bool enabled) async {
    await _storage.write(key: _privacyModeEnabledKey, value: enabled.toString());
  }

  Future<bool> isPrivacyModeEnabled() async {
    final value = await _storage.read(key: _privacyModeEnabledKey);
    return value == 'true';
  }

  // Clear P2P keys (use with caution - will lose all encrypted data!)
  Future<void> clearP2PKeys() async {
    await Future.wait([
      _storage.delete(key: _masterIdentityKeyKey),
      _storage.delete(key: _p2pPublicKeyKey),
      _storage.delete(key: _p2pPrivateKeyKey),
      _storage.delete(key: _privacyModeEnabledKey),
    ]);
  }

  // Clear all
  Future<void> clearAll() async {
    await Future.wait([
      clearTokens(),
      clearUserInfo(),
      clearOnboarding(),
      // Note: P2P keys are NOT cleared by default for safety
      // Call clearP2PKeys() explicitly if needed
    ]);
  }

  // Usage tracking - Stats
  Future<void> setUsageStats(String statsJson) async {
    await _storage.write(key: _usageStatsKey, value: statsJson);
  }

  Future<String?> getUsageStats() async {
    return _storage.read(key: _usageStatsKey);
  }

  // Usage tracking - Navigation history
  Future<void> setNavigationHistory(String historyJson) async {
    await _storage.write(key: _navigationHistoryKey, value: historyJson);
  }

  Future<String?> getNavigationHistory() async {
    return _storage.read(key: _navigationHistoryKey);
  }

  // Clear usage data
  Future<void> clearUsageData() async {
    await Future.wait([
      _storage.delete(key: _usageStatsKey),
      _storage.delete(key: _navigationHistoryKey),
    ]);
  }

  // Demo Mode - Enabled flag
  Future<void> setDemoModeEnabled(bool enabled) async {
    await _storage.write(key: _demoModeEnabledKey, value: enabled.toString());
  }

  Future<bool> isDemoModeEnabled() async {
    final value = await _storage.read(key: _demoModeEnabledKey);
    return value == 'true';
  }

  // Demo Mode - Initialized flag (demo data has been loaded)
  Future<void> setDemoModeInitialized(bool initialized) async {
    await _storage.write(key: _demoModeInitializedKey, value: initialized.toString());
  }

  Future<bool> isDemoModeInitialized() async {
    final value = await _storage.read(key: _demoModeInitializedKey);
    return value == 'true';
  }

  // Clear demo mode data
  Future<void> clearDemoMode() async {
    await Future.wait([
      _storage.delete(key: _demoModeEnabledKey),
      _storage.delete(key: _demoModeInitializedKey),
    ]);
  }
}
