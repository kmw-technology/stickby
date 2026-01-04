import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/demo_sync_service.dart';

/// Provider for managing demo sync state
class DemoSyncProvider with ChangeNotifier {
  final DemoSyncService _syncService = DemoSyncService();

  List<DemoIdentity> _availableIdentities = [];
  DemoIdentity? _selectedIdentity;
  DemoSyncMode _selectedMode = DemoSyncMode.p2p;
  bool _isLoading = false;
  String? _error;
  String? _sessionCode;
  bool _isHost = false;

  StreamSubscription? _participantJoinedSub;
  StreamSubscription? _participantLeftSub;
  StreamSubscription? _p2pMessageSub;
  StreamSubscription? _stateUpdateSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _connectionStateSub;

  DemoSyncProvider() {
    _setupListeners();
  }

  // Getters
  List<DemoIdentity> get availableIdentities => _availableIdentities;
  DemoIdentity? get selectedIdentity => _selectedIdentity;
  DemoSyncMode get selectedMode => _selectedMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get sessionCode => _sessionCode;
  bool get isHost => _isHost;
  bool get isConnected => _syncService.isConnected;
  List<DemoSyncParticipant> get participants => _syncService.participants;
  int get currentEpoch => _syncService.currentEpoch;

  /// Stream access for components that need to listen
  Stream<DemoSyncParticipant> get onParticipantJoined => _syncService.onParticipantJoined;
  Stream<String> get onParticipantLeft => _syncService.onParticipantLeft;
  Stream<Map<String, dynamic>> get onP2PMessage => _syncService.onP2PMessage;
  Stream<Map<String, dynamic>> get onStateUpdate => _syncService.onStateUpdate;

  void _setupListeners() {
    _connectionStateSub = _syncService.onConnectionStateChanged.listen((connected) {
      notifyListeners();
    });

    _participantJoinedSub = _syncService.onParticipantJoined.listen((participant) {
      notifyListeners();
    });

    _participantLeftSub = _syncService.onParticipantLeft.listen((identityId) {
      notifyListeners();
    });

    _errorSub = _syncService.onError.listen((error) {
      _error = error;
      notifyListeners();
    });
  }

  /// Load available demo identities from server
  Future<void> loadIdentities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableIdentities = await _syncService.fetchIdentities();

      // Fallback to local identities if server is unavailable
      if (_availableIdentities.isEmpty) {
        _availableIdentities = _getLocalIdentities();
      }
    } catch (e) {
      _error = 'Failed to load identities: $e';
      _availableIdentities = _getLocalIdentities();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set the selected identity
  void selectIdentity(DemoIdentity identity) {
    _selectedIdentity = identity;
    notifyListeners();
  }

  /// Set the sync mode
  void selectMode(DemoSyncMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  /// Create a new demo session as host
  Future<String?> createSession() async {
    if (_selectedIdentity == null) {
      _error = 'Please select an identity first';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final code = await _syncService.createSession(_selectedMode);
      if (code != null) {
        _sessionCode = code;
        _isHost = true;

        // Automatically join the session
        final success = await _syncService.joinSession(
          sessionCode: code,
          identityId: _selectedIdentity!.id,
          mode: _selectedMode,
        );

        if (!success) {
          _error = 'Failed to join created session';
          _sessionCode = null;
          _isHost = false;
        }
      } else {
        _error = 'Failed to create session';
      }
    } catch (e) {
      _error = 'Error creating session: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _sessionCode;
  }

  /// Join an existing demo session
  Future<bool> joinSession(String sessionCode) async {
    if (_selectedIdentity == null) {
      _error = 'Please select an identity first';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _syncService.joinSession(
        sessionCode: sessionCode,
        identityId: _selectedIdentity!.id,
        mode: _selectedMode,
      );

      if (success) {
        _sessionCode = sessionCode;
        _isHost = false;
      } else {
        _error = 'Failed to join session';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Error joining session: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Leave the current session
  Future<void> leaveSession() async {
    await _syncService.leaveSession();
    _sessionCode = null;
    _isHost = false;
    notifyListeners();
  }

  /// Send a P2P message (P2P mode only)
  Future<void> sendP2PMessage(Map<String, dynamic> data, {String? targetIdentityId}) async {
    if (!isConnected || _selectedMode != DemoSyncMode.p2p) return;
    await _syncService.sendP2PMessage(data, targetIdentityId: targetIdentityId);
  }

  /// Submit a state update (Database mode only)
  Future<void> submitStateUpdate(Map<String, dynamic> state) async {
    if (!isConnected || _selectedMode != DemoSyncMode.database) return;
    await _syncService.submitStateUpdate(state);
  }

  /// Request current state from server (Database mode only)
  Future<void> requestCurrentState() async {
    if (!isConnected || _selectedMode != DemoSyncMode.database) return;
    await _syncService.requestCurrentState();
  }

  /// Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get local fallback identities
  List<DemoIdentity> _getLocalIdentities() {
    return [
      DemoIdentity(id: 'nicolas-wild', name: 'Nicolas Wild', email: 'nicolas.wild@googlemail.com', avatarPath: 'nw.jpg', color: '#2563eb'),
      DemoIdentity(id: 'clara-nguyen', name: 'Clara Nguyen', email: 'clara.nguyen@web.de', avatarPath: 'cn.jpg', color: '#dc2626'),
      DemoIdentity(id: 'andreas-bauer', name: 'Andreas Bauer', email: 'andreas.bauer@gmail.com', avatarPath: 'ab.jpg', color: '#16a34a'),
      DemoIdentity(id: 'andrea-wimmer', name: 'Andrea Wimmer', email: 'andrea.wimmer@example.com', avatarPath: 'aw.jpg', color: '#9333ea'),
      DemoIdentity(id: 'anna-dannhauser', name: 'Anna Dannhauser', email: 'anna.dannhauser@example.com', avatarPath: 'ad.jpg', color: '#ea580c'),
      DemoIdentity(id: 'stefan-keller', name: 'Stefan Keller', email: 'stefan.keller@example.com', avatarPath: 'sk.jpg', color: '#0891b2'),
    ];
  }

  @override
  void dispose() {
    _participantJoinedSub?.cancel();
    _participantLeftSub?.cancel();
    _p2pMessageSub?.cancel();
    _stateUpdateSub?.cancel();
    _errorSub?.cancel();
    _connectionStateSub?.cancel();
    _syncService.dispose();
    super.dispose();
  }
}
