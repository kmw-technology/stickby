import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _valueController = TextEditingController();

  ContactType _selectedType = ContactType.email;
  int _releaseGroups = ReleaseGroup.all;

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final contactsProvider = context.read<ContactsProvider>();
    final success = await contactsProvider.createContact(
      type: _selectedType,
      label: _labelController.text.trim(),
      value: _valueController.text.trim(),
      releaseGroups: _releaseGroups,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(contactsProvider.errorMessage ?? 'Failed to save contact'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type selector
              Text(
                'Type',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ContactType>(
                value: _selectedType,
                decoration: const InputDecoration(),
                items: ContactType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Label field
              AppTextField(
                label: 'Label',
                hint: 'e.g., Work Email, Personal Phone',
                controller: _labelController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a label';
                  }
                  if (value.length > 50) {
                    return 'Label must be less than 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Value field
              AppTextField(
                label: 'Value',
                hint: _getHintForType(_selectedType),
                controller: _valueController,
                keyboardType: _getKeyboardTypeForType(_selectedType),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  if (value.length > 500) {
                    return 'Value must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Release groups
              Text(
                'Visible to',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildReleaseGroupChip('Family', ReleaseGroup.family, AppColors.familyBadge),
                  _buildReleaseGroupChip('Friends', ReleaseGroup.friends, AppColors.friendsBadge),
                  _buildReleaseGroupChip('Business', ReleaseGroup.business, AppColors.businessBadge),
                  _buildReleaseGroupChip('Leisure', ReleaseGroup.leisure, AppColors.leisureBadge),
                ],
              ),
              const SizedBox(height: 32),

              // Save button
              AppButton(
                label: 'Save Contact',
                onPressed: _handleSave,
                isLoading: contactsProvider.isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReleaseGroupChip(String label, int value, Color color) {
    final isSelected = (_releaseGroups & value) != 0;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _releaseGroups |= value;
          } else {
            _releaseGroups &= ~value;
          }
        });
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  String _getHintForType(ContactType type) {
    switch (type) {
      case ContactType.email:
      case ContactType.businessEmail:
        return 'email@example.com';
      case ContactType.phone:
      case ContactType.mobile:
      case ContactType.businessPhone:
        return '+1 234 567 8900';
      case ContactType.address:
        return '123 Main St, City';
      case ContactType.website:
        return 'https://example.com';
      case ContactType.birthday:
        return 'January 1, 1990';
      default:
        return 'Enter value';
    }
  }

  TextInputType _getKeyboardTypeForType(ContactType type) {
    switch (type) {
      case ContactType.email:
      case ContactType.businessEmail:
        return TextInputType.emailAddress;
      case ContactType.phone:
      case ContactType.mobile:
      case ContactType.businessPhone:
        return TextInputType.phone;
      case ContactType.website:
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }
}
