import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import 'details_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.displayName ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Welcome icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Welcome text
              Text(
                'Welcome, $userName!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'StickBy is your self-sovereign identity platform. You own your data, you control who sees it.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Features list - privacy-first
              _buildFeatureItem(
                context,
                Icons.shield_outlined,
                'Self-Sovereign Identity',
                'Your data stays on your device, encrypted',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                Icons.lock_outlined,
                'End-to-End Encryption',
                'Military-grade security for all your contacts',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                Icons.qr_code_2_outlined,
                'Secure P2P Sharing',
                'Share directly via QR codes, no server involved',
              ),

              const Spacer(),

              // Continue button
              AppButton(
                label: 'Get Started',
                onPressed: () => _navigateToDetails(context),
                isFullWidth: true,
              ),
              const SizedBox(height: 12),

              // Skip button
              TextButton(
                onPressed: () => _skipOnboarding(context),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DetailsScreen()),
    );
  }

  void _skipOnboarding(BuildContext context) {
    context.read<AuthProvider>().completeOnboarding();
  }
}
