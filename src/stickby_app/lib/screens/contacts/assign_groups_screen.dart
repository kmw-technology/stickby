import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_indicator.dart';

class AssignGroupsScreen extends StatefulWidget {
  const AssignGroupsScreen({super.key});

  @override
  State<AssignGroupsScreen> createState() => _AssignGroupsScreenState();
}

class _AssignGroupsScreenState extends State<AssignGroupsScreen> {
  final Set<String> _selectedContactIds = {};
  int _targetGroup = ReleaseGroup.family;
  bool _isAddAction = true;
  bool _isSaving = false;

  void _toggleContact(String contactId) {
    setState(() {
      if (_selectedContactIds.contains(contactId)) {
        _selectedContactIds.remove(contactId);
      } else {
        _selectedContactIds.add(contactId);
      }
    });
  }

  void _selectAll(List<Contact> contacts) {
    setState(() {
      _selectedContactIds.addAll(contacts.map((c) => c.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedContactIds.clear();
    });
  }

  Future<void> _applyChanges() async {
    if (_selectedContactIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one contact'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final contactsProvider = context.read<ContactsProvider>();
    final profileProvider = context.read<ProfileProvider>();

    // Calculate new release groups for each selected contact
    final updates = <Map<String, dynamic>>[];
    for (final contactId in _selectedContactIds) {
      final contact = contactsProvider.contacts.firstWhere((c) => c.id == contactId);
      int newGroups;
      if (_isAddAction) {
        newGroups = contact.releaseGroups | _targetGroup;
      } else {
        newGroups = contact.releaseGroups & ~_targetGroup;
      }
      updates.add({'contactId': contactId, 'releaseGroups': newGroups});
    }

    final success = await profileProvider.updateReleaseGroups(updates);

    setState(() => _isSaving = false);

    if (success && mounted) {
      await contactsProvider.loadContacts();
      final actionText = _isAddAction ? 'added to' : 'removed from';
      final groupName = _getGroupName(_targetGroup);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedContactIds.length} contacts $actionText $groupName'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _selectedContactIds.clear());
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.errorMessage ?? 'Failed to apply changes'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _getGroupName(int group) {
    switch (group) {
      case ReleaseGroup.family:
        return 'Family';
      case ReleaseGroup.friends:
        return 'Friends';
      case ReleaseGroup.business:
        return 'Business';
      case ReleaseGroup.leisure:
        return 'Leisure';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final contacts = contactsProvider.contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Contacts'),
      ),
      body: Column(
        children: [
          // Action controls
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
                  'Assign multiple contacts to a group at once',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Action toggle
                Row(
                  children: [
                    Text('Action:', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Add to group'),
                      selected: _isAddAction,
                      onSelected: (selected) {
                        if (selected) setState(() => _isAddAction = true);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Remove from group'),
                      selected: !_isAddAction,
                      onSelected: (selected) {
                        if (selected) setState(() => _isAddAction = false);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Target group
                Row(
                  children: [
                    Text('Target:', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildGroupChip('Family', ReleaseGroup.family, AppColors.familyBadge),
                            const SizedBox(width: 8),
                            _buildGroupChip('Friends', ReleaseGroup.friends, AppColors.friendsBadge),
                            const SizedBox(width: 8),
                            _buildGroupChip('Business', ReleaseGroup.business, AppColors.businessBadge),
                            const SizedBox(width: 8),
                            _buildGroupChip('Leisure', ReleaseGroup.leisure, AppColors.leisureBadge),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Selection actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => _selectAll(contacts),
                  child: const Text('Select all'),
                ),
                TextButton(
                  onPressed: _deselectAll,
                  child: const Text('Deselect all'),
                ),
                const Spacer(),
                Text(
                  '${_selectedContactIds.length} selected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Contacts list
          Expanded(
            child: contactsProvider.isLoading
                ? const LoadingIndicator()
                : contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.contacts_outlined, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text('No contacts yet', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          final isSelected = _selectedContactIds.contains(contact.id);

                          return _buildContactItem(contact, isSelected);
                        },
                      ),
          ),

          // Apply button
          if (_selectedContactIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: SafeArea(
                child: AppButton(
                  label: 'Apply to ${_selectedContactIds.length} contacts',
                  onPressed: _applyChanges,
                  isLoading: _isSaving,
                  isFullWidth: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupChip(String label, int group, Color color) {
    final isSelected = _targetGroup == group;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _targetGroup = group);
      },
    );
  }

  Widget _buildContactItem(Contact contact, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => _toggleContact(contact.id),
        title: Text(contact.label),
        subtitle: Text(
          contact.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        secondary: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((contact.releaseGroups & ReleaseGroup.family) != 0)
              _buildBadge('F', AppColors.familyBadge),
            if ((contact.releaseGroups & ReleaseGroup.friends) != 0)
              _buildBadge('Fr', AppColors.friendsBadge),
            if ((contact.releaseGroups & ReleaseGroup.business) != 0)
              _buildBadge('B', AppColors.businessBadge),
            if ((contact.releaseGroups & ReleaseGroup.leisure) != 0)
              _buildBadge('L', AppColors.leisureBadge),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
