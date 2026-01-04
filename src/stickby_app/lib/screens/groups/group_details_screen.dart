import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/avatar.dart';
import '../../widgets/loading_indicator.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  Group? _group;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    setState(() => _isLoading = true);
    final group = await context.read<GroupsProvider>().getGroupDetails(widget.groupId);
    if (mounted) {
      setState(() {
        _group = group;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group')),
        body: const LoadingIndicator(),
      );
    }

    if (_group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group')),
        body: const Center(child: Text('Group not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with cover image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_group!.name),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: _group!.coverImageUrl != null
                    ? Image.network(
                        _group!.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                      )
                    : _buildCoverPlaceholder(),
              ),
            ),
            actions: [
              if (!_group!.isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'leave') {
                      _confirmLeave();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Leave Group'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Description
                if (_group!.description != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_group!.description!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Members',
                        '${_group!.memberCount}',
                        Icons.people,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Your Role',
                        _group!.myRole.displayName,
                        Icons.badge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Members section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_group!.myRole != GroupMemberRole.member)
                      TextButton.icon(
                        onPressed: _showInviteDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Invite'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_group!.members != null)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _group!.members!.length,
                    itemBuilder: (context, index) {
                      final member = _group!.members![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Avatar(
                            initials: member.displayName.isNotEmpty
                                ? member.displayName[0].toUpperCase()
                                : '?',
                          ),
                          title: Text(member.displayName),
                          subtitle: Text(member.email),
                          trailing: Chip(
                            label: Text(
                              member.role.displayName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Center(
      child: Text(
        _group!.name.isNotEmpty ? _group!.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 64,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter email address',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final success = await context
                    .read<GroupsProvider>()
                    .inviteUser(widget.groupId, emailController.text.trim());
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Invitation sent' : 'Failed to send invitation',
                      ),
                      backgroundColor: success ? AppColors.success : AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${_group!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<GroupsProvider>().leaveGroup(widget.groupId);
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
