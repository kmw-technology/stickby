import 'package:flutter/foundation.dart';
import '../models/share.dart';
import '../services/api_service.dart';
import '../services/demo_service.dart';

class SharesProvider with ChangeNotifier {
  final ApiService _apiService;
  final DemoService _demoService = DemoService();

  List<Share> _shares = [];
  bool _isLoading = false;
  String? _errorMessage;

  SharesProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Returns shares - from demo service if in demo mode.
  List<Share> get shares => _demoService.isEnabled
      ? _demoService.demoShares
      : _shares;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalViewCount => shares.fold(0, (sum, share) => sum + share.viewCount);
  List<Share> get recentShares => shares.take(5).toList();

  Future<void> loadShares() async {
    // Skip API call in demo mode
    if (_demoService.isEnabled) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shares = await _apiService.getShares();
      _shares.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Share?> createShare({
    required List<String> contactIds,
    String? name,
    DateTime? expiresAt,
  }) async {
    // Demo mode - create demo share
    if (_demoService.isEnabled) {
      final share = _demoService.createDemoShare(
        name: name,
        contactIds: contactIds,
        releaseGroups: 15, // All groups in demo mode
        expiresAt: expiresAt,
      );
      notifyListeners();
      return share;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final share = await _apiService.createShare(
        contactIds: contactIds,
        name: name,
        expiresAt: expiresAt,
      );
      _shares.insert(0, share);
      _isLoading = false;
      notifyListeners();
      return share;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteShare(String id) async {
    // Demo mode - delete demo share
    if (_demoService.isEnabled) {
      _demoService.deleteDemoShare(id);
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteShare(id);
      _shares.removeWhere((s) => s.id == id);
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

  Future<ShareView?> viewShare(String token) async {
    try {
      return await _apiService.viewShare(token);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
