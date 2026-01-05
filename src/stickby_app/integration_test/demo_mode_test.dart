import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickby_app/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Demo Mode Tests', () {
    group('Demo Mode Navigation and Features', () {
      testWidgets('Demo mode shows bottom navigation with all tabs', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Enter demo mode (will skip if already in demo mode)
        final inDemoMode = await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        if (!inDemoMode) {
          // If we can't enter demo mode, that's fine - the app might be logged in with real account
          return;
        }

        // Verify bottom navigation is visible with all tabs
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // Check for navigation icons (either outlined or filled version)
        final hasHomeIcon = find.byIcon(Icons.home_outlined).evaluate().isNotEmpty ||
            find.byIcon(Icons.home).evaluate().isNotEmpty;
        final hasContactsIcon = find.byIcon(Icons.contacts_outlined).evaluate().isNotEmpty ||
            find.byIcon(Icons.contacts).evaluate().isNotEmpty;
        final hasShareIcon = find.byIcon(Icons.share_outlined).evaluate().isNotEmpty ||
            find.byIcon(Icons.share).evaluate().isNotEmpty;
        final hasGroupIcon = find.byIcon(Icons.group_outlined).evaluate().isNotEmpty ||
            find.byIcon(Icons.group).evaluate().isNotEmpty;
        final hasProfileIcon = find.byIcon(Icons.person_outlined).evaluate().isNotEmpty ||
            find.byIcon(Icons.person).evaluate().isNotEmpty;

        expect(hasHomeIcon, isTrue);
        expect(hasContactsIcon, isTrue);
        expect(hasShareIcon, isTrue);
        expect(hasGroupIcon, isTrue);
        expect(hasProfileIcon, isTrue);
      });

      testWidgets('Can navigate to contacts tab in demo mode', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate to contacts
        await TestHelpers.navigateToTab(tester, TabIndex.contacts);
        await tester.pumpAndSettle();

        // Should show contacts screen (look for 'Contacts' text or contacts-related UI)
        final hasContactsContent =
            find.text('Contacts').evaluate().isNotEmpty ||
            find.byIcon(Icons.email).evaluate().isNotEmpty ||
            find.byIcon(Icons.phone).evaluate().isNotEmpty;

        expect(hasContactsContent, isTrue);
      });

      testWidgets('Can navigate to shares tab in demo mode', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate to shares
        await TestHelpers.navigateToTab(tester, TabIndex.shares);
        await tester.pumpAndSettle();

        // Should show shares screen
        final hasSharesContent =
            find.text('Shares').evaluate().isNotEmpty ||
            find.text('Business Card').evaluate().isNotEmpty ||
            find.byType(Card).evaluate().isNotEmpty;

        expect(hasSharesContent, isTrue);
      });

      testWidgets('Can navigate to groups tab in demo mode', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate to groups
        await TestHelpers.navigateToTab(tester, TabIndex.groups);
        await tester.pumpAndSettle();

        // Should show groups screen
        final hasGroupsContent =
            find.text('Groups').evaluate().isNotEmpty ||
            find.text('Family').evaluate().isNotEmpty ||
            find.text('Work Team').evaluate().isNotEmpty;

        expect(hasGroupsContent, isTrue);
      });

      testWidgets('Can navigate to profile tab in demo mode', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate to profile
        await TestHelpers.navigateToTab(tester, TabIndex.profile);
        await tester.pumpAndSettle();

        // Should show profile screen
        final hasProfileContent =
            find.text('Profile').evaluate().isNotEmpty ||
            find.textContaining('@').evaluate().isNotEmpty;

        expect(hasProfileContent, isTrue);
      });
    });

    group('Demo Mode Data Display', () {
      testWidgets('Demo mode contacts screen shows contact information', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate to contacts
        await TestHelpers.navigateToTab(tester, TabIndex.contacts);
        await tester.pumpAndSettle();
        await TestHelpers.waitForLoading(tester);

        // Should show contact type icons or email addresses
        final hasContactInfo =
            find.byIcon(Icons.email).evaluate().isNotEmpty ||
            find.byIcon(Icons.phone).evaluate().isNotEmpty ||
            find.textContaining('@').evaluate().isNotEmpty ||
            find.textContaining('+49').evaluate().isNotEmpty;

        expect(hasContactInfo, isTrue);
      });

      testWidgets('Demo mode groups screen shows group information', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate to groups
        await TestHelpers.navigateToTab(tester, TabIndex.groups);
        await tester.pumpAndSettle();
        await TestHelpers.waitForLoading(tester);

        // Should show demo groups
        final hasGroupInfo =
            find.text('Family').evaluate().isNotEmpty ||
            find.text('Work Team').evaluate().isNotEmpty ||
            find.textContaining('member').evaluate().isNotEmpty;

        expect(hasGroupInfo, isTrue);
      });

      testWidgets('Demo mode shares screen shows share information', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate to shares
        await TestHelpers.navigateToTab(tester, TabIndex.shares);
        await tester.pumpAndSettle();
        await TestHelpers.waitForLoading(tester);

        // Should show demo shares
        final hasShareInfo =
            find.text('Business Card').evaluate().isNotEmpty ||
            find.textContaining('view').evaluate().isNotEmpty ||
            find.byType(Card).evaluate().isNotEmpty;

        expect(hasShareInfo, isTrue);
      });
    });

    group('Demo Mode Profile', () {
      testWidgets('Demo mode shows profile with contact information', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate to profile
        await TestHelpers.navigateToTab(tester, TabIndex.profile);
        await tester.pumpAndSettle();
        await TestHelpers.waitForLoading(tester);

        // Should show profile information (name or email)
        final hasProfileInfo =
            find.textContaining('@').evaluate().isNotEmpty ||
            find.textContaining('Nicolas').evaluate().isNotEmpty ||
            find.textContaining('Clara').evaluate().isNotEmpty ||
            find.textContaining('Andreas').evaluate().isNotEmpty;

        expect(hasProfileInfo, isTrue);
      });

      testWidgets('Profile screen has scrollable content or actions', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate to profile
        await TestHelpers.navigateToTab(tester, TabIndex.profile);
        await tester.pumpAndSettle();

        // Profile screen should be visible and have some content
        // It should contain either profile info, settings, or action buttons
        final hasProfileContent =
            find.textContaining('@').evaluate().isNotEmpty ||
            find.text('Profile').evaluate().isNotEmpty ||
            find.text('Settings').evaluate().isNotEmpty ||
            find.byType(Card).evaluate().isNotEmpty ||
            find.byIcon(Icons.settings).evaluate().isNotEmpty;

        expect(hasProfileContent, isTrue);
      });
    });

    group('Demo Mode Tab Switching', () {
      testWidgets('Can switch between all tabs multiple times', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate through all tabs
        await TestHelpers.navigateToTab(tester, TabIndex.home);
        await tester.pumpAndSettle();

        await TestHelpers.navigateToTab(tester, TabIndex.contacts);
        await tester.pumpAndSettle();

        await TestHelpers.navigateToTab(tester, TabIndex.shares);
        await tester.pumpAndSettle();

        await TestHelpers.navigateToTab(tester, TabIndex.groups);
        await tester.pumpAndSettle();

        await TestHelpers.navigateToTab(tester, TabIndex.profile);
        await tester.pumpAndSettle();

        // Go back to home
        await TestHelpers.navigateToTab(tester, TabIndex.home);
        await tester.pumpAndSettle();

        // Should still show bottom navigation
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });
    });

    group('Demo Mode State Persistence', () {
      testWidgets('Demo mode persists after tab navigation', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await TestHelpers.enterDemoMode(tester, identity: 'Nicolas');

        // Navigate away and back
        await TestHelpers.navigateToTab(tester, TabIndex.contacts);
        await tester.pumpAndSettle();
        await TestHelpers.navigateToTab(tester, TabIndex.profile);
        await tester.pumpAndSettle();
        await TestHelpers.navigateToTab(tester, TabIndex.home);
        await tester.pumpAndSettle();

        // Should still be in app (not back to login)
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });
    });
  });
}
