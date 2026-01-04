import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Local database service using SQLCipher for encrypted storage.
/// Used in P2P Privacy Mode to store contacts and shares locally.
class LocalDbService {
  static Database? _database;
  static String? _encryptionKey;

  // Singleton pattern
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  /// Initialize the database with an encryption key.
  /// The key should be derived from the Master Identity Key.
  Future<void> initialize(String encryptionKeyHex) async {
    if (_database != null) return;

    _encryptionKey = encryptionKeyHex;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'stickby_p2p.db');

    _database = await openDatabase(
      path,
      version: 1,
      password: encryptionKeyHex,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Check if database is initialized.
  bool get isInitialized => _database != null;

  /// Close the database.
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _encryptionKey = null;
  }

  /// Create database tables.
  Future<void> _onCreate(Database db, int version) async {
    // Local contacts (owned by this user)
    await db.execute('''
      CREATE TABLE local_contacts (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        label TEXT NOT NULL,
        encrypted_value TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        release_groups INTEGER NOT NULL DEFAULT 15,
        current_epoch INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'local'
      )
    ''');

    // Outgoing shares (shares this user created)
    await db.execute('''
      CREATE TABLE outgoing_shares (
        id TEXT PRIMARY KEY,
        server_share_id TEXT,
        name TEXT,
        current_epoch INTEGER NOT NULL DEFAULT 1,
        use_server_relay INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Contacts included in each share
    await db.execute('''
      CREATE TABLE share_contacts (
        share_id TEXT NOT NULL,
        contact_id TEXT NOT NULL,
        PRIMARY KEY (share_id, contact_id),
        FOREIGN KEY (share_id) REFERENCES outgoing_shares(id) ON DELETE CASCADE,
        FOREIGN KEY (contact_id) REFERENCES local_contacts(id) ON DELETE CASCADE
      )
    ''');

    // Recipients of outgoing shares
    await db.execute('''
      CREATE TABLE share_recipients (
        id TEXT PRIMARY KEY,
        share_id TEXT NOT NULL,
        recipient_public_key TEXT NOT NULL,
        recipient_label TEXT,
        last_delivered_epoch INTEGER NOT NULL DEFAULT 0,
        is_revoked INTEGER NOT NULL DEFAULT 0,
        revoked_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (share_id) REFERENCES outgoing_shares(id) ON DELETE CASCADE
      )
    ''');

    // Received shares (shares from other users)
    await db.execute('''
      CREATE TABLE received_shares (
        id TEXT PRIMARY KEY,
        owner_public_key TEXT NOT NULL,
        owner_display_name TEXT,
        share_name TEXT,
        server_relay_id TEXT,
        current_epoch INTEGER NOT NULL,
        last_synced_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Contacts received from shares
    await db.execute('''
      CREATE TABLE received_contacts (
        id TEXT PRIMARY KEY,
        share_id TEXT NOT NULL,
        type INTEGER NOT NULL,
        label TEXT NOT NULL,
        value TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        epoch_received INTEGER NOT NULL,
        FOREIGN KEY (share_id) REFERENCES received_shares(id) ON DELETE CASCADE
      )
    ''');

    // Epoch keys for received shares
    await db.execute('''
      CREATE TABLE epoch_keys (
        id TEXT PRIMARY KEY,
        share_id TEXT NOT NULL,
        epoch_number INTEGER NOT NULL,
        share_key TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(share_id, epoch_number),
        FOREIGN KEY (share_id) REFERENCES received_shares(id) ON DELETE CASCADE
      )
    ''');

    // Privacy mode settings
    await db.execute('''
      CREATE TABLE p2p_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        privacy_mode_enabled INTEGER NOT NULL DEFAULT 0,
        public_key TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Create indexes for common queries
    await db.execute('CREATE INDEX idx_local_contacts_type ON local_contacts(type)');
    await db.execute('CREATE INDEX idx_share_recipients_share ON share_recipients(share_id)');
    await db.execute('CREATE INDEX idx_received_contacts_share ON received_contacts(share_id)');
    await db.execute('CREATE INDEX idx_epoch_keys_share ON epoch_keys(share_id)');
  }

  /// Handle database upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // ============================================
  // LOCAL CONTACTS OPERATIONS
  // ============================================

  /// Insert or update a local contact.
  Future<void> upsertLocalContact(Map<String, dynamic> contact) async {
    await _database!.insert(
      'local_contacts',
      contact,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all local contacts.
  Future<List<Map<String, dynamic>>> getLocalContacts() async {
    return await _database!.query(
      'local_contacts',
      orderBy: 'sort_order ASC, created_at ASC',
    );
  }

  /// Get a single local contact by ID.
  Future<Map<String, dynamic>?> getLocalContact(String id) async {
    final results = await _database!.query(
      'local_contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Delete a local contact.
  Future<void> deleteLocalContact(String id) async {
    await _database!.delete('local_contacts', where: 'id = ?', whereArgs: [id]);
  }

  /// Increment epoch for specific contacts.
  Future<void> incrementContactsEpoch(List<String> contactIds) async {
    final placeholders = contactIds.map((_) => '?').join(',');
    await _database!.rawUpdate(
      'UPDATE local_contacts SET current_epoch = current_epoch + 1, updated_at = ? WHERE id IN ($placeholders)',
      [DateTime.now().toIso8601String(), ...contactIds],
    );
  }

  // ============================================
  // OUTGOING SHARES OPERATIONS
  // ============================================

  /// Create a new outgoing share.
  Future<void> createOutgoingShare(Map<String, dynamic> share) async {
    await _database!.insert('outgoing_shares', share);
  }

  /// Get all outgoing shares.
  Future<List<Map<String, dynamic>>> getOutgoingShares() async {
    return await _database!.query('outgoing_shares', orderBy: 'created_at DESC');
  }

  /// Get a single outgoing share by ID.
  Future<Map<String, dynamic>?> getOutgoingShare(String id) async {
    final results = await _database!.query(
      'outgoing_shares',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Update outgoing share.
  Future<void> updateOutgoingShare(String id, Map<String, dynamic> updates) async {
    await _database!.update(
      'outgoing_shares',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete an outgoing share.
  Future<void> deleteOutgoingShare(String id) async {
    await _database!.delete('outgoing_shares', where: 'id = ?', whereArgs: [id]);
  }

  /// Increment epoch for a share.
  Future<void> incrementShareEpoch(String shareId) async {
    await _database!.rawUpdate(
      'UPDATE outgoing_shares SET current_epoch = current_epoch + 1, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), shareId],
    );
  }

  // ============================================
  // SHARE CONTACTS OPERATIONS
  // ============================================

  /// Link contacts to a share.
  Future<void> addContactsToShare(String shareId, List<String> contactIds) async {
    final batch = _database!.batch();
    for (final contactId in contactIds) {
      batch.insert('share_contacts', {
        'share_id': shareId,
        'contact_id': contactId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  /// Get contact IDs for a share.
  Future<List<String>> getShareContactIds(String shareId) async {
    final results = await _database!.query(
      'share_contacts',
      columns: ['contact_id'],
      where: 'share_id = ?',
      whereArgs: [shareId],
    );
    return results.map((r) => r['contact_id'] as String).toList();
  }

  /// Get full contacts for a share.
  Future<List<Map<String, dynamic>>> getShareContacts(String shareId) async {
    return await _database!.rawQuery('''
      SELECT c.* FROM local_contacts c
      INNER JOIN share_contacts sc ON c.id = sc.contact_id
      WHERE sc.share_id = ?
      ORDER BY c.sort_order ASC
    ''', [shareId]);
  }

  // ============================================
  // SHARE RECIPIENTS OPERATIONS
  // ============================================

  /// Add a recipient to a share.
  Future<void> addShareRecipient(Map<String, dynamic> recipient) async {
    await _database!.insert('share_recipients', recipient);
  }

  /// Get recipients for a share.
  Future<List<Map<String, dynamic>>> getShareRecipients(String shareId) async {
    return await _database!.query(
      'share_recipients',
      where: 'share_id = ?',
      whereArgs: [shareId],
      orderBy: 'created_at ASC',
    );
  }

  /// Get active (non-revoked) recipients for a share.
  Future<List<Map<String, dynamic>>> getActiveShareRecipients(String shareId) async {
    return await _database!.query(
      'share_recipients',
      where: 'share_id = ? AND is_revoked = 0',
      whereArgs: [shareId],
    );
  }

  /// Revoke a recipient.
  Future<void> revokeRecipient(String recipientId) async {
    await _database!.update(
      'share_recipients',
      {
        'is_revoked': 1,
        'revoked_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [recipientId],
    );
  }

  /// Update recipient's last delivered epoch.
  Future<void> updateRecipientEpoch(String recipientId, int epoch) async {
    await _database!.update(
      'share_recipients',
      {'last_delivered_epoch': epoch},
      where: 'id = ?',
      whereArgs: [recipientId],
    );
  }

  // ============================================
  // RECEIVED SHARES OPERATIONS
  // ============================================

  /// Save a received share.
  Future<void> saveReceivedShare(Map<String, dynamic> share) async {
    await _database!.insert(
      'received_shares',
      share,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all received shares.
  Future<List<Map<String, dynamic>>> getReceivedShares() async {
    return await _database!.query('received_shares', orderBy: 'created_at DESC');
  }

  /// Get a received share by ID.
  Future<Map<String, dynamic>?> getReceivedShare(String id) async {
    final results = await _database!.query(
      'received_shares',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Update received share epoch.
  Future<void> updateReceivedShareEpoch(String id, int epoch) async {
    await _database!.update(
      'received_shares',
      {
        'current_epoch': epoch,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a received share and all its contacts.
  Future<void> deleteReceivedShare(String id) async {
    await _database!.delete('received_shares', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // RECEIVED CONTACTS OPERATIONS
  // ============================================

  /// Save received contacts (replaces existing for that share).
  Future<void> saveReceivedContacts(String shareId, List<Map<String, dynamic>> contacts) async {
    await _database!.transaction((txn) async {
      // Delete existing contacts for this share
      await txn.delete('received_contacts', where: 'share_id = ?', whereArgs: [shareId]);

      // Insert new contacts
      for (final contact in contacts) {
        await txn.insert('received_contacts', {
          ...contact,
          'share_id': shareId,
        });
      }
    });
  }

  /// Get contacts from a received share.
  Future<List<Map<String, dynamic>>> getReceivedContacts(String shareId) async {
    return await _database!.query(
      'received_contacts',
      where: 'share_id = ?',
      whereArgs: [shareId],
      orderBy: 'sort_order ASC',
    );
  }

  // ============================================
  // EPOCH KEYS OPERATIONS
  // ============================================

  /// Save an epoch key for a received share.
  Future<void> saveEpochKey(Map<String, dynamic> key) async {
    await _database!.insert(
      'epoch_keys',
      key,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get epoch key for a share and epoch number.
  Future<Map<String, dynamic>?> getEpochKey(String shareId, int epochNumber) async {
    final results = await _database!.query(
      'epoch_keys',
      where: 'share_id = ? AND epoch_number = ?',
      whereArgs: [shareId, epochNumber],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get latest epoch key for a share.
  Future<Map<String, dynamic>?> getLatestEpochKey(String shareId) async {
    final results = await _database!.query(
      'epoch_keys',
      where: 'share_id = ?',
      whereArgs: [shareId],
      orderBy: 'epoch_number DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ============================================
  // SETTINGS OPERATIONS
  // ============================================

  /// Save P2P settings.
  Future<void> saveP2PSettings({
    required bool enabled,
    String? publicKey,
  }) async {
    await _database!.insert(
      'p2p_settings',
      {
        'id': 1,
        'privacy_mode_enabled': enabled ? 1 : 0,
        'public_key': publicKey,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get P2P settings.
  Future<Map<String, dynamic>?> getP2PSettings() async {
    final results = await _database!.query('p2p_settings', where: 'id = 1');
    return results.isNotEmpty ? results.first : null;
  }

  /// Check if privacy mode is enabled.
  Future<bool> isPrivacyModeEnabled() async {
    final settings = await getP2PSettings();
    return settings?['privacy_mode_enabled'] == 1;
  }
}
