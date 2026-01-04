import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Cryptographic service for P2P Privacy Mode.
/// Handles key generation, derivation, encryption, and signing.
class CryptoService {
  static final _aesGcm = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _ed25519 = Ed25519();

  // Singleton pattern
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  /// Generate a new Master Identity Key (256-bit random).
  /// Called once when user enables P2P Privacy Mode.
  Future<Uint8List> generateMasterIdentityKey() async {
    final secretKey = await _aesGcm.newSecretKey();
    return Uint8List.fromList(await secretKey.extractBytes());
  }

  /// Generate Ed25519 key pair for user identity.
  /// Public key is shared with recipients, private key signs data.
  Future<KeyPairResult> generateKeyPair() async {
    final keyPair = await _ed25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    return KeyPairResult(
      publicKey: Uint8List.fromList(publicKey.bytes),
      privateKey: Uint8List.fromList(privateKeyBytes),
    );
  }

  /// Derive Epoch Key from Master Identity Key.
  /// Each epoch has a unique key derived deterministically.
  ///
  /// EK_n = HKDF(MIK, salt="epoch", info="epoch_{n}")
  Future<Uint8List> deriveEpochKey(Uint8List masterKey, int epochNumber) async {
    final secretKey = SecretKey(masterKey);
    final derivedKey = await _hkdf.deriveKey(
      secretKey: secretKey,
      nonce: utf8.encode('epoch'),
      info: utf8.encode('epoch_$epochNumber'),
    );
    return Uint8List.fromList(await derivedKey.extractBytes());
  }

  /// Derive Share Key for a specific recipient.
  /// This key encrypts data for that recipient only.
  ///
  /// SK = HKDF(EK_n, salt="share", info=recipient_public_key)
  Future<Uint8List> deriveShareKey(
    Uint8List epochKey,
    Uint8List recipientPublicKey,
  ) async {
    final secretKey = SecretKey(epochKey);
    final derivedKey = await _hkdf.deriveKey(
      secretKey: secretKey,
      nonce: utf8.encode('share'),
      info: recipientPublicKey,
    );
    return Uint8List.fromList(await derivedKey.extractBytes());
  }

  /// Derive database encryption key from Master Identity Key.
  /// Used to encrypt the local SQLCipher database.
  Future<Uint8List> deriveDatabaseKey(Uint8List masterKey) async {
    final secretKey = SecretKey(masterKey);
    final derivedKey = await _hkdf.deriveKey(
      secretKey: secretKey,
      nonce: utf8.encode('localdb'),
      info: utf8.encode('sqlcipher_key'),
    );
    return Uint8List.fromList(await derivedKey.extractBytes());
  }

  /// Encrypt data using AES-256-GCM.
  /// Returns ciphertext with appended authentication tag.
  Future<EncryptionResult> encrypt(
    Uint8List plaintext,
    Uint8List key,
  ) async {
    final secretKey = SecretKey(key);
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Combine ciphertext + MAC tag
    final ciphertext = Uint8List.fromList([
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return EncryptionResult(
      ciphertext: ciphertext,
      nonce: Uint8List.fromList(nonce),
    );
  }

  /// Encrypt a JSON string.
  Future<EncryptionResult> encryptString(String plaintext, Uint8List key) async {
    return encrypt(Uint8List.fromList(utf8.encode(plaintext)), key);
  }

  /// Decrypt data encrypted with AES-256-GCM.
  Future<Uint8List> decrypt(
    Uint8List ciphertext,
    Uint8List nonce,
    Uint8List key,
  ) async {
    final secretKey = SecretKey(key);

    // Split ciphertext and MAC tag (last 16 bytes)
    final macBytes = ciphertext.sublist(ciphertext.length - 16);
    final cipherBytes = ciphertext.sublist(0, ciphertext.length - 16);

    final secretBox = SecretBox(
      cipherBytes,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await _aesGcm.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(plaintext);
  }

  /// Decrypt to a string.
  Future<String> decryptString(
    Uint8List ciphertext,
    Uint8List nonce,
    Uint8List key,
  ) async {
    final plaintext = await decrypt(ciphertext, nonce, key);
    return utf8.decode(plaintext);
  }

  /// Sign data with Ed25519 private key.
  Future<Uint8List> sign(Uint8List data, Uint8List privateKey) async {
    // Ed25519 uses 32-byte seed to derive key pair
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKey.sublist(0, 32));
    final signature = await _ed25519.sign(data, keyPair: keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  /// Verify Ed25519 signature.
  Future<bool> verify(
    Uint8List data,
    Uint8List signature,
    Uint8List publicKey,
  ) async {
    try {
      final pubKey = SimplePublicKey(publicKey, type: KeyPairType.ed25519);
      final sig = Signature(signature, publicKey: pubKey);
      return await _ed25519.verify(data, signature: sig);
    } catch (e) {
      return false;
    }
  }

  /// Compute SHA-256 hash of data.
  Future<Uint8List> sha256Hash(Uint8List data) async {
    final algorithm = Sha256();
    final hash = await algorithm.hash(data);
    return Uint8List.fromList(hash.bytes);
  }

  /// Encrypt a share key for a recipient using their public key.
  /// This allows only the recipient to decrypt the share key.
  Future<Uint8List> encryptShareKeyForRecipient(
    Uint8List shareKey,
    Uint8List recipientPublicKey,
    Uint8List senderPrivateKey,
  ) async {
    // Use X25519 key exchange to derive shared secret
    // Then encrypt share key with the shared secret
    final x25519 = X25519();

    // Convert Ed25519 keys to X25519 for key exchange
    // Note: In production, you might want to use separate X25519 keys
    final senderKeyPair = await x25519.newKeyPair();
    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: senderKeyPair,
      remotePublicKey: SimplePublicKey(recipientPublicKey, type: KeyPairType.x25519),
    );

    // Derive encryption key from shared secret
    final encKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode('sharekey'),
      info: utf8.encode('encrypt'),
    );

    // Encrypt the share key
    final result = await encrypt(shareKey, Uint8List.fromList(await encKey.extractBytes()));

    // Include ephemeral public key in output
    final ephemeralPubKey = await senderKeyPair.extractPublicKey();
    return Uint8List.fromList([
      ...ephemeralPubKey.bytes,
      ...result.nonce,
      ...result.ciphertext,
    ]);
  }

  /// Decrypt a share key using recipient's private key.
  Future<Uint8List> decryptShareKeyForRecipient(
    Uint8List encryptedShareKey,
    Uint8List recipientPrivateKey,
  ) async {
    // Extract ephemeral public key (32 bytes), nonce (12 bytes), ciphertext (rest)
    final ephemeralPubKey = encryptedShareKey.sublist(0, 32);
    final nonce = encryptedShareKey.sublist(32, 44);
    final ciphertext = encryptedShareKey.sublist(44);

    final x25519 = X25519();

    // Recreate key pair from private key
    final keyPair = await x25519.newKeyPairFromSeed(recipientPrivateKey.sublist(0, 32));

    // Derive shared secret
    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(ephemeralPubKey, type: KeyPairType.x25519),
    );

    // Derive decryption key
    final decKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode('sharekey'),
      info: utf8.encode('encrypt'),
    );

    // Decrypt the share key
    return decrypt(ciphertext, nonce, Uint8List.fromList(await decKey.extractBytes()));
  }
}

/// Result of key pair generation.
class KeyPairResult {
  final Uint8List publicKey;
  final Uint8List privateKey;

  KeyPairResult({required this.publicKey, required this.privateKey});
}

/// Result of encryption operation.
class EncryptionResult {
  final Uint8List ciphertext;
  final Uint8List nonce;

  EncryptionResult({required this.ciphertext, required this.nonce});

  /// Convert to base64 for storage/transmission.
  Map<String, String> toBase64() => {
    'ciphertext': base64Encode(ciphertext),
    'nonce': base64Encode(nonce),
  };

  /// Create from base64 encoded data.
  factory EncryptionResult.fromBase64(Map<String, String> data) {
    return EncryptionResult(
      ciphertext: base64Decode(data['ciphertext']!),
      nonce: base64Decode(data['nonce']!),
    );
  }
}
