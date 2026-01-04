import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final groupsProvider = context.read<GroupsProvider>();
    final success = await groupsProvider.createGroup(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(groupsProvider.errorMessage ?? 'Failed to create group'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsProvider = context.watch<GroupsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              AppTextField(
                label: 'Group Name',
                hint: 'Enter group name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.length > 100) {
                    return 'Name must be less than 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              AppTextField(
                label: 'Description (Optional)',
                hint: 'Enter group description',
                controller: _descriptionController,
                maxLines: 3,
                minLines: 3,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Description must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Create button
              AppButton(
                label: 'Create Group',
                onPressed: _handleCreate,
                isLoading: groupsProvider.isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
