import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/p2p_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_indicator.dart';
import 'share_qr_screen.dart';

/// Screen for creating a new P2P share by selecting contacts.
class P2PShareScreen extends StatefulWidget {
  const P2PShareScreen({super.key});

  @override
  State<P2PShareScreen> createState() => _P2PShareScreenState();
}

class _P2PShareScreenState extends State<P2PShareScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedContactIds = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p2pProvider = context.watch<P2PProvider>();
    final contacts = p2pProvider.localContacts;

    // Group contacts by category
    final groupedContacts = <String, List<Contact>>{};
    for (final contact in contacts) {
      final category = contact.type.category;
      groupedContacts.putIfAbsent(category, () => []).add(contact);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create P2P Share'),
        actions: [
          if (_selectedContactIds.isNotEmpty)
            TextButton.icon(
              onPressed: _isCreating ? null : _createShare,
              icon: const Icon(Icons.qr_code),
              label: Text('Create (${_selectedContactIds.length})'),
            ),
        ],
      ),
      body: p2pProvider.isLoading
          ? const LoadingIndicator()
          : contacts.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Share name input
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Share Name (optional)',
                          hintText: 'e.g., Business Contacts',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                      ),
                    ),

                    // Selection header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: AppColors.secondaryLight,
                      child: Row(
                        children: [
                          Text(
                            'Select contacts to share',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _selectAll,
                            child: Text(
                              _selectedContactIds.length == contacts.length
                                  ? 'Deselect All'
                                  : 'Select All',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contacts list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedContacts.keys.length,
                        itemBuilder: (context, index) {
                          final category = groupedContacts.keys.elementAt(index);
                          final categoryContacts = groupedContacts[category]!;
                          return _buildCategorySection(category, categoryContacts);
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _selectedContactIds.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createShare,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Icon(Icons.qr_code),
                  label: Text(
                    _isCreating
                        ? 'Creating...'
                        : 'Generate QR Code (${_selectedContactIds.length} contacts)',
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No local contacts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some contacts in Privacy Mode to create a P2P share.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<Contact> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
          ),
        ),
        ...contacts.map((contact) => _buildContactTile(contact)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildContactTile(Contact contact) {
    final isSelected = _selectedContactIds.contains(contact.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
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
        title: Text(contact.label),
        subtitle: Text(
          contact.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForType(contact.type),
            color: AppColors.primary,
            size: 20,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  IconData _getIconForType(ContactType type) {
    switch (type) {
      case ContactType.email:
      case ContactType.businessEmail:
        return Icons.email_outlined;
      case ContactType.phone:
      case ContactType.businessPhone:
      case ContactType.mobile:
        return Icons.phone_outlined;
      case ContactType.address:
        return Icons.location_on_outlined;
      case ContactType.website:
        return Icons.language;
      case ContactType.company:
        return Icons.business_outlined;
      case ContactType.position:
        return Icons.work_outline;
      case ContactType.birthday:
        return Icons.cake_outlined;
      case ContactType.facebook:
      case ContactType.instagram:
      case ContactType.linkedin:
      case ContactType.twitter:
      case ContactType.tiktok:
      case ContactType.snapchat:
      case ContactType.xing:
        return Icons.people_outline;
      case ContactType.github:
        return Icons.code;
      case ContactType.discord:
      case ContactType.steam:
        return Icons.games_outlined;
      default:
        return Icons.contact_page_outlined;
    }
  }

  void _selectAll() {
    final contacts = context.read<P2PProvider>().localContacts;
    setState(() {
      if (_selectedContactIds.length == contacts.length) {
        _selectedContactIds.clear();
      } else {
        _selectedContactIds.addAll(contacts.map((c) => c.id));
      }
    });
  }

  Future<void> _createShare() async {
    if (_selectedContactIds.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final p2pProvider = context.read<P2PProvider>();

      // Create the share
      final share = await p2pProvider.createShare(
        name: _nameController.text.isEmpty ? null : _nameController.text,
        contactIds: _selectedContactIds.toList(),
      );

      if (share == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                p2pProvider.errorMessage ?? 'Failed to create share',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      // Generate QR data
      final qrData = await p2pProvider.generateQRData(share);

      if (qrData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                p2pProvider.errorMessage ?? 'Failed to generate QR code',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      // Navigate to QR display screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ShareQRScreen(
              share: share,
              qrData: qrData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
