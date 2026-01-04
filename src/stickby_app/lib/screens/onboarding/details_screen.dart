import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'privacy_mode_screen.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill email from user account
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.email != null) {
      _emailController.text = authProvider.user!.email;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final contactsProvider = context.read<ContactsProvider>();
    bool anyAdded = false;

    // Add phone if provided
    if (_phoneController.text.isNotEmpty) {
      final success = await contactsProvider.createContact(
        type: ContactType.mobile,
        label: 'Personal Phone',
        value: _phoneController.text.trim(),
        releaseGroups: ReleaseGroup.all,
      );
      if (success) anyAdded = true;
    }

    // Add email if provided and different from account email
    if (_emailController.text.isNotEmpty) {
      final success = await contactsProvider.createContact(
        type: ContactType.email,
        label: 'Personal Email',
        value: _emailController.text.trim(),
        releaseGroups: ReleaseGroup.all,
      );
      if (success) anyAdded = true;
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (anyAdded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Navigate to privacy mode selection
      _navigateToPrivacyMode();
    }
  }

  void _skip() {
    _navigateToPrivacyMode();
  }

  void _navigateToPrivacyMode() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PrivacyModeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_add_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add your first contacts',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can add more later from the Contacts tab',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Phone field
                AppTextField(
                  label: 'Phone Number',
                  hint: '+1 234 567 8900',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 16),

                // Email field
                AppTextField(
                  label: 'Email Address',
                  hint: 'your@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'These contacts will be visible to all your groups by default. You can change visibility later.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                AppButton(
                  label: 'Save & Continue',
                  onPressed: _handleSave,
                  isLoading: _isSaving,
                  isFullWidth: true,
                ),
                const SizedBox(height: 12),

                // Skip button
                TextButton(
                  onPressed: _skip,
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
