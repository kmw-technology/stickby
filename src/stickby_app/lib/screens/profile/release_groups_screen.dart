import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_indicator.dart';

class ReleaseGroupsScreen extends StatefulWidget {
  const ReleaseGroupsScreen({super.key});

  @override
  State<ReleaseGroupsScreen> createState() => _ReleaseGroupsScreenState();
}

class _ReleaseGroupsScreenState extends State<ReleaseGroupsScreen> {
  final Map<String, int> _pendingChanges = {};
  bool _isSaving = false;
  final _expandedCategories = <String>{};

  @override
  void initState() {
    super.initState();
    // Expand all categories by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contactsProvider = context.read<ContactsProvider>();
      setState(() {
        _expandedCategories.addAll(contactsProvider.contactsByCategory.keys);
      });
    });
  }

  int _getReleaseGroups(Contact contact) {
    return _pendingChanges[contact.id] ?? contact.releaseGroups;
  }

  void _toggleReleaseGroup(Contact contact, int group) {
    final currentGroups = _getReleaseGroups(contact);
    final newGroups = (currentGroups & group) != 0
        ? currentGroups & ~group
        : currentGroups | group;
    setState(() {
      _pendingChanges[contact.id] = newGroups;
    });
  }

  Future<void> _saveChanges() async {
    if (_pendingChanges.isEmpty) return;

    setState(() => _isSaving = true);

    final profileProvider = context.read<ProfileProvider>();
    final updates = _pendingChanges.entries
        .map((e) => {'contactId': e.key, 'releaseGroups': e.value})
        .toList();

    final success = await profileProvider.updateReleaseGroups(updates);

    setState(() => _isSaving = false);

    if (success && mounted) {
      await context.read<ContactsProvider>().loadContacts();
      setState(() => _pendingChanges.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Release groups updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.errorMessage ?? 'Failed to save changes'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final contactsByCategory = contactsProvider.contactsByCategory;
    final hasChanges = _pendingChanges.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Release Groups'),
      ),
      body: Column(
        children: [
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control who can see each contact',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildLegendItem('F', 'Family', AppColors.familyBadge),
                    _buildLegendItem('Fr', 'Friends', AppColors.friendsBadge),
                    _buildLegendItem('B', 'Business', AppColors.businessBadge),
                    _buildLegendItem('L', 'Leisure', AppColors.leisureBadge),
                  ],
                ),
              ],
            ),
          ),

          // Contacts list
          Expanded(
            child: contactsProvider.isLoading
                ? const LoadingIndicator()
                : contactsProvider.contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contacts_outlined,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No contacts yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add contacts first to manage release groups',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => contactsProvider.loadContacts(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: contactsByCategory.length,
                          itemBuilder: (context, index) {
                            final category = contactsByCategory.keys.elementAt(index);
                            final contacts = contactsByCategory[category]!;
                            final isExpanded = _expandedCategories.contains(category);

                            return _buildCategorySection(category, contacts, isExpanded);
                          },
                        ),
                      ),
          ),

          // Save button
          if (hasChanges)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: AppButton(
                  label: 'Save Changes (${_pendingChanges.length})',
                  onPressed: _saveChanges,
                  isLoading: _isSaving,
                  isFullWidth: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String abbr, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              abbr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<Contact> contacts, bool isExpanded) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
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
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: contacts.map((contact) => _buildContactItem(contact)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    final releaseGroups = _getReleaseGroups(contact);
    final hasChanged = _pendingChanges.containsKey(contact.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasChanged ? AppColors.primaryLight.withOpacity(0.3) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: hasChanged ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _buildToggleButton('F', ReleaseGroup.family, releaseGroups, contact, AppColors.familyBadge),
              const SizedBox(width: 4),
              _buildToggleButton('Fr', ReleaseGroup.friends, releaseGroups, contact, AppColors.friendsBadge),
              const SizedBox(width: 4),
              _buildToggleButton('B', ReleaseGroup.business, releaseGroups, contact, AppColors.businessBadge),
              const SizedBox(width: 4),
              _buildToggleButton('L', ReleaseGroup.leisure, releaseGroups, contact, AppColors.leisureBadge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, int group, int currentGroups, Contact contact, Color activeColor) {
    final isActive = (currentGroups & group) != 0;

    return GestureDetector(
      onTap: () => _toggleReleaseGroup(contact, group),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive ? activeColor : AppColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? activeColor : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
