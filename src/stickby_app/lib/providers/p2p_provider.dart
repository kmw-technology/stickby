import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/p2p_share.dart';
import '../services/crypto_service.dart';
import '../services/local_db_service.dart';
import '../services/storage_service.dart';

/// Provider for P2P Privacy Mode functionality.
/// Manages encrypted local storage, shares, and key distribution.
class P2PProvider with ChangeNotifier {
  final StorageService _storageService;
  final CryptoService _cryptoService;
  final LocalDbService _localDbService;
  final Uuid _uuid = const Uuid();

  bool _isInitialized = false;
  bool _isPrivacyModeEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Cached data
  List<P2PShare> _outgoingShares = [];
  List<ReceivedShare> _receivedShares = [];
  List<Contact> _localContacts = [];

  P2PProvider({
    required StorageService storageService,
    CryptoService? cryptoService,
    LocalDbService? localDbService,
  })  : _storageService = storageService,
        _cryptoService = cryptoService ?? CryptoService(),
        _localDbService = localDbService ?? LocalDbService();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPrivacyModeEnabled => _isPrivacyModeEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<P2PShare> get outgoingShares => List.unmodifiable(_outgoingShares);
  List<ReceivedShare> get receivedShares => List.unmodifiable(_receivedShares);
  List<Contact> get localContacts => List.unmodifiable(_localContacts);

  /// Initialize P2P provider.
  /// Call this on app startup if privacy mode might be enabled.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _isPrivacyModeEnabled = await _storageService.isPrivacyModeEnabled();

      if (_isPrivacyModeEnabled) {
        await _initializeDatabase();
        await _loadData();
      }

      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to initialize P2P mode: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enable P2P Privacy Mode.
  /// Generates master key, key pair, and initializes encrypted database.
  Future<bool> enablePrivacyMode() async {
    if (_isPrivacyModeEnabled) return true;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Generate Master Identity Key
      final mik = await _cryptoService.generateMasterIdentityKey();
      final mikHex = _bytesToHex(mik);
      await _storageService.saveMasterIdentityKey(mikHex);

      // Generate Ed25519 key pair
      final keyPair = await _cryptoService.generateKeyPair();
      await _storageService.saveP2PKeyPair(
        publicKeyHex: _bytesToHex(keyPair.publicKey),
        privateKeyHex: _bytesToHex(keyPair.privateKey),
      );

      // Mark as enabled
      await _storageService.setPrivacyModeEnabled(true);
      _isPrivacyModeEnabled = true;

      // Initialize encrypted database
      await _initializeDatabase();

      // Save settings to local DB
      final publicKeyHex = _bytesToHex(keyPair.publicKey);
      await _localDbService.saveP2PSettings(
        enabled: true,
        publicKey: publicKeyHex,
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to enable privacy mode: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize the encrypted database.
  Future<void> _initializeDatabase() async {
    final mikHex = await _storageService.getMasterIdentityKey();
    if (mikHex == null) {
      throw Exception('Master Identity Key not found');
    }

    // Derive database encryption key from MIK
    final mik = _hexToBytes(mikHex);
    final dbKey = await _cryptoService.deriveDatabaseKey(mik);
    final dbKeyHex = _bytesToHex(dbKey);

    await _localDbService.initialize(dbKeyHex);
  }

  /// Load data from local database.
  Future<void> _loadData() async {
    await Future.wait([
      _loadOutgoingShares(),
      _loadReceivedShares(),
      _loadLocalContacts(),
    ]);
  }

  Future<void> _loadOutgoingShares() async {
    final sharesData = await _localDbService.getOutgoingShares();
    _outgoingShares = [];

    for (final shareData in sharesData) {
      final contactIds = await _localDbService.getShareContactIds(shareData['id'] as String);
      final recipientsData = await _localDbService.getShareRecipients(shareData['id'] as String);
      final recipients = recipientsData.map((r) => P2PRecipient.fromDb(r)).toList();

      _outgoingShares.add(P2PShare.fromDb(
        shareData,
        contactIds: contactIds,
        recipients: recipients,
      ));
    }
  }

  Future<void> _loadReceivedShares() async {
    final sharesData = await _localDbService.getReceivedShares();
    _receivedShares = [];

    for (final shareData in sharesData) {
      final contactsData = await _localDbService.getReceivedContacts(shareData['id'] as String);
      final contacts = contactsData.map((c) => ReceivedContact.fromDb(c)).toList();

      _receivedShares.add(ReceivedShare.fromDb(
        shareData,
        contacts: contacts,
      ));
    }
  }

  Future<void> _loadLocalContacts() async {
    final contactsData = await _localDbService.getLocalContacts();
    _localContacts = await Future.wait(contactsData.map((c) async {
      // Decrypt contact value
      final encryptedValue = c['encrypted_value'] as String;
      final decryptedValue = await _decryptContactValue(encryptedValue);

      return Contact(
        id: c['id'] as String,
        type: ContactType.values[c['type'] as int],
        label: c['label'] as String,
        value: decryptedValue,
        sortOrder: c['sort_order'] as int? ?? 0,
        releaseGroups: c['release_groups'] as int? ?? ReleaseGroup.all,
      );
    }));
  }

  // ============================================
  // LOCAL CONTACTS MANAGEMENT
  // ============================================

  /// Add a new local contact.
  Future<Contact?> addLocalContact({
    required ContactType type,
    required String label,
    required String value,
    int sortOrder = 0,
    int releaseGroups = ReleaseGroup.all,
  }) async {
    try {
      final id = _uuid.v4();
      final encryptedValue = await _encryptContactValue(value);

      final contactData = {
        'id': id,
        'type': type.index,
        'label': label,
        'encrypted_value': encryptedValue,
        'sort_order': sortOrder,
        'release_groups': releaseGroups,
        'current_epoch': 1,
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 'local',
      };

      await _localDbService.upsertLocalContact(contactData);

      final contact = Contact(
        id: id,
        type: type,
        label: label,
        value: value,
        sortOrder: sortOrder,
        releaseGroups: releaseGroups,
      );

      _localContacts.add(contact);
      notifyListeners();
      return contact;
    } catch (e) {
      _errorMessage = 'Failed to add contact: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update a local contact.
  Future<bool> updateLocalContact(Contact contact) async {
    try {
      final encryptedValue = await _encryptContactValue(contact.value);

      final contactData = {
        'id': contact.id,
        'type': contact.type.index,
        'label': contact.label,
        'encrypted_value': encryptedValue,
        'sort_order': contact.sortOrder,
        'release_groups': contact.releaseGroups,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _localDbService.upsertLocalContact(contactData);

      // Increment epoch for shares containing this contact
      await _incrementEpochForContact(contact.id);

      final index = _localContacts.indexWhere((c) => c.id == contact.id);
      if (index >= 0) {
        _localContacts[index] = contact;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update contact: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a local contact.
  Future<bool> deleteLocalContact(String contactId) async {
    try {
      await _localDbService.deleteLocalContact(contactId);
      _localContacts.removeWhere((c) => c.id == contactId);

      // Increment epoch for shares containing this contact
      await _incrementEpochForContact(contactId);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete contact: $e';
      notifyListeners();
      return false;
    }
  }

  /// Increment epoch for shares containing a specific contact.
  Future<void> _incrementEpochForContact(String contactId) async {
    for (final share in _outgoingShares) {
      if (share.contactIds.contains(contactId)) {
        await _localDbService.incrementShareEpoch(share.id);
      }
    }
    await _loadOutgoingShares();
  }

  // ============================================
  // OUTGOING SHARES MANAGEMENT
  // ============================================

  /// Create a new P2P share.
  Future<P2PShare?> createShare({
    String? name,
    required List<String> contactIds,
    bool useServerRelay = false,
  }) async {
    if (contactIds.isEmpty) {
      _errorMessage = 'No contacts selected';
      notifyListeners();
      return null;
    }

    try {
      final id = _uuid.v4();
      final now = DateTime.now();

      final shareData = {
        'id': id,
        'name': name,
        'current_epoch': 1,
        'use_server_relay': useServerRelay ? 1 : 0,
        'created_at': now.toIso8601String(),
      };

      await _localDbService.createOutgoingShare(shareData);
      await _localDbService.addContactsToShare(id, contactIds);

      final share = P2PShare(
        id: id,
        name: name,
        currentEpoch: 1,
        useServerRelay: useServerRelay,
        contactIds: contactIds,
        recipients: [],
        createdAt: now,
      );

      _outgoingShares.insert(0, share);
      notifyListeners();
      return share;
    } catch (e) {
      _errorMessage = 'Failed to create share: $e';
      notifyListeners();
      return null;
    }
  }

  /// Generate QR code data for a share.
  Future<String?> generateQRData(P2PShare share) async {
    try {
      final publicKeyHex = await _storageService.getP2PPublicKey();
      final privateKeyHex = await _storageService.getP2PPrivateKey();
      final mikHex = await _storageService.getMasterIdentityKey();

      if (publicKeyHex == null || privateKeyHex == null || mikHex == null) {
        throw Exception('Keys not found');
      }

      final publicKey = _hexToBytes(publicKeyHex);
      final privateKey = _hexToBytes(privateKeyHex);
      final mik = _hexToBytes(mikHex);

      // Derive epoch key
      final epochKey = await _cryptoService.deriveEpochKey(mik, share.currentEpoch);

      // Get contacts for this share
      final contacts = _localContacts.where((c) => share.contactIds.contains(c.id)).toList();

      // Serialize and encrypt contacts bundle
      final contactsJson = jsonEncode(contacts.map((c) => {
        'id': c.id,
        'type': c.type.index,
        'label': c.label,
        'value': c.value,
        'sortOrder': c.sortOrder,
      }).toList());

      final encResult = await _cryptoService.encryptString(contactsJson, epochKey);

      // Compute bundle hash
      final bundleHash = await _cryptoService.sha256Hash(
        Uint8List.fromList(utf8.encode(contactsJson)),
      );

      // Create data to sign
      final dataToSign = Uint8List.fromList([
        ...utf8.encode(share.id),
        ...utf8.encode(share.currentEpoch.toString()),
        ...bundleHash,
      ]);

      // Sign with private key
      final signature = await _cryptoService.sign(dataToSign, privateKey);

      // Create QR data
      final qrData = QRShareData(
        ownerPublicKey: publicKeyHex,
        shareId: share.id,
        epochNumber: share.currentEpoch,
        encryptedShareKey: base64Encode(epochKey), // In real impl, encrypt for recipient
        serverRelayId: share.useServerRelay ? share.serverShareId : null,
        encryptedBundle: base64Encode(Uint8List.fromList([
          ...encResult.nonce,
          ...encResult.ciphertext,
        ])),
        signature: base64Encode(signature),
      );

      return qrData.encode();
    } catch (e) {
      _errorMessage = 'Failed to generate QR data: $e';
      notifyListeners();
      return null;
    }
  }

  /// Delete an outgoing share.
  Future<bool> deleteShare(String shareId) async {
    try {
      await _localDbService.deleteOutgoingShare(shareId);
      _outgoingShares.removeWhere((s) => s.id == shareId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete share: $e';
      notifyListeners();
      return false;
    }
  }

  /// Revoke a recipient's access.
  Future<bool> revokeRecipient(String shareId, String recipientId) async {
    try {
      // Revoke in database
      await _localDbService.revokeRecipient(recipientId);

      // Increment share epoch (so revoked recipient can't decrypt new data)
      await _localDbService.incrementShareEpoch(shareId);

      // Reload shares
      await _loadOutgoingShares();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to revoke recipient: $e';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // RECEIVING SHARES
  // ============================================

  /// Receive a share from QR code data.
  Future<ReceivedShare?> receiveShare(String qrData) async {
    try {
      // Decode QR data
      final shareData = QRShareData.decode(qrData);

      // Verify signature
      final publicKey = _hexToBytes(shareData.ownerPublicKey);
      final signature = base64Decode(shareData.signature);

      // Recreate data that was signed
      final bundleData = base64Decode(shareData.encryptedBundle!);
      final bundleHash = await _cryptoService.sha256Hash(bundleData);
      final dataToVerify = Uint8List.fromList([
        ...utf8.encode(shareData.shareId),
        ...utf8.encode(shareData.epochNumber.toString()),
        ...bundleHash,
      ]);

      final isValid = await _cryptoService.verify(dataToVerify, signature, publicKey);
      if (!isValid) {
        throw Exception('Invalid signature - share may be tampered');
      }

      // Decrypt the bundle
      final epochKey = base64Decode(shareData.encryptedShareKey);
      final nonce = bundleData.sublist(0, 12);
      final ciphertext = bundleData.sublist(12);

      final contactsJson = await _cryptoService.decryptString(
        ciphertext,
        nonce,
        Uint8List.fromList(epochKey),
      );

      // Parse contacts
      final contactsList = jsonDecode(contactsJson) as List;
      final contacts = contactsList.map((c) => ReceivedContact(
        id: c['id'] as String,
        shareId: shareData.shareId,
        type: c['type'] as int,
        label: c['label'] as String,
        value: c['value'] as String,
        sortOrder: c['sortOrder'] as int? ?? 0,
        epochReceived: shareData.epochNumber,
      )).toList();

      // Save to local database
      final receivedShare = ReceivedShare(
        id: shareData.shareId,
        ownerPublicKey: shareData.ownerPublicKey,
        serverRelayId: shareData.serverRelayId,
        currentEpoch: shareData.epochNumber,
        createdAt: DateTime.now(),
        contacts: contacts,
      );

      await _localDbService.saveReceivedShare(receivedShare.toDb());
      await _localDbService.saveReceivedContacts(
        shareData.shareId,
        contacts.map((c) => c.toDb()).toList(),
      );

      // Save epoch key for future use
      await _localDbService.saveEpochKey({
        'id': _uuid.v4(),
        'share_id': shareData.shareId,
        'epoch_number': shareData.epochNumber,
        'share_key': shareData.encryptedShareKey,
        'created_at': DateTime.now().toIso8601String(),
      });

      _receivedShares.insert(0, receivedShare);
      notifyListeners();
      return receivedShare;
    } catch (e) {
      _errorMessage = 'Failed to receive share: $e';
      notifyListeners();
      return null;
    }
  }

  /// Delete a received share.
  Future<bool> deleteReceivedShare(String shareId) async {
    try {
      await _localDbService.deleteReceivedShare(shareId);
      _receivedShares.removeWhere((s) => s.id == shareId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete received share: $e';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // ENCRYPTION HELPERS
  // ============================================

  /// Encrypt a contact value for local storage.
  Future<String> _encryptContactValue(String value) async {
    final mikHex = await _storageService.getMasterIdentityKey();
    if (mikHex == null) throw Exception('MIK not found');

    final mik = _hexToBytes(mikHex);
    final key = await _cryptoService.deriveDatabaseKey(mik);
    final result = await _cryptoService.encryptString(value, key);

    return base64Encode(Uint8List.fromList([
      ...result.nonce,
      ...result.ciphertext,
    ]));
  }

  /// Decrypt a contact value from local storage.
  Future<String> _decryptContactValue(String encryptedValue) async {
    final mikHex = await _storageService.getMasterIdentityKey();
    if (mikHex == null) throw Exception('MIK not found');

    final mik = _hexToBytes(mikHex);
    final key = await _cryptoService.deriveDatabaseKey(mik);

    final data = base64Decode(encryptedValue);
    final nonce = data.sublist(0, 12);
    final ciphertext = data.sublist(12);

    return await _cryptoService.decryptString(ciphertext, nonce, key);
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh all data.
  Future<void> refresh() async {
    if (!_isPrivacyModeEnabled) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _loadData();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to refresh: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
