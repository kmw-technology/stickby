import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../models/share.dart';
import '../models/profile.dart';
import '../services/demo_service.dart';

/// Provider for managing demo mode state.
/// Demo mode uses pre-populated sample data to showcase the app.
class DemoProvider with ChangeNotifier {
  final DemoService _demoService = DemoService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Check if demo mode is currently enabled.
  bool get isDemoMode => _demoService.isEnabled;

  /// Check if demo mode has been initialized.
  bool get isInitialized => _demoService.isInitialized;

  /// Initialize demo provider - check stored state.
  Future<void> initialize() async {
    await _demoService.initialize();
    notifyListeners();
  }

  /// Enable demo mode.
  Future<bool> enableDemoMode() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _demoService.enableDemoMode();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to enable demo mode: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Disable demo mode.
  Future<bool> disableDemoMode() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _demoService.disableDemoMode();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to disable demo mode: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Demo data getters
  Profile? get demoProfile => _demoService.demoProfile;
  List<Contact> get demoProfileContacts => _demoService.demoProfileContacts;
  List<Contact> get demoContacts => _demoService.demoContacts;
  List<Contact> get allDemoContacts => _demoService.allDemoContacts;
  List<Group> get demoGroups => _demoService.demoGroups;
  List<Group> get demoInvitations => _demoService.demoInvitations;
  List<Share> get demoShares => _demoService.demoShares;

  // Demo mode actions - simulate API operations

  /// Add a new contact in demo mode.
  Contact? addContact({
    required ContactType type,
    required String label,
    required String value,
    int releaseGroups = ReleaseGroup.all,
  }) {
    if (!isDemoMode) return null;
    final contact = _demoService.addDemoContact(
      type: type,
      label: label,
      value: value,
      releaseGroups: releaseGroups,
    );
    notifyListeners();
    return contact;
  }

  /// Delete a contact in demo mode.
  void deleteContact(String contactId) {
    if (!isDemoMode) return;
    _demoService.deleteDemoContact(contactId);
    notifyListeners();
  }

  /// Accept a group invitation in demo mode.
  void acceptInvitation(String groupId) {
    if (!isDemoMode) return;
    _demoService.acceptDemoInvitation(groupId);
    notifyListeners();
  }

  /// Decline a group invitation in demo mode.
  void declineInvitation(String groupId) {
    if (!isDemoMode) return;
    _demoService.declineDemoInvitation(groupId);
    notifyListeners();
  }

  /// Create a new share in demo mode.
  Share? createShare({
    String? name,
    required List<String> contactIds,
    required int releaseGroups,
    DateTime? expiresAt,
    int? maxViews,
  }) {
    if (!isDemoMode) return null;
    final share = _demoService.createDemoShare(
      name: name,
      contactIds: contactIds,
      releaseGroups: releaseGroups,
      expiresAt: expiresAt,
      maxViews: maxViews,
    );
    notifyListeners();
    return share;
  }

  /// Delete a share in demo mode.
  void deleteShare(String shareId) {
    if (!isDemoMode) return;
    _demoService.deleteDemoShare(shareId);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
