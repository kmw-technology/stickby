import 'dart:convert';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cryptography/cryptography.dart';

/// Service for backing up and recovering Master Identity Key.
/// Supports BIP39 mnemonic phrases and encrypted file backups.
class BackupService {
  static final _aesGcm = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  // Singleton pattern
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Generate a BIP39 mnemonic phrase (24 words) from Master Identity Key.
  /// The mnemonic can be written down and used to recover the key.
  String generateMnemonic(Uint8List masterKey) {
    // BIP39 expects entropy, MIK is 256-bit (32 bytes) = 24 word mnemonic
    return bip39.entropyToMnemonic(masterKey.toHexString());
  }

  /// Recover Master Identity Key from BIP39 mnemonic phrase.
  /// Returns null if mnemonic is invalid.
  Uint8List? recoverFromMnemonic(String mnemonic) {
    try {
      if (!bip39.validateMnemonic(mnemonic)) {
        return null;
      }
      final entropy = bip39.mnemonicToEntropy(mnemonic);
      return entropy.toUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Validate a mnemonic phrase.
  bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  /// Generate a random mnemonic (for new key generation).
  /// Returns both the mnemonic and the derived key.
  MnemonicKeyPair generateNewMnemonicKey() {
    final mnemonic = bip39.generateMnemonic(strength: 256); // 24 words
    final entropy = bip39.mnemonicToEntropy(mnemonic);
    return MnemonicKeyPair(
      mnemonic: mnemonic,
      masterKey: entropy.toUint8List(),
    );
  }

  /// Export Master Identity Key as encrypted backup string.
  /// Uses password-based encryption with HKDF + AES-256-GCM.
  Future<String> exportEncryptedBackup(
    Uint8List masterKey,
    Uint8List publicKey,
    Uint8List privateKey,
    String password,
  ) async {
    // Derive encryption key from password
    final encryptionKey = await _deriveKeyFromPassword(password);

    // Create backup payload
    final payload = BackupPayload(
      version: 1,
      masterKey: masterKey,
      publicKey: publicKey,
      privateKey: privateKey,
      createdAt: DateTime.now(),
    );

    // Serialize and encrypt
    final plaintext = utf8.encode(jsonEncode(payload.toJson()));
    final secretKey = SecretKey(encryptionKey);
    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Combine nonce + ciphertext + mac
    final encrypted = Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    // Return as base64
    return base64Encode(encrypted);
  }

  /// Import Master Identity Key from encrypted backup string.
  /// Returns null if decryption fails (wrong password or corrupted data).
  Future<BackupPayload?> importEncryptedBackup(
    String encryptedBackup,
    String password,
  ) async {
    try {
      // Decode base64
      final encrypted = base64Decode(encryptedBackup);

      // Extract nonce (first 12 bytes), ciphertext, and mac (last 16 bytes)
      final nonce = encrypted.sublist(0, 12);
      final cipherText = encrypted.sublist(12, encrypted.length - 16);
      final mac = encrypted.sublist(encrypted.length - 16);

      // Derive decryption key from password
      final decryptionKey = await _deriveKeyFromPassword(password);
      final secretKey = SecretKey(decryptionKey);

      // Decrypt
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(mac),
      );

      final plaintext = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      // Parse payload
      final json = jsonDecode(utf8.decode(plaintext));
      return BackupPayload.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Generate QR code data for backup (contains encrypted keys).
  Future<String> generateBackupQRData(
    Uint8List masterKey,
    Uint8List publicKey,
    Uint8List privateKey,
    String password,
  ) async {
    final encrypted = await exportEncryptedBackup(
      masterKey,
      publicKey,
      privateKey,
      password,
    );

    // Add prefix for identification
    return 'STICKBY-BACKUP:$encrypted';
  }

  /// Parse backup from QR code data.
  Future<BackupPayload?> parseBackupQRData(
    String qrData,
    String password,
  ) async {
    if (!qrData.startsWith('STICKBY-BACKUP:')) {
      return null;
    }

    final encrypted = qrData.substring('STICKBY-BACKUP:'.length);
    return importEncryptedBackup(encrypted, password);
  }

  /// Derive encryption key from password using HKDF.
  Future<Uint8List> _deriveKeyFromPassword(String password) async {
    final passwordBytes = utf8.encode(password);
    final secretKey = SecretKey(passwordBytes);

    final derivedKey = await _hkdf.deriveKey(
      secretKey: secretKey,
      nonce: utf8.encode('stickby_backup_salt'),
      info: utf8.encode('backup_encryption_key'),
    );

    return Uint8List.fromList(await derivedKey.extractBytes());
  }
}

/// Result of generating a new mnemonic key pair.
class MnemonicKeyPair {
  final String mnemonic;
  final Uint8List masterKey;

  MnemonicKeyPair({
    required this.mnemonic,
    required this.masterKey,
  });

  /// Get mnemonic as list of words.
  List<String> get words => mnemonic.split(' ');
}

/// Payload for encrypted backup.
class BackupPayload {
  final int version;
  final Uint8List masterKey;
  final Uint8List publicKey;
  final Uint8List privateKey;
  final DateTime createdAt;

  BackupPayload({
    required this.version,
    required this.masterKey,
    required this.publicKey,
    required this.privateKey,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'masterKey': base64Encode(masterKey),
    'publicKey': base64Encode(publicKey),
    'privateKey': base64Encode(privateKey),
    'createdAt': createdAt.toIso8601String(),
  };

  factory BackupPayload.fromJson(Map<String, dynamic> json) => BackupPayload(
    version: json['version'] as int,
    masterKey: base64Decode(json['masterKey'] as String),
    publicKey: base64Decode(json['publicKey'] as String),
    privateKey: base64Decode(json['privateKey'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Extension to convert hex string to Uint8List.
extension HexStringExtension on String {
  Uint8List toUint8List() {
    final hex = this;
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }
}

/// Extension to convert Uint8List to hex string.
extension Uint8ListHexExtension on Uint8List {
  String toHexString() {
    return map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
