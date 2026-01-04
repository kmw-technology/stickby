import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../services/api_service.dart';

class GroupsProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Group> _groups = [];
  List<Group> _invitations = [];
  bool _isLoading = false;
  String? _errorMessage;

  GroupsProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<Group> get groups => _groups.where((g) => g.isActive).toList();
  List<Group> get invitations => _invitations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendingInvitationsCount => _invitations.length;

  Future<void> loadGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await _apiService.getGroups();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInvitations() async {
    try {
      _invitations = await _apiService.getGroupInvitations();
      notifyListeners();
    } catch (e) {
      // Silently fail for invitations
    }
  }

  Future<Group?> getGroupDetails(String id) async {
    try {
      return await _apiService.getGroup(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> createGroup({
    required String name,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final group = await _apiService.createGroup(
        name: name,
        description: description,
      );
      _groups.add(group);
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

  Future<bool> joinGroup(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.joinGroup(id);
      // Move from invitations to groups
      final index = _invitations.indexWhere((g) => g.id == id);
      if (index != -1) {
        _invitations.removeAt(index);
      }
      await loadGroups(); // Reload groups to get the updated status
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

  Future<bool> declineGroup(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.declineGroup(id);
      _invitations.removeWhere((g) => g.id == id);
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

  Future<bool> leaveGroup(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.leaveGroup(id);
      _groups.removeWhere((g) => g.id == id);
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

  Future<bool> inviteUser(String groupId, String email) async {
    try {
      await _apiService.inviteToGroup(groupId, email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
