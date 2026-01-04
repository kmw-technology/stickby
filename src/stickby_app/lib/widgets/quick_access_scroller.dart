import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A horizontal scrolling section like the legacy "GroupedNotes"
/// Shows items with avatars for quick access
class QuickAccessScroller extends StatelessWidget {
  final String title;
  final List<QuickAccessItem> items;
  final VoidCallback? onSeeAll;

  const QuickAccessScroller({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    child: const Text('See all'),
                  ),
              ],
            ),
          ),
          // Horizontal scroll list
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItem(context, item);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, QuickAccessItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar with badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: item.color ?? AppColors.primaryLight,
                  backgroundImage:
                      item.imageUrl != null ? NetworkImage(item.imageUrl!) : null,
                  child: item.imageUrl == null
                      ? Text(
                          item.initials,
                          style: TextStyle(
                            color: item.color != null
                                ? Colors.white
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        item.badgeCount! > 9 ? '9+' : '${item.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAccessItem {
  final String label;
  final String initials;
  final String? imageUrl;
  final Color? color;
  final int? badgeCount;
  final VoidCallback? onTap;

  const QuickAccessItem({
    required this.label,
    required this.initials,
    this.imageUrl,
    this.color,
    this.badgeCount,
    this.onTap,
  });
}
