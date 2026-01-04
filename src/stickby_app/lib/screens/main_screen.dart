import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/demo_provider.dart';
import '../providers/groups_provider.dart';
import '../providers/shares_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_mode_banner.dart';
import 'home/home_screen.dart';
import 'contacts/contacts_screen.dart';
import 'groups/groups_screen.dart';
import 'profile/profile_screen.dart';
import 'shares/shares_screen.dart';
import 'companies/companies_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ContactsScreen(),
    SharesScreen(),
    GroupsScreen(),
    CompaniesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final demoProvider = context.read<DemoProvider>();

    // Skip API calls in demo mode - data is loaded from DemoService
    if (demoProvider.isDemoMode) {
      return;
    }

    // Load data for all screens from API
    final contactsProvider = context.read<ContactsProvider>();
    final groupsProvider = context.read<GroupsProvider>();
    final sharesProvider = context.read<SharesProvider>();
    final profileProvider = context.read<ProfileProvider>();

    await Future.wait([
      contactsProvider.loadContacts(),
      groupsProvider.loadGroups(),
      groupsProvider.loadInvitations(),
      sharesProvider.loadShares(),
      profileProvider.loadProfile(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final groupsProvider = context.watch<GroupsProvider>();
    final demoProvider = context.watch<DemoProvider>();

    return DemoModeBanner(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.contacts_outlined),
              activeIcon: Icon(Icons.contacts),
              label: 'Contacts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.share_outlined),
              activeIcon: Icon(Icons.share),
              label: 'Shares',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: groupsProvider.pendingInvitationsCount > 0,
                label: Text('${groupsProvider.pendingInvitationsCount}'),
                child: const Icon(Icons.group_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: groupsProvider.pendingInvitationsCount > 0,
                label: Text('${groupsProvider.pendingInvitationsCount}'),
                child: const Icon(Icons.group),
              ),
              label: 'Groups',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.business_outlined),
              activeIcon: Icon(Icons.business),
              label: 'Companies',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      ),
    );
  }
}
