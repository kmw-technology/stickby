import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';
import '../../widgets/contact_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    final profile = profileProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: profile != null
                ? () => _navigateToEditProfile(context)
                : null,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const LoadingIndicator()
          : profile == null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Failed to load profile',
                  message: profileProvider.errorMessage,
                )
              : RefreshIndicator(
                  onRefresh: () => profileProvider.loadProfile(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile header
                        Avatar(
                          imageUrl: profile.profileImageUrl,
                          initials: profile.initials,
                          size: AvatarSize.large,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.displayName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            profile.bio!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Contacts by category
                        if (profile.contactsByCategory.isEmpty)
                          const EmptyState(
                            icon: Icons.contacts_outlined,
                            title: 'No contacts',
                            message: 'Add contacts from the Contacts tab',
                          )
                        else
                          ...profile.contactsByCategory.entries.map((entry) {
                            return _buildCategorySection(
                              context,
                              entry.key,
                              entry.value,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List contacts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            category,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...contacts.map((contact) {
          return ContactTile(
            contact: contact,
            showReleaseGroups: true,
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }
}
