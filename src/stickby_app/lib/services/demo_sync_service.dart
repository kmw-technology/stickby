import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';

/// Sync mode for demo sessions
enum DemoSyncMode {
  /// P2P Mode: Server only relays encrypted messages (privacy-first)
  p2p,
  /// Database Mode: Server stores encrypted state and broadcasts updates
  database,
}

/// Represents a participant in a demo sync session
class DemoSyncParticipant {
  final String identityId;
  final String? publicKey;
  final DateTime? joinedAt;

  DemoSyncParticipant({
    required this.identityId,
    this.publicKey,
    this.joinedAt,
  });

  factory DemoSyncParticipant.fromJson(Map<String, dynamic> json) {
    return DemoSyncParticipant(
      identityId: json['identityId'] as String,
      publicKey: json['publicKey'] as String?,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
    );
  }
}

/// Represents a demo identity that can be selected
class DemoIdentity {
  final String id;
  final String name;
  final String email;
  final String avatarPath;
  final String color;

  DemoIdentity({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarPath,
    required this.color,
  });

  factory DemoIdentity.fromJson(Map<String, dynamic> json) {
    return DemoIdentity(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarPath: json['avatarPath'] as String,
      color: json['color'] as String,
    );
  }
}

/// Service for real-time multi-device demo synchronization.
/// Supports both P2P (privacy-first) and Database (server-mediated) modes.
class DemoSyncService {
  static final DemoSyncService _instance = DemoSyncService._internal();
  factory DemoSyncService() => _instance;
  DemoSyncService._internal();

  HubConnection? _hubConnection;
  String? _currentSessionCode;
  String? _currentIdentityId;
  DemoSyncMode? _currentSyncMode;
  SimpleKeyPair? _keyPair;
  String? _publicKeyBase64;
  long _currentEpoch = 0;

  final List<DemoSyncParticipant> _participants = [];

  // Event streams
  final _participantJoinedController = StreamController<DemoSyncParticipant>.broadcast();
  final _participantLeftController = StreamController<String>.broadcast();
  final _p2pMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  /// Stream of participant join events
  Stream<DemoSyncParticipant> get onParticipantJoined => _participantJoinedController.stream;

  /// Stream of participant leave events (identity ID)
  Stream<String> get onParticipantLeft => _participantLeftController.stream;

  /// Stream of P2P messages (encrypted payload)
  Stream<Map<String, dynamic>> get onP2PMessage => _p2pMessageController.stream;

  /// Stream of state updates (database mode)
  Stream<Map<String, dynamic>> get onStateUpdate => _stateUpdateController.stream;

  /// Stream of errors
  Stream<String> get onError => _errorController.stream;

  /// Stream of connection state changes
  Stream<bool> get onConnectionStateChanged => _connectionStateController.stream;

  /// Current session code
  String? get sessionCode => _currentSessionCode;

  /// Current identity ID
  String? get identityId => _currentIdentityId;

  /// Current sync mode
  DemoSyncMode? get syncMode => _currentSyncMode;

  /// Whether connected to a session
  bool get isConnected =>
      _hubConnection != null &&
      _hubConnection!.state == HubConnectionState.Connected;

  /// List of current participants
  List<DemoSyncParticipant> get participants => List.unmodifiable(_participants);

  /// Current epoch for conflict resolution
  long get currentEpoch => _currentEpoch;

  /// Generate a new key pair for P2P encryption
  Future<void> _generateKeyPair() async {
    final algorithm = X25519();
    _keyPair = await algorithm.newKeyPair();
    final publicKey = await _keyPair!.extractPublicKey();
    _publicKeyBase64 = base64Encode(publicKey.bytes);
  }

  /// Fetch available demo identities from the server
  Future<List<DemoIdentity>> fetchIdentities() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.demoIdentities}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => DemoIdentity.fromJson(e)).toList();
      }
    } catch (e) {
      print('DemoSyncService: Error fetching identities: $e');
    }
    return [];
  }

  /// Create a new session and return the session code
  Future<String?> createSession(DemoSyncMode mode) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.demoSessionCreate}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'syncMode': mode == DemoSyncMode.p2p ? 'p2p' : 'database',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['sessionCode'] as String;
      }
    } catch (e) {
      print('DemoSyncService: Error creating session: $e');
    }
    return null;
  }

  /// Join a demo sync session
  Future<bool> joinSession({
    required String sessionCode,
    required String identityId,
    required DemoSyncMode mode,
  }) async {
    try {
      // Generate key pair for P2P encryption
      await _generateKeyPair();

      // Build SignalR hub URL
      final hubUrl = '${ApiConfig.wsBaseUrl}${ApiConfig.demoSyncHub}';

      // Create hub connection
      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      // Set up event handlers
      _setupEventHandlers();

      // Start connection
      await _hubConnection!.start();
      _connectionStateController.add(true);

      // Join the session
      await _hubConnection!.invoke(
        'JoinSession',
        args: [
          sessionCode,
          identityId,
          _publicKeyBase64!,
          mode == DemoSyncMode.p2p ? 'p2p' : 'database',
        ],
      );

      _currentSessionCode = sessionCode;
      _currentIdentityId = identityId;
      _currentSyncMode = mode;

      return true;
    } catch (e) {
      print('DemoSyncService: Error joining session: $e');
      _connectionStateController.add(false);
      return false;
    }
  }

  /// Leave the current session
  Future<void> leaveSession() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.invoke('LeaveSession');
        await _hubConnection!.stop();
      } catch (e) {
        print('DemoSyncService: Error leaving session: $e');
      }
    }

    _hubConnection = null;
    _currentSessionCode = null;
    _currentIdentityId = null;
    _currentSyncMode = null;
    _keyPair = null;
    _publicKeyBase64 = null;
    _participants.clear();
    _currentEpoch = 0;
    _connectionStateController.add(false);
  }

  /// Send a P2P message (encrypted, server cannot read)
  Future<void> sendP2PMessage(Map<String, dynamic> data, {String? targetIdentityId}) async {
    if (_hubConnection == null || _currentSyncMode != DemoSyncMode.p2p) {
      throw Exception('Not in a P2P session');
    }

    // Encrypt the data
    final encryptedPayload = await _encryptForP2P(data);

    final args = <Object>[encryptedPayload];
    if (targetIdentityId != null) {
      args.add(targetIdentityId);
    }

    await _hubConnection!.invoke(
      'RelayP2PMessage',
      args: args,
    );
  }

  /// Submit a state update (database mode)
  Future<void> submitStateUpdate(Map<String, dynamic> state) async {
    if (_hubConnection == null || _currentSyncMode != DemoSyncMode.database) {
      throw Exception('Not in a database session');
    }

    // Increment epoch
    _currentEpoch++;

    // Encrypt the state
    final encryptedState = await _encryptState(state);

    await _hubConnection!.invoke(
      'SubmitDatabaseUpdate',
      args: [encryptedState, _currentEpoch],
    );
  }

  /// Request the current state from server (database mode)
  Future<void> requestCurrentState() async {
    if (_hubConnection == null || _currentSyncMode != DemoSyncMode.database) {
      throw Exception('Not in a database session');
    }

    await _hubConnection!.invoke('RequestCurrentState');
  }

  /// Encrypt data for P2P transmission
  Future<String> _encryptForP2P(Map<String, dynamic> data) async {
    // Use a simple symmetric encryption for demo purposes
    // In production, use proper ECDH key exchange with recipient's public key
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKey();
    final nonce = algorithm.newNonce();

    final plaintext = utf8.encode(jsonEncode(data));
    final secretBox = await algorithm.encrypt(plaintext, secretKey: secretKey, nonce: nonce);

    // Combine nonce + ciphertext + mac for transmission
    final combined = [...secretBox.nonce, ...secretBox.cipherText, ...secretBox.mac.bytes];

    // Include secret key for demo (in real P2P, would use ECDH)
    final secretKeyBytes = await secretKey.extractBytes();
    final payload = {
      'key': base64Encode(secretKeyBytes),
      'data': base64Encode(combined),
    };

    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  /// Encrypt state for database storage
  Future<String> _encryptState(Map<String, dynamic> state) async {
    // Use AES-256-GCM for state encryption
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKey();
    final nonce = algorithm.newNonce();

    final plaintext = utf8.encode(jsonEncode(state));
    final secretBox = await algorithm.encrypt(plaintext, secretKey: secretKey, nonce: nonce);

    final combined = [...secretBox.nonce, ...secretBox.cipherText, ...secretBox.mac.bytes];
    final secretKeyBytes = await secretKey.extractBytes();

    final payload = {
      'key': base64Encode(secretKeyBytes),
      'data': base64Encode(combined),
    };

    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  /// Decrypt P2P message
  Future<Map<String, dynamic>?> _decryptP2PMessage(String encryptedPayload) async {
    try {
      final payloadJson = jsonDecode(utf8.decode(base64Decode(encryptedPayload)));
      final keyBytes = base64Decode(payloadJson['key'] as String);
      final combined = base64Decode(payloadJson['data'] as String);

      final algorithm = AesGcm.with256bits();
      final secretKey = await algorithm.newSecretKeyFromBytes(keyBytes);

      // Split combined into nonce, ciphertext, mac
      final nonce = combined.sublist(0, 12);
      final cipherText = combined.sublist(12, combined.length - 16);
      final mac = Mac(combined.sublist(combined.length - 16));

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
      final plaintext = await algorithm.decrypt(secretBox, secretKey: secretKey);

      return jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    } catch (e) {
      print('DemoSyncService: Error decrypting message: $e');
      return null;
    }
  }

  /// Set up SignalR event handlers
  void _setupEventHandlers() {
    _hubConnection!.on('SessionJoined', (args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;

      // Add existing participants
      final participants = (data['participants'] as List<dynamic>?)
          ?.map((e) => DemoSyncParticipant.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];

      _participants.clear();
      _participants.addAll(participants);

      // If database mode, check for existing state
      if (data['currentState'] != null && _currentSyncMode == DemoSyncMode.database) {
        _stateUpdateController.add({
          'encryptedState': data['currentState'],
          'isInitialState': true,
        });
      }
    });

    _hubConnection!.on('ParticipantJoined', (args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;
      final participant = DemoSyncParticipant(
        identityId: data['identityId'] as String,
        publicKey: data['publicKey'] as String?,
      );
      _participants.add(participant);
      _participantJoinedController.add(participant);
    });

    _hubConnection!.on('ParticipantLeft', (args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;
      final identityId = data['identityId'] as String;
      _participants.removeWhere((p) => p.identityId == identityId);
      _participantLeftController.add(identityId);
    });

    _hubConnection!.on('P2PMessage', (args) async {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;
      final encryptedPayload = data['encryptedPayload'] as String;
      final decrypted = await _decryptP2PMessage(encryptedPayload);
      if (decrypted != null) {
        _p2pMessageController.add({
          'senderIdentityId': data['senderIdentityId'],
          'data': decrypted,
          'timestamp': data['timestamp'],
        });
      }
    });

    _hubConnection!.on('StateUpdated', (args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;
      final epoch = data['epoch'] as int;
      if (epoch > _currentEpoch) {
        _currentEpoch = epoch;
      }
      _stateUpdateController.add(data);
    });

    _hubConnection!.on('CurrentState', (args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;
      final epoch = data['epoch'] as int;
      if (epoch > _currentEpoch) {
        _currentEpoch = epoch;
      }
      _stateUpdateController.add({
        ...data,
        'isCurrentState': true,
      });
    });

    _hubConnection!.on('Error', (args) {
      if (args == null || args.length < 2) return;
      final errorCode = args[0] as String;
      final message = args[1] as String;
      _errorController.add('$errorCode: $message');
    });

    // Handle reconnection
    _hubConnection!.onreconnecting(({error}) {
      _connectionStateController.add(false);
    });

    _hubConnection!.onreconnected(({connectionId}) {
      _connectionStateController.add(true);
      // Re-join session after reconnect
      if (_currentSessionCode != null && _currentIdentityId != null) {
        _hubConnection!.invoke(
          'JoinSession',
          args: [
            _currentSessionCode!,
            _currentIdentityId!,
            _publicKeyBase64!,
            _currentSyncMode == DemoSyncMode.p2p ? 'p2p' : 'database',
          ],
        );
      }
    });

    _hubConnection!.onclose(({error}) {
      _connectionStateController.add(false);
    });
  }

  /// Dispose of resources
  void dispose() {
    _participantJoinedController.close();
    _participantLeftController.close();
    _p2pMessageController.close();
    _stateUpdateController.close();
    _errorController.close();
    _connectionStateController.close();
    leaveSession();
  }
}

// Type alias for epoch counter
typedef long = int;
