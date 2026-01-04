import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/p2p_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

/// Screen for choosing between Standard Mode and P2P Privacy Mode.
class PrivacyModeScreen extends StatefulWidget {
  const PrivacyModeScreen({super.key});

  @override
  State<PrivacyModeScreen> createState() => _PrivacyModeScreenState();
}

class _PrivacyModeScreenState extends State<PrivacyModeScreen> {
  _PrivacyMode _selectedMode = _PrivacyMode.p2p; // SSI: P2P is default
  bool _isEnabling = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.security,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Choose Your Privacy Mode',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can change this later in Settings',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Mode options - P2P first (SSI default)
              Expanded(
                child: ListView(
                  children: [
                    _buildModeCard(
                      mode: _PrivacyMode.p2p,
                      icon: Icons.shield_outlined,
                      title: 'Self-Sovereign Mode',
                      subtitle: 'You own your data',
                      description:
                          'True data ownership. Your contacts are encrypted and stored only on your device. Share directly via QR codes with end-to-end encryption.',
                      features: [
                        'Self-sovereign identity',
                        'End-to-end encrypted',
                        'No server storage',
                        'Revocable access',
                      ],
                      recommended: true,
                    ),
                    const SizedBox(height: 16),
                    _buildModeCard(
                      mode: _PrivacyMode.standard,
                      icon: Icons.cloud_outlined,
                      title: 'Cloud Sync Mode',
                      subtitle: 'Convenience first',
                      description:
                          'Your contacts are encrypted and stored on our servers. Access from any device. Good for users who prioritize convenience.',
                      features: [
                        'Sync across devices',
                        'Share via links',
                        'Server backup',
                        'Easy recovery',
                      ],
                      recommended: false,
                      isAdvanced: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue button
              AppButton(
                label: _isEnabling ? 'Setting up...' : 'Continue',
                onPressed: _isEnabling ? null : _continue,
                isFullWidth: true,
                isLoading: _isEnabling,
              ),
              const SizedBox(height: 12),

              // Skip button (only for cloud mode - P2P requires key setup)
              if (_selectedMode == _PrivacyMode.standard)
                TextButton(
                  onPressed: () => _skipOnboarding(context),
                  child: const Text('Use Cloud Mode without setup'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required _PrivacyMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required List<String> features,
    required bool recommended,
    bool isAdvanced = false,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? AppColors.primary : AppColors.secondary,
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
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (recommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SSI Default',
                                  style: TextStyle(
                                    color: AppColors.textOnPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            if (isAdvanced) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Advanced',
                                  style: TextStyle(
                                    color: AppColors.textOnPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Radio<_PrivacyMode>(
                    value: mode,
                    groupValue: _selectedMode,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMode = value);
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.map((feature) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feature,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (_selectedMode == _PrivacyMode.p2p) {
      // Enable P2P mode
      setState(() => _isEnabling = true);

      try {
        final p2pProvider = context.read<P2PProvider>();
        final success = await p2pProvider.enablePrivacyMode();

        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  p2pProvider.errorMessage ?? 'Failed to enable Privacy Mode',
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }

        // Show success message
        if (mounted) {
          await _showP2PSuccessDialog();
        }
      } finally {
        if (mounted) {
          setState(() => _isEnabling = false);
        }
      }
    }

    // Complete onboarding
    if (mounted) {
      context.read<AuthProvider>().completeOnboarding();
    }
  }

  Future<void> _showP2PSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock,
            color: AppColors.success,
            size: 32,
          ),
        ),
        title: const Text('Privacy Mode Enabled'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Master Identity Key has been generated and securely stored on this device.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you lose this device without backup, your data cannot be recovered.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _skipOnboarding(BuildContext context) {
    context.read<AuthProvider>().completeOnboarding();
  }
}

enum _PrivacyMode { standard, p2p }
