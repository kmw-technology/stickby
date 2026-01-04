import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/contact_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _searchQuery = '';
  final _expandedCategories = <String>{};

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final contactsByCategory = contactsProvider.contactsByCategory;

    // Filter contacts by search query
    final filteredCategories = <String, List<Contact>>{};
    for (final entry in contactsByCategory.entries) {
      final filtered = entry.value.where((contact) {
        final query = _searchQuery.toLowerCase();
        return contact.label.toLowerCase().contains(query) ||
            contact.value.toLowerCase().contains(query);
      }).toList();
      if (filtered.isNotEmpty) {
        filteredCategories[entry.key] = filtered;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddContact(context),
            tooltip: 'Add Contact',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),

          // Contacts list
          Expanded(
            child: contactsProvider.isLoading
                ? const LoadingIndicator()
                : contactsProvider.contacts.isEmpty
                    ? EmptyState(
                        icon: Icons.contacts_outlined,
                        title: 'No contacts yet',
                        message: 'Add your first contact to get started',
                        actionLabel: 'Add Contact',
                        onAction: () => _navigateToAddContact(context),
                      )
                    : filteredCategories.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off,
                            title: 'No results',
                            message: 'No contacts match your search',
                          )
                        : RefreshIndicator(
                            onRefresh: () => contactsProvider.loadContacts(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = filteredCategories.keys.elementAt(index);
                                final contacts = filteredCategories[category]!;
                                final isExpanded = _expandedCategories.contains(category);

                                return _buildCategorySection(
                                  context,
                                  category,
                                  contacts,
                                  isExpanded,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddContact(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<Contact> contacts,
    bool isExpanded,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Category header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove(category);
                } else {
                  _expandedCategories.add(category);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconForCategory(category),
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${contacts.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Contacts list
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: contacts.map((contact) {
                  return ContactTile(
                    contact: contact,
                    onTap: () => _showContactDetails(context, contact),
                    onDelete: () => _confirmDelete(context, contact),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'General':
        return Icons.info_outline;
      case 'Personal':
        return Icons.person_outline;
      case 'Private':
        return Icons.lock_outline;
      case 'Business':
        return Icons.business_outlined;
      case 'Social':
        return Icons.public_outlined;
      case 'Gaming':
        return Icons.sports_esports_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  void _navigateToAddContact(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddContactScreen()),
    );
  }

  void _showContactDetails(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(contact.type),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        contact.type.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Value',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              contact.value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Visible to',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: ReleaseGroup.getLabels(contact.releaseGroups)
                  .map((label) => Chip(label: Text(label)))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(ContactType type) {
    switch (type) {
      case ContactType.email:
      case ContactType.businessEmail:
        return Icons.email_outlined;
      case ContactType.phone:
      case ContactType.mobile:
      case ContactType.businessPhone:
        return Icons.phone_outlined;
      case ContactType.address:
        return Icons.location_on_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Future<void> _confirmDelete(BuildContext context, Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete "${contact.label}"?'),
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
      await context.read<ContactsProvider>().deleteContact(contact.id);
    }
  }
}
