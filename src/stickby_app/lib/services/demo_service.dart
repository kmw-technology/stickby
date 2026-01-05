import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/contact.dart';
import '../models/group.dart';
import '../models/share.dart';
import '../models/profile.dart';
import '../widgets/demo_identity_picker.dart';
import 'storage_service.dart';

/// Service for managing Demo Mode.
/// Demo mode uses pre-populated sample data to showcase the app.
class DemoService {
  static final DemoService _instance = DemoService._internal();
  factory DemoService() => _instance;
  DemoService._internal();

  final StorageService _storage = StorageService();

  // Cached demo data
  Profile? _demoProfile;
  List<Contact>? _demoContacts;
  List<Group>? _demoGroups;
  List<Group>? _demoInvitations;
  List<Share>? _demoShares;

  bool _isEnabled = false;
  bool _isInitialized = false;
  DemoIdentity? _currentIdentity;

  /// Check if demo mode is currently enabled.
  bool get isEnabled => _isEnabled;

  /// Check if demo mode has been initialized.
  bool get isInitialized => _isInitialized;

  /// Get current demo identity.
  DemoIdentity? get currentIdentity => _currentIdentity;

  /// Initialize demo service - check stored state.
  Future<void> initialize() async {
    _isEnabled = await _storage.isDemoModeEnabled();
    _isInitialized = await _storage.isDemoModeInitialized();

    if (_isEnabled && _isInitialized) {
      await _loadDemoData();
    }
  }

  /// Enable demo mode with a selected identity and load demo data.
  Future<void> enableDemoMode({DemoIdentity? identity}) async {
    _currentIdentity = identity ?? DemoIdentity.all.first;
    await _storage.setDemoModeEnabled(true);
    await _loadDemoData();
    await _storage.setDemoModeInitialized(true);
    _isEnabled = true;
    _isInitialized = true;
  }

  /// Disable demo mode and clear demo data.
  Future<void> disableDemoMode() async {
    await _storage.setDemoModeEnabled(false);
    await _storage.setDemoModeInitialized(false);
    _clearCachedData();
    _isEnabled = false;
    _isInitialized = false;
  }

  /// Get demo profile.
  Profile? get demoProfile => _demoProfile;

  /// Get demo contacts (user's own contacts from profile).
  List<Contact> get demoProfileContacts {
    if (_demoProfile == null) return [];
    return _demoProfile!.allContacts;
  }

  /// Get demo received contacts (from other people).
  List<Contact> get demoContacts => _demoContacts ?? [];

  /// Get all demo contacts combined.
  List<Contact> get allDemoContacts {
    return [...demoProfileContacts, ...demoContacts];
  }

  /// Get demo groups.
  List<Group> get demoGroups => _demoGroups ?? [];

  /// Get demo invitations.
  List<Group> get demoInvitations => _demoInvitations ?? [];

  /// Get demo shares.
  List<Share> get demoShares => _demoShares ?? [];

  /// Load demo data based on selected identity.
  Future<void> _loadDemoData() async {
    try {
      if (_currentIdentity == null) {
        _currentIdentity = DemoIdentity.all.first;
      }

      // Create profile from selected identity
      _demoProfile = Profile(
        id: _currentIdentity!.id,
        email: _currentIdentity!.email,
        displayName: _currentIdentity!.name,
        profileImageUrl: _currentIdentity!.avatarPath,
        contactsByCategory: _generateProfileContactsByCategory(),
      );

      // Generate contacts - other demo identities become your contacts
      _demoContacts = _generateDemoContacts();

      // Generate demo groups
      _demoGroups = [
        Group(
          id: 'demo-group-1',
          name: 'Family',
          description: 'Close family members',
          memberCount: 4,
          myRole: GroupMemberRole.owner,
          myStatus: GroupMemberStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Group(
          id: 'demo-group-2',
          name: 'Work Team',
          description: 'Colleagues from the office',
          memberCount: 8,
          myRole: GroupMemberRole.member,
          myStatus: GroupMemberStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        ),
      ];

      // Generate demo invitations
      _demoInvitations = [
        Group(
          id: 'demo-invite-1',
          name: 'Sports Club',
          description: 'Weekend hiking group',
          memberCount: 12,
          myRole: GroupMemberRole.member,
          myStatus: GroupMemberStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      // Generate demo shares
      _demoShares = [
        Share(
          id: 'demo-share-1',
          name: 'Business Card',
          token: 'demo-biz-card',
          contactIds: ['prof-email', 'prof-phone'],
          expiresAt: null,
          viewCount: 23,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
    } catch (e) {
      print('DemoService: Error loading demo data: $e');
    }
  }

  /// Generate profile contacts by category for the current identity.
  Map<String, List<Contact>> _generateProfileContactsByCategory() {
    return {
      'General': [
        Contact(
          id: 'prof-email',
          type: ContactType.email,
          label: 'Personal',
          value: _currentIdentity!.email,
          releaseGroups: ReleaseGroup.all,
        ),
      ],
      'Private': [
        Contact(
          id: 'prof-phone',
          type: ContactType.mobile,
          label: 'Mobile',
          value: '+49 151 ${_currentIdentity!.name.hashCode.abs() % 10000000}',
          releaseGroups: ReleaseGroup.family | ReleaseGroup.friends,
        ),
      ],
      'Social': [
        Contact(
          id: 'prof-linkedin',
          type: ContactType.linkedin,
          label: 'LinkedIn',
          value: 'linkedin.com/in/${_currentIdentity!.id}',
          releaseGroups: ReleaseGroup.business,
        ),
      ],
    };
  }

  /// Generate demo contacts from other identities.
  List<Contact> _generateDemoContacts() {
    final contacts = <Contact>[];

    // Each other identity becomes a contact
    for (final identity in DemoIdentity.all) {
      if (identity.id == _currentIdentity!.id) continue;

      contacts.add(Contact(
        id: 'contact-${identity.id}-email',
        type: ContactType.email,
        label: identity.name,
        value: identity.email,
        releaseGroups: ReleaseGroup.all,
        ownerImageUrl: identity.avatarPath,
      ));

      contacts.add(Contact(
        id: 'contact-${identity.id}-phone',
        type: ContactType.mobile,
        label: identity.name,
        value: '+49 151 ${identity.name.hashCode.abs() % 10000000}',
        releaseGroups: ReleaseGroup.friends,
        ownerName: identity.name,
        ownerImageUrl: identity.avatarPath,
      ));
    }

    return contacts;
  }

  /// Clear cached demo data.
  void _clearCachedData() {
    _demoProfile = null;
    _demoContacts = null;
    _demoGroups = null;
    _demoInvitations = null;
    _demoShares = null;
    _currentIdentity = null;
  }

  /// Create Group from demo JSON format.
  Group _groupFromDemoJson(Map<String, dynamic> json, {bool isActive = true}) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberCount: json['memberCount'] as int? ?? 0,
      myRole: _parseGroupRole(json['role'] as String?),
      myStatus: isActive ? GroupMemberStatus.active : GroupMemberStatus.pending,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Create Share from demo JSON format.
  Share _shareFromDemoJson(Map<String, dynamic> json) {
    return Share(
      id: json['id'] as String,
      name: json['name'] as String?,
      token: json['token'] as String,
      contactIds: (json['contactIds'] as List<dynamic>).cast<String>(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      viewCount: json['viewCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  GroupMemberRole _parseGroupRole(String? role) {
    switch (role) {
      case 'owner':
        return GroupMemberRole.owner;
      case 'admin':
        return GroupMemberRole.admin;
      default:
        return GroupMemberRole.member;
    }
  }

  // Demo mode actions - simulate API responses

  /// Simulate adding a contact in demo mode.
  Contact addDemoContact({
    required ContactType type,
    required String label,
    required String value,
    int releaseGroups = ReleaseGroup.all,
  }) {
    final contact = Contact(
      id: 'demo-new-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      label: label,
      value: value,
      releaseGroups: releaseGroups,
    );
    _demoContacts ??= [];
    _demoContacts!.add(contact);
    return contact;
  }

  /// Simulate deleting a contact in demo mode.
  void deleteDemoContact(String contactId) {
    _demoContacts?.removeWhere((c) => c.id == contactId);
  }

  /// Simulate accepting a group invitation.
  void acceptDemoInvitation(String groupId) {
    final invitation = _demoInvitations?.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Invitation not found'),
    );
    if (invitation != null) {
      _demoInvitations?.removeWhere((g) => g.id == groupId);
      _demoGroups ??= [];
      _demoGroups!.add(Group(
        id: invitation.id,
        name: invitation.name,
        description: invitation.description,
        memberCount: invitation.memberCount,
        myRole: GroupMemberRole.member,
        myStatus: GroupMemberStatus.active,
        createdAt: invitation.createdAt,
      ));
    }
  }

  /// Simulate declining a group invitation.
  void declineDemoInvitation(String groupId) {
    _demoInvitations?.removeWhere((g) => g.id == groupId);
  }

  /// Simulate creating a share.
  Share createDemoShare({
    String? name,
    required List<String> contactIds,
    required int releaseGroups,
    DateTime? expiresAt,
    int? maxViews,
  }) {
    final share = Share(
      id: 'demo-share-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      token: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      contactIds: contactIds,
      expiresAt: expiresAt,
      viewCount: 0,
      createdAt: DateTime.now(),
    );
    _demoShares ??= [];
    _demoShares!.add(share);
    return share;
  }

  /// Simulate deleting a share.
  void deleteDemoShare(String shareId) {
    _demoShares?.removeWhere((s) => s.id == shareId);
  }
}
