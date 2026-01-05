import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/company.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../models/profile.dart';
import '../models/share.dart';
import '../models/web_session.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final StorageService _storage;
  final http.Client _client;

  ApiService({StorageService? storage, http.Client? client})
      : _storage = storage ?? StorageService(),
        _client = client ?? http.Client();

  // Base request methods
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message = 'An error occurred';
    try {
      final body = jsonDecode(response.body);
      message = body['message'] ?? message;
    } catch (_) {}

    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<dynamic> _get(String endpoint, {bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> _post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<void> _delete(String endpoint, {bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: headers,
    );
    await _handleResponse(response);
  }

  // Auth methods
  Future<AuthResponse> login(String email, String password) async {
    final data = await _post(
      ApiConfig.login,
      {'email': email, 'password': password},
      requireAuth: false,
    );
    final authResponse = AuthResponse.fromJson(data);

    // Save tokens and user info
    await _storage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    await _storage.saveUserInfo(
      userId: authResponse.user.id,
      email: authResponse.user.email,
      displayName: authResponse.user.displayName,
    );

    return authResponse;
  }

  Future<AuthResponse> register(
    String email,
    String password,
    String displayName,
  ) async {
    final data = await _post(
      ApiConfig.register,
      {
        'email': email,
        'password': password,
        'displayName': displayName,
      },
      requireAuth: false,
    );
    final authResponse = AuthResponse.fromJson(data);

    await _storage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    await _storage.saveUserInfo(
      userId: authResponse.user.id,
      email: authResponse.user.email,
      displayName: authResponse.user.displayName,
    );

    return authResponse;
  }

  Future<AuthResponse?> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final data = await _post(
        ApiConfig.refresh,
        {'refreshToken': refreshToken},
        requireAuth: false,
      );
      final authResponse = AuthResponse.fromJson(data);

      await _storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      return authResponse;
    } catch (e) {
      await _storage.clearAll();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _post(ApiConfig.logout, {'refreshToken': refreshToken});
      }
    } finally {
      await _storage.clearAll();
    }
  }

  // Contacts methods
  Future<List<Contact>> getContacts() async {
    final data = await _get(ApiConfig.contacts);
    return (data as List).map((e) => Contact.fromJson(e)).toList();
  }

  Future<Contact> getContact(String id) async {
    final data = await _get('${ApiConfig.contacts}/$id');
    return Contact.fromJson(data);
  }

  Future<Contact> createContact({
    required int type,
    required String label,
    required String value,
    int sortOrder = 0,
    int releaseGroups = 15,
  }) async {
    final data = await _post(ApiConfig.contacts, {
      'type': type,
      'label': label,
      'value': value,
      'sortOrder': sortOrder,
      'releaseGroups': releaseGroups,
    });
    return Contact.fromJson(data);
  }

  Future<Contact> updateContact(String id, {
    required int type,
    required String label,
    required String value,
    int sortOrder = 0,
    int releaseGroups = 15,
  }) async {
    final data = await _put('${ApiConfig.contacts}/$id', {
      'type': type,
      'label': label,
      'value': value,
      'sortOrder': sortOrder,
      'releaseGroups': releaseGroups,
    });
    return Contact.fromJson(data);
  }

  Future<void> deleteContact(String id) async {
    await _delete('${ApiConfig.contacts}/$id');
  }

  // Shares methods
  Future<List<Share>> getShares() async {
    final data = await _get(ApiConfig.shares);
    return (data as List).map((e) => Share.fromJson(e)).toList();
  }

  Future<Share> createShare({
    required List<String> contactIds,
    String? name,
    DateTime? expiresAt,
  }) async {
    final body = <String, dynamic>{
      'contactIds': contactIds,
    };
    if (name != null) body['name'] = name;
    if (expiresAt != null) body['expiresAt'] = expiresAt.toIso8601String();

    final data = await _post(ApiConfig.shares, body);
    return Share.fromJson(data);
  }

  Future<void> deleteShare(String id) async {
    await _delete('${ApiConfig.shares}/$id');
  }

  Future<ShareView> viewShare(String token) async {
    final data = await _get(
      '${ApiConfig.shares}/view/$token',
      requireAuth: false,
    );
    return ShareView.fromJson(data);
  }

  // Groups methods
  Future<List<Group>> getGroups() async {
    final data = await _get(ApiConfig.groups);
    return (data as List).map((e) => Group.fromJson(e)).toList();
  }

  Future<List<Group>> getGroupInvitations() async {
    final data = await _get(ApiConfig.groupInvitations);
    return (data as List).map((e) => Group.fromJson(e)).toList();
  }

  Future<Group> getGroup(String id) async {
    final data = await _get('${ApiConfig.groups}/$id');
    return Group.fromJson(data);
  }

  Future<Group> createGroup({
    required String name,
    String? description,
  }) async {
    final data = await _post(ApiConfig.groups, {
      'name': name,
      if (description != null) 'description': description,
    });
    return Group.fromJson(data);
  }

  Future<void> joinGroup(String id) async {
    await _post('${ApiConfig.groups}/$id/join', {});
  }

  Future<void> declineGroup(String id) async {
    await _post('${ApiConfig.groups}/$id/decline', {});
  }

  Future<void> leaveGroup(String id) async {
    await _post('${ApiConfig.groups}/$id/leave', {});
  }

  Future<void> inviteToGroup(String groupId, String email) async {
    await _post('${ApiConfig.groups}/$groupId/invite', {'email': email});
  }

  // Profile methods
  Future<Profile> getProfile() async {
    final data = await _get(ApiConfig.profile);
    return Profile.fromJson(data);
  }

  Future<Profile> updateProfile({
    required String displayName,
    String? bio,
  }) async {
    final data = await _put(ApiConfig.profile, {
      'displayName': displayName,
      if (bio != null) 'bio': bio,
    });
    return Profile.fromJson(data);
  }

  Future<void> updateReleaseGroups(List<Map<String, dynamic>> updates) async {
    await _put('${ApiConfig.profile}/release-groups/bulk', {
      'updates': updates,
    });
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    final token = await _storage.getAccessToken();
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileImage}'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = _getMimeType(extension);

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        return data['imageUrl'] as String?;
      }
      return null;
    }

    String message = 'Failed to upload image';
    try {
      final body = jsonDecode(response.body);
      message = body['message'] ?? message;
    } catch (_) {}

    throw ApiException(message, statusCode: response.statusCode);
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Company methods
  Future<Company> getCompany(String id) async {
    final data = await _get('${ApiConfig.companies}/$id');
    return Company.fromJson(data);
  }

  Future<List<Company>> getCompanies() async {
    final data = await _get(ApiConfig.companies);
    return (data as List<dynamic>)
        .map((e) => Company.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      await _get(ApiConfig.health, requireAuth: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Web Session methods (QR pairing for StickBy Web)

  /// Authorize a web session by scanning its QR code.
  /// The pairing token is obtained from the QR code on the website.
  Future<void> authorizeWebSession(String pairingToken) async {
    await _post(ApiConfig.webSessionAuthorize, {
      'pairingToken': pairingToken,
    });
  }

  /// Get list of active web sessions for the current user.
  Future<List<WebSession>> getWebSessions() async {
    final data = await _get(ApiConfig.webSession);
    return (data as List).map((e) => WebSession.fromJson(e)).toList();
  }

  /// Invalidate a specific web session.
  Future<void> invalidateWebSession(String sessionId) async {
    await _delete('${ApiConfig.webSession}/$sessionId');
  }

  /// Invalidate all web sessions.
  Future<void> invalidateAllWebSessions() async {
    await _delete(ApiConfig.webSession);
  }
}
