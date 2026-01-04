import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Activity card with avatar, time indicator, and action icons
/// Similar to legacy ContactNote pattern
class ActivityCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String timeAgo;
  final String? imageUrl;
  final String initials;
  final List<ActivityIcon> actionIcons;
  final ActivityType type;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ActivityCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.timeAgo,
    this.imageUrl,
    required this.initials,
    this.actionIcons = const [],
    this.type = ActivityType.update,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with title and time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (actionIcons.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildActionIcons(context),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(height: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _getTypeColor().withOpacity(0.15),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  initials,
                  style: TextStyle(
                    color: _getTypeColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
        // Type indicator
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _getTypeColor(),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              _getTypeIcon(),
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getActionLabel(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(width: 8),
          ...actionIcons.map((icon) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  icon.icon,
                  size: 18,
                  color: icon.color ?? AppColors.textSecondary,
                ),
              )),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (type) {
      case ActivityType.share:
        return AppColors.success;
      case ActivityType.update:
        return AppColors.primary;
      case ActivityType.request:
        return AppColors.warning;
      case ActivityType.group:
        return AppColors.secondary;
      case ActivityType.view:
        return AppColors.info;
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case ActivityType.share:
        return Icons.share;
      case ActivityType.update:
        return Icons.edit;
      case ActivityType.request:
        return Icons.person_add;
      case ActivityType.group:
        return Icons.group;
      case ActivityType.view:
        return Icons.visibility;
    }
  }

  String _getActionLabel() {
    switch (type) {
      case ActivityType.share:
        return 'Shared:';
      case ActivityType.update:
        return 'Updated:';
      case ActivityType.request:
        return 'Requesting:';
      case ActivityType.group:
        return 'Group:';
      case ActivityType.view:
        return 'Viewed:';
    }
  }
}

enum ActivityType {
  share,
  update,
  request,
  group,
  view,
}

class ActivityIcon {
  final IconData icon;
  final Color? color;

  const ActivityIcon({
    required this.icon,
    this.color,
  });

  // Predefined icons for common contact types
  static const phone = ActivityIcon(icon: Icons.phone);
  static const email = ActivityIcon(icon: Icons.email);
  static const location = ActivityIcon(icon: Icons.location_on);
  static const instagram = ActivityIcon(icon: Icons.camera_alt);
  static const linkedin = ActivityIcon(icon: Icons.work);
  static const website = ActivityIcon(icon: Icons.language);
  static const birthday = ActivityIcon(icon: Icons.cake);
}
