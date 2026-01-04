import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../services/api_service.dart';

class ContactsProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Contact> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  ContactsProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, List<Contact>> get contactsByCategory {
    final map = <String, List<Contact>>{};
    for (final contact in _contacts) {
      final category = contact.type.category;
      map.putIfAbsent(category, () => []).add(contact);
    }
    return map;
  }

  Future<void> loadContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contacts = await _apiService.getContacts();
      _contacts.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createContact({
    required ContactType type,
    required String label,
    required String value,
    int releaseGroups = 15,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final contact = await _apiService.createContact(
        type: type.value,
        label: label,
        value: value,
        sortOrder: _contacts.length,
        releaseGroups: releaseGroups,
      );
      _contacts.add(contact);
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

  Future<bool> updateContact(
    String id, {
    required ContactType type,
    required String label,
    required String value,
    int? sortOrder,
    int? releaseGroups,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existingContact = _contacts.firstWhere((c) => c.id == id);
      final updatedContact = await _apiService.updateContact(
        id,
        type: type.value,
        label: label,
        value: value,
        sortOrder: sortOrder ?? existingContact.sortOrder,
        releaseGroups: releaseGroups ?? existingContact.releaseGroups,
      );

      final index = _contacts.indexWhere((c) => c.id == id);
      if (index != -1) {
        _contacts[index] = updatedContact;
      }

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

  Future<bool> deleteContact(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteContact(id);
      _contacts.removeWhere((c) => c.id == id);
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
