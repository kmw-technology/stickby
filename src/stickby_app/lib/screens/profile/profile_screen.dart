import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/demo_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';
import '../../widgets/contact_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'edit_profile_screen.dart';
import 'release_groups_screen.dart';
import '../settings/connect_web_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    final demoProvider = context.watch<DemoProvider>();
    final profile = profileProvider.profile;
    final isDemo = demoProvider.isDemoMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDemo ? 'Profile (Demo)' : 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: profile != null
                ? () => _navigateToEditProfile(context)
                : null,
            tooltip: 'Edit Profile',
          ),
          if (isDemo)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _showExitDemoDialog(context),
              tooltip: 'Exit Demo Mode',
            )
          else
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
                        const SizedBox(height: 24),

                        // Action buttons
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.tune),
                              label: const Text('Release Groups'),
                              onPressed: () => _navigateToReleaseGroups(context),
                            ),
                            if (!isDemo)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Web verbinden'),
                                onPressed: () => _navigateToConnectWeb(context),
                              ),
                          ],
                        ),
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

  void _navigateToReleaseGroups(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReleaseGroupsScreen()),
    );
  }

  void _navigateToConnectWeb(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConnectWebScreen()),
    );
  }

  void _showExitDemoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Demo Mode?'),
        content: const Text(
          'You will be returned to the login screen. '
          'All demo data will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<DemoProvider>().disableDemoMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit Demo'),
          ),
        ],
      ),
    );
  }
}
