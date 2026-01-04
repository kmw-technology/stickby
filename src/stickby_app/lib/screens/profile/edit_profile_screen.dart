import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    if (profile != null) {
      _displayNameController.text = profile.displayName;
      _bioController.text = profile.bio ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = context.read<ProfileProvider>();
    final success = await profileProvider.updateProfile(
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim().isNotEmpty
          ? _bioController.text.trim()
          : null,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.errorMessage ?? 'Failed to update profile'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display name field
              AppTextField(
                label: 'Display Name',
                hint: 'Enter your name',
                controller: _displayNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length > 100) {
                    return 'Name must be less than 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio field
              AppTextField(
                label: 'Bio (Optional)',
                hint: 'Tell others about yourself',
                controller: _bioController,
                maxLines: 4,
                minLines: 3,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Bio must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save button
              AppButton(
                label: 'Save Changes',
                onPressed: _handleSave,
                isLoading: profileProvider.isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
