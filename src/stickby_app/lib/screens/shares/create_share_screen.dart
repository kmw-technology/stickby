import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/shares_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class CreateShareScreen extends StatefulWidget {
  const CreateShareScreen({super.key});

  @override
  State<CreateShareScreen> createState() => _CreateShareScreenState();
}

class _CreateShareScreenState extends State<CreateShareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final Set<String> _selectedContactIds = {};
  DateTime? _expiresAt;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_selectedContactIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one contact'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final sharesProvider = context.read<SharesProvider>();
    final share = await sharesProvider.createShare(
      contactIds: _selectedContactIds.toList(),
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
      expiresAt: _expiresAt,
    );

    if (share != null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sharesProvider.errorMessage ?? 'Failed to create share'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _expiresAt = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final sharesProvider = context.watch<SharesProvider>();
    final contactsByCategory = contactsProvider.contactsByCategory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Share'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name field
                    AppTextField(
                      label: 'Share Name (Optional)',
                      hint: 'e.g., Business Contacts',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),

                    // Expiry date
                    Text(
                      'Expiry Date (Optional)',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectExpiryDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _expiresAt != null
                                  ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                                  : 'No expiry',
                              style: TextStyle(
                                color: _expiresAt != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                            Row(
                              children: [
                                if (_expiresAt != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() => _expiresAt = null);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                const SizedBox(width: 8),
                                const Icon(Icons.calendar_today, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Select contacts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Contacts',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${_selectedContactIds.length} selected',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Contacts by category
                    ...contactsByCategory.entries.map((entry) {
                      return _buildCategorySection(
                        context,
                        entry.key,
                        entry.value,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: AppButton(
                label: 'Create Share',
                onPressed: _selectedContactIds.isNotEmpty ? _handleCreate : null,
                isLoading: sharesProvider.isLoading,
                isFullWidth: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<Contact> contacts,
  ) {
    final allSelected = contacts.every((c) => _selectedContactIds.contains(c.id));
    final someSelected = contacts.any((c) => _selectedContactIds.contains(c.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Category header with select all
          InkWell(
            onTap: () {
              setState(() {
                if (allSelected) {
                  for (final contact in contacts) {
                    _selectedContactIds.remove(contact.id);
                  }
                } else {
                  for (final contact in contacts) {
                    _selectedContactIds.add(contact.id);
                  }
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    tristate: someSelected && !allSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          for (final contact in contacts) {
                            _selectedContactIds.add(contact.id);
                          }
                        } else {
                          for (final contact in contacts) {
                            _selectedContactIds.remove(contact.id);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    '${contacts.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Contact items
          ...contacts.map((contact) {
            final isSelected = _selectedContactIds.contains(contact.id);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedContactIds.remove(contact.id);
                  } else {
                    _selectedContactIds.add(contact.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedContactIds.add(contact.id);
                          } else {
                            _selectedContactIds.remove(contact.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.label,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            contact.value,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
