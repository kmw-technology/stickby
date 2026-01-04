import 'dart:convert';

/// Outgoing P2P share created by this user.
class P2PShare {
  final String id;
  final String? serverShareId;
  final String? name;
  final int currentEpoch;
  final bool useServerRelay;
  final List<String> contactIds;
  final List<P2PRecipient> recipients;
  final DateTime createdAt;
  final DateTime? updatedAt;

  P2PShare({
    required this.id,
    this.serverShareId,
    this.name,
    required this.currentEpoch,
    this.useServerRelay = false,
    required this.contactIds,
    this.recipients = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from database row.
  factory P2PShare.fromDb(Map<String, dynamic> data, {
    List<String>? contactIds,
    List<P2PRecipient>? recipients,
  }) {
    return P2PShare(
      id: data['id'] as String,
      serverShareId: data['server_share_id'] as String?,
      name: data['name'] as String?,
      currentEpoch: data['current_epoch'] as int,
      useServerRelay: data['use_server_relay'] == 1,
      contactIds: contactIds ?? [],
      recipients: recipients ?? [],
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toDb() => {
    'id': id,
    'server_share_id': serverShareId,
    'name': name,
    'current_epoch': currentEpoch,
    'use_server_relay': useServerRelay ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  /// Create a copy with updated fields.
  P2PShare copyWith({
    String? id,
    String? serverShareId,
    String? name,
    int? currentEpoch,
    bool? useServerRelay,
    List<String>? contactIds,
    List<P2PRecipient>? recipients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return P2PShare(
      id: id ?? this.id,
      serverShareId: serverShareId ?? this.serverShareId,
      name: name ?? this.name,
      currentEpoch: currentEpoch ?? this.currentEpoch,
      useServerRelay: useServerRelay ?? this.useServerRelay,
      contactIds: contactIds ?? this.contactIds,
      recipients: recipients ?? this.recipients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get active (non-revoked) recipients.
  List<P2PRecipient> get activeRecipients =>
      recipients.where((r) => !r.isRevoked).toList();

  /// Get revoked recipients.
  List<P2PRecipient> get revokedRecipients =>
      recipients.where((r) => r.isRevoked).toList();
}

/// Recipient of a P2P share.
class P2PRecipient {
  final String id;
  final String shareId;
  final String publicKey;
  final String? label;
  final int lastDeliveredEpoch;
  final bool isRevoked;
  final DateTime? revokedAt;
  final DateTime createdAt;

  P2PRecipient({
    required this.id,
    required this.shareId,
    required this.publicKey,
    this.label,
    this.lastDeliveredEpoch = 0,
    this.isRevoked = false,
    this.revokedAt,
    required this.createdAt,
  });

  /// Create from database row.
  factory P2PRecipient.fromDb(Map<String, dynamic> data) {
    return P2PRecipient(
      id: data['id'] as String,
      shareId: data['share_id'] as String,
      publicKey: data['recipient_public_key'] as String,
      label: data['recipient_label'] as String?,
      lastDeliveredEpoch: data['last_delivered_epoch'] as int? ?? 0,
      isRevoked: data['is_revoked'] == 1,
      revokedAt: data['revoked_at'] != null
          ? DateTime.parse(data['revoked_at'] as String)
          : null,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toDb() => {
    'id': id,
    'share_id': shareId,
    'recipient_public_key': publicKey,
    'recipient_label': label,
    'last_delivered_epoch': lastDeliveredEpoch,
    'is_revoked': isRevoked ? 1 : 0,
    'revoked_at': revokedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  /// Create a revoked copy.
  P2PRecipient revoke() => P2PRecipient(
    id: id,
    shareId: shareId,
    publicKey: publicKey,
    label: label,
    lastDeliveredEpoch: lastDeliveredEpoch,
    isRevoked: true,
    revokedAt: DateTime.now(),
    createdAt: createdAt,
  );
}

/// Share received from another user.
class ReceivedShare {
  final String id;
  final String ownerPublicKey;
  final String? ownerDisplayName;
  final String? shareName;
  final String? serverRelayId;
  final int currentEpoch;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final List<ReceivedContact> contacts;

  ReceivedShare({
    required this.id,
    required this.ownerPublicKey,
    this.ownerDisplayName,
    this.shareName,
    this.serverRelayId,
    required this.currentEpoch,
    this.lastSyncedAt,
    required this.createdAt,
    this.contacts = const [],
  });

  /// Create from database row.
  factory ReceivedShare.fromDb(Map<String, dynamic> data, {
    List<ReceivedContact>? contacts,
  }) {
    return ReceivedShare(
      id: data['id'] as String,
      ownerPublicKey: data['owner_public_key'] as String,
      ownerDisplayName: data['owner_display_name'] as String?,
      shareName: data['share_name'] as String?,
      serverRelayId: data['server_relay_id'] as String?,
      currentEpoch: data['current_epoch'] as int,
      lastSyncedAt: data['last_synced_at'] != null
          ? DateTime.parse(data['last_synced_at'] as String)
          : null,
      createdAt: DateTime.parse(data['created_at'] as String),
      contacts: contacts ?? [],
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toDb() => {
    'id': id,
    'owner_public_key': ownerPublicKey,
    'owner_display_name': ownerDisplayName,
    'share_name': shareName,
    'server_relay_id': serverRelayId,
    'current_epoch': currentEpoch,
    'last_synced_at': lastSyncedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  /// Display name for the share.
  String get displayName =>
      shareName ?? ownerDisplayName ?? 'Unknown Share';
}

/// Contact received from a share.
class ReceivedContact {
  final String id;
  final String shareId;
  final int type;
  final String label;
  final String value;
  final int sortOrder;
  final int epochReceived;

  ReceivedContact({
    required this.id,
    required this.shareId,
    required this.type,
    required this.label,
    required this.value,
    this.sortOrder = 0,
    required this.epochReceived,
  });

  /// Create from database row.
  factory ReceivedContact.fromDb(Map<String, dynamic> data) {
    return ReceivedContact(
      id: data['id'] as String,
      shareId: data['share_id'] as String,
      type: data['type'] as int,
      label: data['label'] as String,
      value: data['value'] as String,
      sortOrder: data['sort_order'] as int? ?? 0,
      epochReceived: data['epoch_received'] as int,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toDb() => {
    'id': id,
    'share_id': shareId,
    'type': type,
    'label': label,
    'value': value,
    'sort_order': sortOrder,
    'epoch_received': epochReceived,
  };
}

/// Data structure for QR code encoding/decoding.
class QRShareData {
  static const int version = 1;

  final String ownerPublicKey;
  final String shareId;
  final int epochNumber;
  final String encryptedShareKey;
  final String? serverRelayId;
  final String? encryptedBundle;
  final String signature;

  QRShareData({
    required this.ownerPublicKey,
    required this.shareId,
    required this.epochNumber,
    required this.encryptedShareKey,
    this.serverRelayId,
    this.encryptedBundle,
    required this.signature,
  });

  /// Encode for QR code (compact JSON, base64 encoded).
  String encode() {
    final data = {
      'v': version,
      'o': ownerPublicKey,
      's': shareId,
      'e': epochNumber,
      'k': encryptedShareKey,
      if (serverRelayId != null) 'r': serverRelayId,
      if (encryptedBundle != null) 'b': encryptedBundle,
      'g': signature,
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  /// Decode from QR code data.
  factory QRShareData.decode(String qrData) {
    try {
      final jsonStr = utf8.decode(base64Decode(qrData));
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (json['v'] != version) {
        throw FormatException('Unsupported QR version: ${json['v']}');
      }

      return QRShareData(
        ownerPublicKey: json['o'] as String,
        shareId: json['s'] as String,
        epochNumber: json['e'] as int,
        encryptedShareKey: json['k'] as String,
        serverRelayId: json['r'] as String?,
        encryptedBundle: json['b'] as String?,
        signature: json['g'] as String,
      );
    } catch (e) {
      throw FormatException('Invalid QR share data: $e');
    }
  }

  /// Estimated size in bytes.
  int get estimatedSize => encode().length;

  /// Check if bundle is included (small share, fully P2P).
  bool get hasEmbeddedBundle => encryptedBundle != null;

  /// Check if server relay is configured.
  bool get hasServerRelay => serverRelayId != null;
}

/// Encrypted contact bundle for P2P transfer.
class EncryptedBundle {
  final String ciphertext;
  final String nonce;
  final int epochNumber;
  final String bundleHash;
  final String signature;

  EncryptedBundle({
    required this.ciphertext,
    required this.nonce,
    required this.epochNumber,
    required this.bundleHash,
    required this.signature,
  });

  /// Create from JSON.
  factory EncryptedBundle.fromJson(Map<String, dynamic> json) {
    return EncryptedBundle(
      ciphertext: json['ciphertext'] as String,
      nonce: json['nonce'] as String,
      epochNumber: json['epochNumber'] as int,
      bundleHash: json['bundleHash'] as String,
      signature: json['signature'] as String,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'nonce': nonce,
    'epochNumber': epochNumber,
    'bundleHash': bundleHash,
    'signature': signature,
  };

  /// Encode for transmission.
  String encode() => base64Encode(utf8.encode(jsonEncode(toJson())));

  /// Decode from transmission.
  factory EncryptedBundle.decode(String data) {
    final json = jsonDecode(utf8.decode(base64Decode(data))) as Map<String, dynamic>;
    return EncryptedBundle.fromJson(json);
  }
}
