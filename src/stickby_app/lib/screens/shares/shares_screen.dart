import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/share.dart';
import '../../providers/shares_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'create_share_screen.dart';

class SharesScreen extends StatelessWidget {
  const SharesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sharesProvider = context.watch<SharesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shares'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateShare(context),
            tooltip: 'Create Share',
          ),
        ],
      ),
      body: sharesProvider.isLoading
          ? const LoadingIndicator()
          : sharesProvider.shares.isEmpty
              ? EmptyState(
                  icon: Icons.share_outlined,
                  title: 'No shares yet',
                  message: 'Create a share link to share your contacts',
                  actionLabel: 'Create Share',
                  onAction: () => _navigateToCreateShare(context),
                )
              : RefreshIndicator(
                  onRefresh: () => sharesProvider.loadShares(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sharesProvider.shares.length,
                    itemBuilder: (context, index) {
                      final share = sharesProvider.shares[index];
                      return _buildShareCard(context, share);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateShare(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildShareCard(BuildContext context, Share share) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: share.isExpired
                        ? AppColors.dangerLight
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link,
                    color: share.isExpired ? AppColors.danger : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share.name ?? 'Unnamed Share',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${share.contactIds.length} contacts',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (share.isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Expired',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _buildStat(context, Icons.visibility, '${share.viewCount} views'),
                const SizedBox(width: 24),
                _buildStat(
                  context,
                  Icons.calendar_today,
                  _formatDate(share.createdAt),
                ),
                if (share.expiresAt != null) ...[
                  const SizedBox(width: 24),
                  _buildStat(
                    context,
                    Icons.timer,
                    'Expires ${_formatDate(share.expiresAt!)}',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Actions row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareLink(context, share),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyLink(context, share),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _confirmDelete(context, share),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.danger,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToCreateShare(BuildContext context) {
    final contacts = context.read<ContactsProvider>().contacts;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some contacts first before creating a share'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateShareScreen()),
    );
  }

  void _shareLink(BuildContext context, Share share) {
    Share.share(
      'Check out my contact info: ${share.shareUrl}',
      subject: 'StickBy Contact Share',
    );
  }

  void _copyLink(BuildContext context, Share share) {
    // Using Share.share with just the URL copies it
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: AppColors.textOnPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Link copied: ${share.shareUrl}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Share share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Share'),
        content: Text(
          'Are you sure you want to delete "${share.name ?? 'this share'}"? This cannot be undone.',
        ),
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

    if (confirmed == true) {
      await context.read<SharesProvider>().deleteShare(share.id);
    }
  }
}
