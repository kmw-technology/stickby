import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  final ApiService _apiService;

  Profile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
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
    Map<String, int> contactReleaseGroups,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updates = contactReleaseGroups.entries
          .map((e) => {
                'contactId': e.key,
                'releaseGroups': e.value,
              })
          .toList();

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
