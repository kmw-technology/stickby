import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/demo_sync_provider.dart';
import '../../providers/demo_provider.dart';
import '../../services/demo_sync_service.dart';
import '../../theme/app_theme.dart' show AppColors;
import '../main_screen.dart';

/// Screen for setting up multi-device demo sync
class DemoSyncScreen extends StatefulWidget {
  const DemoSyncScreen({super.key});

  @override
  State<DemoSyncScreen> createState() => _DemoSyncScreenState();
}

class _DemoSyncScreenState extends State<DemoSyncScreen> {
  final _sessionCodeController = TextEditingController();
  bool _showJoinSession = false;

  @override
  void initState() {
    super.initState();
    // Load identities when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DemoSyncProvider>().loadIdentities();
    });
  }

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<DemoSyncProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.availableIdentities.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show session lobby if connected
          if (provider.isConnected) {
            return _buildSessionLobby(context, provider);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Multi-Device Demo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Test real-time sync between multiple devices. Select your identity and sync mode to get started.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Step 1: Select Identity
                _buildSectionHeader('1. Select Your Identity'),
                const SizedBox(height: 12),
                _buildIdentitySelector(provider),
                const SizedBox(height: 24),

                // Step 2: Select Sync Mode
                _buildSectionHeader('2. Choose Sync Mode'),
                const SizedBox(height: 12),
                _buildSyncModeSelector(provider),
                const SizedBox(height: 32),

                // Error display
                if (provider.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: provider.clearError,
                          iconSize: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                if (!_showJoinSession) ...[
                  FilledButton.icon(
                    onPressed: provider.selectedIdentity == null || provider.isLoading
                        ? null
                        : () => _createSession(provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Session'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: provider.selectedIdentity == null
                        ? null
                        : () => setState(() => _showJoinSession = true),
                    icon: const Icon(Icons.login),
                    label: const Text('Join Existing Session'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _sessionCodeController,
                    decoration: InputDecoration(
                      labelText: 'Session Code',
                      hintText: 'Enter 6-character code',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      UpperCaseTextFormatter(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _showJoinSession = false;
                            _sessionCodeController.clear();
                          }),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: provider.isLoading ||
                                  _sessionCodeController.text.length != 6
                              ? null
                              : () => _joinSession(provider),
                          child: provider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Join'),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // Or start solo demo
                const Divider(),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _startSoloDemo(context),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Or start solo demo mode'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildIdentitySelector(DemoSyncProvider provider) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: provider.availableIdentities.map((identity) {
        final isSelected = provider.selectedIdentity?.id == identity.id;
        final color = _parseColor(identity.color);

        return InkWell(
          onTap: () => provider.selectIdentity(identity),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: Text(
                    identity.name.split(' ').map((n) => n[0]).take(2).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  identity.name.split(' ').first,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSyncModeSelector(DemoSyncProvider provider) {
    return Column(
      children: [
        _buildModeCard(
          provider: provider,
          mode: DemoSyncMode.p2p,
          icon: Icons.lock,
          title: 'P2P (Privacy Mode)',
          description: 'End-to-end encrypted. Server only relays encrypted data and cannot read your messages.',
          color: AppColors.success,
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          provider: provider,
          mode: DemoSyncMode.database,
          icon: Icons.cloud,
          title: 'Database (Server Mode)',
          description: 'Server stores encrypted state for easy sync. Good for testing shared updates.',
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required DemoSyncProvider provider,
    required DemoSyncMode mode,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = provider.selectedMode == mode;

    return InkWell(
      onTap: () => provider.selectMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<DemoSyncMode>(
              value: mode,
              groupValue: provider.selectedMode,
              onChanged: (value) => provider.selectMode(value!),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionLobby(BuildContext context, DemoSyncProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Session code display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Session Code',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.sessionCode ?? '',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: provider.sessionCode ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session code copied!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Code'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mode indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                provider.selectedMode == DemoSyncMode.p2p
                    ? Icons.lock
                    : Icons.cloud,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                provider.selectedMode == DemoSyncMode.p2p
                    ? 'P2P Mode (End-to-End Encrypted)'
                    : 'Database Mode (Server Sync)',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Participants list
          Text(
            'Participants (${provider.participants.length + 1})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // Current user (you)
          _buildParticipantTile(
            identity: provider.selectedIdentity!,
            isYou: true,
          ),
          const SizedBox(height: 8),

          // Other participants
          ...provider.participants.map((p) {
            final identity = provider.availableIdentities.firstWhere(
              (i) => i.id == p.identityId,
              orElse: () => DemoIdentity(
                id: p.identityId,
                name: p.identityId,
                email: '',
                avatarPath: '',
                color: '#808080',
              ),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildParticipantTile(identity: identity, isYou: false),
            );
          }),

          if (provider.participants.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Waiting for others to join...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share the session code with another device',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Start Demo button (enabled when at least 2 participants)
          FilledButton.icon(
            onPressed: () => _startSyncedDemo(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Demo'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => provider.leaveSession(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Leave Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile({
    required DemoIdentity identity,
    required bool isYou,
  }) {
    final color = _parseColor(identity.color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isYou ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: isYou ? Border.all(color: color) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Text(
              identity.name.split(' ').map((n) => n[0]).take(2).join(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      identity.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  identity.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.circle,
            size: 12,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  Future<void> _createSession(DemoSyncProvider provider) async {
    final sessionCode = await provider.createSession();
    if (sessionCode != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session created: $sessionCode'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sessionCode));
            },
          ),
        ),
      );
    }
  }

  Future<void> _joinSession(DemoSyncProvider provider) async {
    final code = _sessionCodeController.text.trim().toUpperCase();
    if (code.length != 6) return;

    final success = await provider.joinSession(code);
    if (success && mounted) {
      setState(() => _showJoinSession = false);
    }
  }

  Future<void> _startSoloDemo(BuildContext context) async {
    final demoProvider = context.read<DemoProvider>();
    await demoProvider.enableDemoMode();

    if (mounted && demoProvider.isDemoMode) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  void _startSyncedDemo(BuildContext context) async {
    final demoProvider = context.read<DemoProvider>();
    await demoProvider.enableDemoMode();

    if (mounted && demoProvider.isDemoMode) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
