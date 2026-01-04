import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/shares_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/group_card.dart';
import '../../widgets/loading_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final groupsProvider = context.watch<GroupsProvider>();
    final sharesProvider = context.watch<SharesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.share_outlined, color: AppColors.primary),
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
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Welcome back, ${authProvider.user?.displayName ?? 'User'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // Pending Invitations Section
              if (groupsProvider.invitations.isNotEmpty) ...[
                _buildSectionHeader(context, 'Pending Invitations'),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groupsProvider.invitations.length,
                  itemBuilder: (context, index) {
                    final group = groupsProvider.invitations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GroupCard(
                        group: group,
                        showActions: true,
                        onJoin: () => groupsProvider.joinGroup(group.id),
                        onDecline: () => groupsProvider.declineGroup(group.id),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Activity Summary
              _buildSectionHeader(context, 'Your Activity'),
              const SizedBox(height: 12),
              _buildStatsCards(context, sharesProvider, groupsProvider),

              const SizedBox(height: 24),

              // Recent Shares
              _buildSectionHeader(context, 'Recent Shares'),
              const SizedBox(height: 12),
              if (sharesProvider.isLoading)
                const Center(child: LoadingIndicator())
              else if (sharesProvider.shares.isEmpty)
                _buildEmptyState(
                  context,
                  'No shares yet',
                  'Create a share to start sharing your contacts',
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sharesProvider.recentShares.length,
                  itemBuilder: (context, index) {
                    final share = sharesProvider.recentShares[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.link,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(share.name ?? 'Unnamed Share'),
                        subtitle: Text(
                          '${share.contactIds.length} contacts • ${share.viewCount} views',
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
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
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.share,
            label: 'Total Shares',
            value: '${sharesProvider.shares.length}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.visibility,
            label: 'Total Views',
            value: '${sharesProvider.totalViewCount}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.group,
            label: 'Groups',
            value: '${groupsProvider.groups.length}',
            color: AppColors.secondary,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
