import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/groups_provider.dart';
import '../../services/search_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/contact_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/slide_page_route.dart';
import 'add_contact_screen.dart';
import 'assign_groups_screen.dart';
import 'edit_contact_screen.dart';
import 'requests_screen.dart';
import 'scan_card_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();
  final _searchService = SearchService();
  String _searchQuery = '';
  String? _selectedCategory;
  final _expandedCategories = <String>{};
  Timer? _debounceTimer;
  List<SearchResult>? _searchResults;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value;
        _updateSearchResults();
      });
    });
  }

  void _updateSearchResults() {
    final contacts = context.read<ContactsProvider>().contacts;
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      _searchResults = null;
    } else if (_searchQuery.isNotEmpty) {
      _searchResults = _searchService.search(_searchQuery, contacts);
    } else {
      // Category filter only
      _searchResults = contacts
          .where((c) => c.type.category == _selectedCategory)
          .map((c) => SearchResult(
                contact: c,
                relevanceScore: 1.0,
                matchedField: 'category',
              ))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final groupsProvider = context.watch<GroupsProvider>();
    final contactsByCategory = contactsProvider.contactsByCategory;
    final pendingCount = groupsProvider.pendingInvitationsCount;

    // Use search results if available, otherwise show by category
    final showSearchResults = _searchResults != null;

    // Filter contacts by category if no search
    Map<String, List<Contact>> filteredCategories = {};
    if (!showSearchResults) {
      if (_selectedCategory != null) {
        final categoryContacts = contactsByCategory[_selectedCategory];
        if (categoryContacts != null && categoryContacts.isNotEmpty) {
          filteredCategories[_selectedCategory!] = categoryContacts;
        }
      } else {
        filteredCategories = contactsByCategory;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          // Business card scanner
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () => _navigateToScanCard(context),
            tooltip: 'Scan Business Card',
          ),
          // Requests button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline),
                onPressed: () => _navigateToRequests(context),
                tooltip: 'Requests',
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      pendingCount > 9 ? '9+' : '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () => _navigateToAssignGroups(context),
            tooltip: 'Assign Groups',
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search contacts... (try "@", "social", "business")',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = null;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(null, 'All'),
                _buildCategoryChip('General', 'General'),
                _buildCategoryChip('Personal', 'Personal'),
                _buildCategoryChip('Private', 'Private'),
                _buildCategoryChip('Business', 'Business'),
                _buildCategoryChip('Social', 'Social'),
                _buildCategoryChip('Gaming', 'Gaming'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Contacts list
          Expanded(
            child: contactsProvider.isLoading
                ? const LoadingIndicator()
                : contactsProvider.contacts.isEmpty
                    ? EmptyState(
                        icon: Icons.contacts_outlined,
                        title: 'No contacts yet',
                        message: 'Add your first contact or scan a business card',
                        actionLabel: 'Scan Card',
                        onAction: () => _navigateToScanCard(context),
                      )
                    : showSearchResults
                        ? _buildSearchResults()
                        : filteredCategories.isEmpty
                            ? EmptyState(
                                icon: Icons.search_off,
                                title: 'No results',
                                message: 'No contacts match your filter',
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

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
            _updateSearchResults();
          });
        },
        selectedColor: AppColors.primaryLight,
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _searchResults!;

    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No results',
        message: 'No contacts match "$_searchQuery"',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ContactsProvider>().loadContacts();
        _updateSearchResults();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return _buildSearchResultCard(result);
        },
      ),
    );
  }

  Widget _buildSearchResultCard(SearchResult result) {
    final contact = result.contact;
    final relevance = result.relevanceScore;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showContactDetails(context, contact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Type icon
              Container(
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
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.label,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        // Relevance indicator
                        _buildRelevanceBadge(relevance),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${contact.type.category} • ${contact.type.displayName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, contact),
                color: AppColors.textMuted,
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelevanceBadge(double relevance) {
    final Color color;
    final String label;

    if (relevance >= 0.9) {
      color = AppColors.success;
      label = 'Exact';
    } else if (relevance >= 0.7) {
      color = AppColors.primary;
      label = 'High';
    } else {
      color = AppColors.warning;
      label = 'Partial';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
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
      SlidePageRoute(page: const AddContactScreen(), direction: SlideDirection.up),
    );
  }

  void _navigateToScanCard(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      SlidePageRoute(page: const ScanCardScreen(), direction: SlideDirection.up),
    );
    if (result == true && mounted) {
      context.read<ContactsProvider>().loadContacts();
    }
  }

  void _navigateToRequests(BuildContext context) {
    Navigator.of(context).push(
      SlidePageRoute(page: const RequestsScreen(), direction: SlideDirection.right),
    );
  }

  void _navigateToAssignGroups(BuildContext context) {
    Navigator.of(context).push(
      SlidePageRoute(page: const AssignGroupsScreen(), direction: SlideDirection.right),
    );
  }

  void _showContactDetails(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
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
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      Text(
                        contact.type.displayName,
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _navigateToEditContact(context, contact);
                  },
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Value',
              style: Theme.of(ctx).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              contact.value,
              style: Theme.of(ctx).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Visible to',
              style: Theme.of(ctx).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: ReleaseGroup.getLabels(contact.releaseGroups)
                  .map((label) => Chip(label: Text(label)))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Contact'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _navigateToEditContact(context, contact);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditContact(BuildContext context, Contact contact) async {
    final result = await Navigator.of(context).push<bool>(
      SlidePageRoute(page: EditContactScreen(contact: contact), direction: SlideDirection.right),
    );
    if (result == true && mounted) {
      context.read<ContactsProvider>().loadContacts();
    }
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
