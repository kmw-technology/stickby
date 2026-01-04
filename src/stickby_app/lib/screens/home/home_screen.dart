import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../models/share.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/insights_provider.dart';
import '../../providers/shares_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/dismissible_card.dart';
import '../../widgets/insights_widget.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/quick_access_scroller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final groupsProvider = context.watch<GroupsProvider>();
    final sharesProvider = context.watch<SharesProvider>();
    final contactsProvider = context.watch<ContactsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/stickby_logo.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 8),
            Text(
              'StickBy',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            groupsProvider.loadInvitations(),
            sharesProvider.loadShares(),
            contactsProvider.loadContacts(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card for new users (dismissible)
              if (contactsProvider.contacts.isEmpty)
                WelcomeCard(
                  userName: authProvider.user?.displayName ?? 'User',
                  onGetStarted: () {
                    // Navigate to contacts tab - handled by parent
                  },
                ),

              // Tip card when user has contacts but no shares
              if (contactsProvider.contacts.isNotEmpty && sharesProvider.shares.isEmpty)
                const TipCard(
                  tip: 'Create your first share to start sharing your contacts with others via QR code or link.',
                ),

              // Welcome message
              Text(
                'Welcome back, ${authProvider.user?.displayName ?? 'User'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // Quick Access - Recent Contacts (horizontal scroller)
              if (contactsProvider.contacts.isNotEmpty) ...[
                _buildRecentContactsScroller(context, contactsProvider),
                const SizedBox(height: 16),
              ],

              // Quick Access - Pending Group Invitations (horizontal scroller)
              if (groupsProvider.invitations.isNotEmpty) ...[
                _buildInvitationsScroller(context, groupsProvider),
                const SizedBox(height: 16),
              ],

              // Activity Summary
              _buildSectionHeader(context, 'Your Activity'),
              const SizedBox(height: 12),
              _buildStatsCards(context, sharesProvider, groupsProvider, contactsProvider),
              const SizedBox(height: 24),

              // Discover Insights (commonalities)
              if (contactsProvider.contacts.length >= 2) ...[
                const InsightsWidget(),
                const SizedBox(height: 24),
              ],

              // Recent Activity Feed with enhanced cards
              _buildSectionHeader(context, 'Recent Activity'),
              const SizedBox(height: 12),
              if (sharesProvider.isLoading)
                const Center(child: LoadingIndicator())
              else if (sharesProvider.shares.isEmpty)
                _buildEmptyState(
                  context,
                  'No activity yet',
                  'Create a share to start sharing your contacts',
                )
              else
                _buildEnhancedActivityFeed(context, sharesProvider, contactsProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentContactsScroller(BuildContext context, ContactsProvider contactsProvider) {
    // Get unique contacts by label, take first 10
    final recentContacts = contactsProvider.contacts.take(10).toList();

    return QuickAccessScroller(
      title: 'Your Contacts',
      items: recentContacts.map((contact) {
        return QuickAccessItem(
          label: contact.label,
          initials: _getInitials(contact.label),
          color: _getContactTypeColor(contact.type.value),
          onTap: () {
            // Navigate to contact details or contacts tab
          },
        );
      }).toList(),
    );
  }

  Widget _buildInvitationsScroller(BuildContext context, GroupsProvider groupsProvider) {
    return QuickAccessScroller(
      title: 'Pending Invitations',
      items: groupsProvider.invitations.map((group) {
        return QuickAccessItem(
          label: group.name,
          initials: _getInitials(group.name),
          color: AppColors.warning,
          badgeCount: 1,
          onTap: () {
            _showInvitationDialog(context, group, groupsProvider);
          },
        );
      }).toList(),
    );
  }

  void _showInvitationDialog(BuildContext context, group, GroupsProvider groupsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${group.name}?'),
        content: Text(group.description ?? 'You have been invited to join this group.'),
        actions: [
          TextButton(
            onPressed: () {
              groupsProvider.declineGroup(group.id);
              Navigator.pop(context);
            },
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () {
              groupsProvider.joinGroup(group.id);
              Navigator.pop(context);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    SharesProvider sharesProvider,
    GroupsProvider groupsProvider,
    ContactsProvider contactsProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.contact_phone,
            label: 'Contacts',
            value: '${contactsProvider.contacts.length}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.share,
            label: 'Shares',
            value: '${sharesProvider.shares.length}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.visibility,
            label: 'Views',
            value: '${sharesProvider.totalViewCount}',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActivityFeed(
    BuildContext context,
    SharesProvider sharesProvider,
    ContactsProvider contactsProvider,
  ) {
    final recentShares = sharesProvider.recentShares;

    return Column(
      children: recentShares.map((share) {
        return _buildEnhancedActivityItem(context, share, contactsProvider);
      }).toList(),
    );
  }

  Widget _buildEnhancedActivityItem(
    BuildContext context,
    Share share,
    ContactsProvider contactsProvider,
  ) {
    // Get shared contact types to show as icons
    final sharedContacts = share.contactIds
        .map((id) => contactsProvider.contacts.where((c) => c.id == id).firstOrNull)
        .where((c) => c != null)
        .cast<Contact>()
        .toList();

    // Build action icons based on contact types
    final actionIcons = _getActionIconsForContacts(sharedContacts);

    // Get initials from share name or first contact
    final initials = share.name != null
        ? _getInitials(share.name!)
        : (sharedContacts.isNotEmpty ? _getInitials(sharedContacts.first.label) : 'SH');

    // Determine activity type
    ActivityType type;
    if (share.viewCount > 0) {
      type = ActivityType.view;
    } else {
      type = ActivityType.share;
    }

    return ActivityCard(
      title: share.name ?? 'Shared Contacts',
      subtitle: _buildShareSubtitle(sharedContacts),
      timeAgo: _getRelativeTime(share.createdAt),
      initials: initials,
      type: type,
      actionIcons: actionIcons,
      trailing: _buildShareStats(context, share),
      onTap: () {
        // Navigate to share details
      },
    );
  }

  String _buildShareSubtitle(List<Contact> contacts) {
    if (contacts.isEmpty) return 'No contacts';
    if (contacts.length == 1) return contacts.first.label;
    if (contacts.length == 2) return '${contacts[0].label} and ${contacts[1].label}';
    return '${contacts[0].label}, ${contacts[1].label} +${contacts.length - 2} more';
  }

  List<ActivityIcon> _getActionIconsForContacts(List<Contact> contacts) {
    final icons = <ActivityIcon>[];
    final seenTypes = <int>{};

    for (final contact in contacts) {
      if (seenTypes.contains(contact.type.value)) continue;
      seenTypes.add(contact.type.value);

      final icon = _getIconForContactType(contact.type.value);
      if (icon != null) {
        icons.add(icon);
      }

      if (icons.length >= 4) break; // Max 4 icons
    }

    return icons;
  }

  ActivityIcon? _getIconForContactType(int type) {
    // Based on ContactType enum categories
    if (type == 0) return ActivityIcon.email; // Email
    if (type == 1) return ActivityIcon.phone; // Phone
    if (type == 2) return ActivityIcon.location; // Address
    if (type == 3) return ActivityIcon.website; // Website
    if (type >= 100 && type < 200) return ActivityIcon.birthday; // Personal
    if (type >= 200 && type < 300) return ActivityIcon.phone; // Private
    if (type >= 300 && type < 400) return ActivityIcon.linkedin; // Business
    if (type >= 400 && type < 500) return ActivityIcon.instagram; // Social
    return null;
  }

  Widget _buildShareStats(BuildContext context, Share share) {
    return Row(
      children: [
        _buildMiniStat(context, Icons.visibility, '${share.viewCount}', AppColors.success),
        const SizedBox(width: 12),
        _buildMiniStat(context, Icons.people, '${share.contactIds.length}', AppColors.primary),
        const Spacer(),
        if (share.isExpired)
          _buildStatusChip('Expired', AppColors.danger)
        else if (share.viewCount > 0)
          _buildStatusChip('Viewed', AppColors.success)
        else
          _buildStatusChip('Pending', AppColors.warning),
      ],
    );
  }

  Widget _buildMiniStat(BuildContext context, IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getContactTypeColor(int type) {
    if (type >= 0 && type < 100) return AppColors.primary; // General
    if (type >= 100 && type < 200) return AppColors.familyBadge; // Personal
    if (type >= 200 && type < 300) return AppColors.friendsBadge; // Private
    if (type >= 300 && type < 400) return AppColors.businessBadge; // Business
    if (type >= 400 && type < 500) return AppColors.leisureBadge; // Social
    return AppColors.secondary;
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? 'Yesterday' : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1 hr ago' : '${difference.inHours} hrs ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildEmptyState(BuildContext context, String title, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
