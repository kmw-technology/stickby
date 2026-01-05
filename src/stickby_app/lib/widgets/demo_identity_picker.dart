import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Represents a demo identity that can be selected
class DemoIdentity {
  final String id;
  final String name;
  final String email;
  final String avatarPath;
  final Color color;

  const DemoIdentity({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarPath,
    required this.color,
  });

  static const List<DemoIdentity> all = [
    DemoIdentity(
      id: 'nicolas-wild',
      name: 'Nicolas Wild',
      email: 'nicolas.wild@googlemail.com',
      avatarPath: 'assets/imgs/nw.jpg',
      color: Color(0xFF2563eb),
    ),
    DemoIdentity(
      id: 'clara-nguyen',
      name: 'Clara Nguyen',
      email: 'clara.nguyen@web.de',
      avatarPath: 'assets/imgs/cn.jpg',
      color: Color(0xFFdc2626),
    ),
    DemoIdentity(
      id: 'andreas-bauer',
      name: 'Andreas Bauer',
      email: 'andreas.bauer@gmail.com',
      avatarPath: 'assets/imgs/ab.jpg',
      color: Color(0xFF16a34a),
    ),
    DemoIdentity(
      id: 'andrea-wimmer',
      name: 'Andrea Wimmer',
      email: 'andrea.wimmer@example.com',
      avatarPath: 'assets/imgs/aw.jpg',
      color: Color(0xFF9333ea),
    ),
    DemoIdentity(
      id: 'anna-dannhauser',
      name: 'Anna Dannhauser',
      email: 'anna.dannhauser@example.com',
      avatarPath: 'assets/imgs/ad.jpg',
      color: Color(0xFFea580c),
    ),
    DemoIdentity(
      id: 'stefan-keller',
      name: 'Stefan Keller',
      email: 'stefan.keller@example.com',
      avatarPath: 'assets/imgs/st.jpg',
      color: Color(0xFF0891b2),
    ),
    DemoIdentity(
      id: 'tobias-bauer',
      name: 'Tobias Bauer',
      email: 'tobias.bauer@example.com',
      avatarPath: 'assets/imgs/tb.jpg',
      color: Color(0xFF4f46e5),
    ),
    DemoIdentity(
      id: 'jana-belawa',
      name: 'Jana Belawa',
      email: 'jana.belawa@example.com',
      avatarPath: 'assets/imgs/jb.jpg',
      color: Color(0xFFbe185d),
    ),
    DemoIdentity(
      id: 'leonie-austin',
      name: 'Leonie Austin',
      email: 'leonie.austin@example.com',
      avatarPath: 'assets/imgs/la.jpg',
      color: Color(0xFF059669),
    ),
  ];
}

/// Bottom sheet picker for selecting a demo identity
class DemoIdentityPicker extends StatelessWidget {
  const DemoIdentityPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Choose Your Demo Identity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pick a character to explore StickBy. You can try different identities on different devices to see how contacts sync.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Identity grid
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: DemoIdentity.all.length,
                itemBuilder: (context, index) {
                  final identity = DemoIdentity.all[index];
                  return _IdentityCard(
                    identity: identity,
                    onTap: () => Navigator.of(context).pop(identity),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Cancel button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final DemoIdentity identity;
  final VoidCallback onTap;

  const _IdentityCard({
    required this.identity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar with photo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: identity.color,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  identity.avatarPath,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 52,
                      height: 52,
                      color: identity.color.withOpacity(0.15),
                      child: Center(
                        child: Text(
                          identity.name.split(' ').map((n) => n[0]).join(),
                          style: TextStyle(
                            color: identity.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              identity.name.split(' ')[0], // First name only
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

