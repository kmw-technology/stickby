import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../theme/app_theme.dart';
import 'avatar.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showReleaseGroups;

  const ContactTile({
    super.key,
    required this.contact,
    this.onTap,
    this.onDelete,
    this.showReleaseGroups = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: _buildLeading(),
        title: Text(contact.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (showReleaseGroups) ...[
              const SizedBox(height: 4),
              _buildReleaseGroupBadges(),
            ],
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.danger,
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }

  Widget _buildLeading() {
    // Show owner photo if available (contacts from other people)
    if (contact.ownerImageUrl != null && contact.ownerImageUrl!.isNotEmpty) {
      return Avatar(
        imageUrl: contact.ownerImageUrl,
        initials: contact.ownerName?.isNotEmpty == true
            ? contact.ownerName!.split(' ').map((n) => n[0]).take(2).join()
            : contact.label[0].toUpperCase(),
        size: AvatarSize.small,
      );
    }

    // Default: show icon based on contact type
    return Container(
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
    );
  }

  Widget _buildReleaseGroupBadges() {
    final labels = ReleaseGroup.getLabels(contact.releaseGroups);
    if (labels.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      children: labels.map((label) {
        Color badgeColor;
        String shortLabel;

        switch (label) {
          case 'Family':
            badgeColor = AppColors.familyBadge;
            shortLabel = 'F';
            break;
          case 'Friends':
            badgeColor = AppColors.friendsBadge;
            shortLabel = 'Fr';
            break;
          case 'Business':
            badgeColor = AppColors.businessBadge;
            shortLabel = 'B';
            break;
          case 'Leisure':
            badgeColor = AppColors.leisureBadge;
            shortLabel = 'L';
            break;
          default:
            badgeColor = AppColors.secondary;
            shortLabel = label[0];
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            shortLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        );
      }).toList(),
    );
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
      case ContactType.website:
        return Icons.language_outlined;
      case ContactType.birthday:
        return Icons.cake_outlined;
      case ContactType.company:
        return Icons.business_outlined;
      case ContactType.position:
        return Icons.work_outline;
      case ContactType.facebook:
        return Icons.facebook_outlined;
      case ContactType.instagram:
      case ContactType.twitter:
      case ContactType.tiktok:
      case ContactType.snapchat:
        return Icons.camera_alt_outlined;
      case ContactType.linkedin:
      case ContactType.xing:
        return Icons.work_outline;
      case ContactType.github:
        return Icons.code_outlined;
      case ContactType.discord:
      case ContactType.steam:
        return Icons.sports_esports_outlined;
      case ContactType.emergencyContact:
        return Icons.emergency_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
