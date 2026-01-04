import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/backup_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

/// Screen for backing up and recovering Master Identity Key.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  final StorageService _storageService = StorageService();

  String? _mnemonic;
  bool _isLoading = false;
  bool _showMnemonic = false;
  bool _hasCopied = false;

  @override
  void initState() {
    super.initState();
    _loadMnemonic();
  }

  Future<void> _loadMnemonic() async {
    setState(() => _isLoading = true);

    try {
      final masterKeyHex = await _storageService.getMasterIdentityKey();
      if (masterKeyHex != null) {
        final masterKey = masterKeyHex.toUint8List();
        final mnemonic = _backupService.generateMnemonic(masterKey);
        setState(() => _mnemonic = mnemonic);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Recovery'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning card
                  _buildWarningCard(),
                  const SizedBox(height: 24),

                  // Mnemonic section
                  _buildMnemonicSection(),
                  const SizedBox(height: 24),

                  // Recovery section
                  _buildRecoverySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Security Information',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your recovery phrase is the ONLY way to restore your data if you lose access to this device. Store it securely offline. Never share it with anyone.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicSection() {
    if (_mnemonic == null) {
      return const SizedBox.shrink();
    }

    final words = _mnemonic!.split(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Recovery Phrase',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: Icon(
                _showMnemonic ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _showMnemonic = !_showMnemonic),
              tooltip: _showMnemonic ? 'Hide' : 'Show',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '24 words that can restore your entire identity',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 16),

        // Mnemonic grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: _showMnemonic
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(words.length, (index) {
                    return _buildWordChip(index + 1, words[index]);
                  }),
                )
              : Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the eye icon to reveal your recovery phrase',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: 16),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedGradientButton(
                label: _hasCopied ? 'Copied!' : 'Copy to Clipboard',
                icon: _hasCopied ? Icons.check : Icons.copy,
                onPressed: _showMnemonic ? _copyMnemonic : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedGradientButton(
                label: 'Share',
                icon: Icons.share,
                onPressed: _showMnemonic ? _shareMnemonic : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // QR Code option
        GradientButton(
          label: 'Show QR Code Backup',
          icon: Icons.qr_code,
          onPressed: _showQRBackup,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildWordChip(int index, String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$index.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            word,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restore from Backup',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your 24-word recovery phrase or scan a backup QR code',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedGradientButton(
                label: 'Enter Phrase',
                icon: Icons.edit,
                onPressed: _showRecoveryDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedGradientButton(
                label: 'Scan QR',
                icon: Icons.qr_code_scanner,
                onPressed: _scanQRBackup,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copyMnemonic() {
    if (_mnemonic != null) {
      Clipboard.setData(ClipboardData(text: _mnemonic!));
      setState(() => _hasCopied = true);

      // Reset after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _hasCopied = false);
        }
      });
    }
  }

  void _shareMnemonic() {
    if (_mnemonic != null) {
      Share.share(
        'StickBy Recovery Phrase:\n\n$_mnemonic\n\nStore this securely!',
        subject: 'StickBy Recovery Phrase',
      );
    }
  }

  Future<void> _showQRBackup() async {
    // Get password for encryption
    final password = await _showPasswordDialog(
      title: 'Encrypt Backup',
      message: 'Enter a password to encrypt your backup QR code:',
    );

    if (password == null || password.isEmpty) return;

    // Generate QR data
    final masterKeyHex = await _storageService.getMasterIdentityKey();
    final publicKeyHex = await _storageService.getP2PPublicKey();
    final privateKeyHex = await _storageService.getP2PPrivateKey();

    if (masterKeyHex == null || publicKeyHex == null || privateKeyHex == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load keys')),
        );
      }
      return;
    }

    final qrData = await _backupService.generateBackupQRData(
      masterKeyHex.toUint8List(),
      publicKeyHex.toUint8List(),
      privateKeyHex.toUint8List(),
      password,
    );

    if (mounted) {
      _showQRCodeDialog(qrData);
    }
  }

  void _showQRCodeDialog(String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan this QR code on another device to restore your identity.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPasswordDialog({
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecoveryDialog() async {
    final controller = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enter Recovery Phrase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your 24-word recovery phrase, separated by spaces:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'word1 word2 word3 ...',
                  border: const OutlineInputBorder(),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final mnemonic = controller.text.trim().toLowerCase();
                final isValid = _backupService.validateMnemonic(mnemonic);

                if (!isValid) {
                  setDialogState(() {
                    error = 'Invalid recovery phrase. Please check and try again.';
                  });
                  return;
                }

                // Recover key
                final masterKey = _backupService.recoverFromMnemonic(mnemonic);
                if (masterKey == null) {
                  setDialogState(() {
                    error = 'Failed to recover key from phrase.';
                  });
                  return;
                }

                Navigator.of(context).pop();
                _confirmRecovery(masterKey);
              },
              child: const Text('Recover'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRecovery(Uint8List masterKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning, color: AppColors.warning, size: 48),
        title: const Text('Confirm Recovery'),
        content: const Text(
          'This will replace your current identity with the recovered one. '
          'Any existing local data will be lost. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace Identity'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Implement full recovery (regenerate keypair, reinitialize DB)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery initiated...')),
      );
    }
  }

  void _scanQRBackup() {
    // TODO: Implement QR scanning for backup recovery
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR scanning coming soon...')),
    );
  }
}
