import 'package:flutter/foundation.dart';
import '../models/share.dart';
import '../services/api_service.dart';

class SharesProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Share> _shares = [];
  bool _isLoading = false;
  String? _errorMessage;

  SharesProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<Share> get shares => _shares;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalViewCount => _shares.fold(0, (sum, share) => sum + share.viewCount);
  List<Share> get recentShares => _shares.take(5).toList();

  Future<void> loadShares() async {
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
