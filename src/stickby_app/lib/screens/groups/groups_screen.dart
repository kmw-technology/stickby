import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/group_card.dart';
import '../../widgets/loading_indicator.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupsProvider = context.watch<GroupsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateGroup(context),
            tooltip: 'Create Group',
          ),
        ],
      ),
      body: groupsProvider.isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  groupsProvider.loadGroups(),
                  groupsProvider.loadInvitations(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pending invitations
                    if (groupsProvider.invitations.isNotEmpty) ...[
                      Text(
                        'Pending Invitations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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

                    // My groups
                    Text(
                      'My Groups',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (groupsProvider.groups.isEmpty)
                      EmptyState(
                        icon: Icons.group_outlined,
                        title: 'No groups yet',
                        message: 'Create or join a group to collaborate with others',
                        actionLabel: 'Create Group',
                        onAction: () => _navigateToCreateGroup(context),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: groupsProvider.groups.length,
                        itemBuilder: (context, index) {
                          final group = groupsProvider.groups[index];
                          return GroupCard(
                            group: group,
                            onTap: () => _navigateToGroupDetails(context, group.id),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateGroup(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateGroup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
  }

  void _navigateToGroupDetails(BuildContext context, String groupId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(groupId: groupId),
      ),
    );
  }
}
