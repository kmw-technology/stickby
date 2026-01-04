import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EditContactScreen extends StatefulWidget {
  final Contact contact;

  const EditContactScreen({super.key, required this.contact});

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _valueController;

  late ContactType _selectedType;
  late int _releaseGroups;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.contact.label);
    _valueController = TextEditingController(text: widget.contact.value);
    _selectedType = widget.contact.type;
    _releaseGroups = widget.contact.releaseGroups;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final contactsProvider = context.read<ContactsProvider>();
    final success = await contactsProvider.updateContact(
      widget.contact.id,
      type: _selectedType,
      label: _labelController.text.trim(),
      value: _valueController.text.trim(),
      releaseGroups: _releaseGroups,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(contactsProvider.errorMessage ?? 'Failed to save contact'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete "${widget.contact.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final contactsProvider = context.read<ContactsProvider>();
      final success = await contactsProvider.deleteContact(widget.contact.id);
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _handleDelete,
            color: AppColors.danger,
          ),
        ],
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
                label: 'Save Changes',
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
