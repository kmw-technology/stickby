import 'package:flutter/material.dart';
import '../models/group.dart';
import '../theme/app_theme.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onJoin;
  final VoidCallback? onDecline;

  const GroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.showActions = false,
    this.onJoin,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image or gradient
            Container(
              height: 80,
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
              child: group.coverImageUrl != null
                  ? Image.network(
                      group.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                    )
                  : _buildCoverPlaceholder(),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberCount} members',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (group.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      group.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (showActions && group.isPending) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onDecline,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onJoin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Join'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Center(
      child: Text(
        group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
