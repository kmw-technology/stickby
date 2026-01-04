import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/api_service.dart';
import '../services/demo_service.dart';

class ProfileProvider with ChangeNotifier {
  final ApiService _apiService;
  final DemoService _demoService = DemoService();

  Profile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Returns profile - from demo service if in demo mode.
  Profile? get profile => _demoService.isEnabled
      ? _demoService.demoProfile
      : _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    // Skip API call in demo mode
    if (_demoService.isEnabled) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _apiService.getProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String displayName,
    String? bio,
  }) async {
    // Demo mode - simulate success (changes are in-memory only)
    if (_demoService.isEnabled) {
      // Demo mode doesn't persist changes
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _apiService.updateProfile(
        displayName: displayName,
        bio: bio,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReleaseGroups(
    List<Map<String, dynamic>> updates,
  ) async {
    // Demo mode - simulate success
    if (_demoService.isEnabled) {
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateReleaseGroups(updates);
      await loadProfile(); // Reload to get updated data
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfileImage(File imageFile) async {
    // Demo mode - simulate success (image upload not supported)
    if (_demoService.isEnabled) {
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.uploadProfileImage(imageFile);
      await loadProfile(); // Reload to get updated image URL
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
