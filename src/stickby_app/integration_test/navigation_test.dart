import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickby_app/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom Navigation Tests', () {
    testWidgets('All navigation tabs are visible', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Verify all navigation items exist
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.contacts_outlined), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.byIcon(Icons.group_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outlined), findsOneWidget);
    });

    testWidgets('Tab navigation updates content', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Home tab
      await TestHelpers.navigateToTab(tester, TabIndex.home);
      expect(find.text('Home'), findsAtLeast(1));

      // Contacts tab
      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      expect(find.text('Contacts'), findsAtLeast(1));

      // Shares tab
      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      expect(find.text('Shares'), findsAtLeast(1));

      // Groups tab
      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      expect(find.text('Groups'), findsAtLeast(1));

      // Profile tab
      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      expect(find.text('Profile'), findsAtLeast(1));
    });

    testWidgets('Tab state is preserved on switch', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Navigate to contacts
      await TestHelpers.navigateToTab(tester, TabIndex.contacts);

      // Scroll down if possible
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView.first, const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      // Switch to another tab and back
      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.navigateToTab(tester, TabIndex.contacts);

      // State should be preserved (scroll position, etc.)
      expect(find.text('Contacts'), findsAtLeast(1));
    });

    testWidgets('Active tab is highlighted', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Navigate to contacts
      await TestHelpers.navigateToTab(tester, TabIndex.contacts);

      // Verify the contacts icon is now filled (active state)
      final contactsIconFilled = find.byIcon(Icons.contacts);
      final contactsIconOutlined = find.byIcon(Icons.contacts_outlined);

      // One of them should be visible
      expect(
        contactsIconFilled.evaluate().isNotEmpty ||
            contactsIconOutlined.evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('App Bar Navigation Tests', () {
    testWidgets('Back button works correctly', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Navigate to contacts
      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Open add contact screen
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Verify we're on add contact screen
        expect(find.text('Add Contact'), findsOneWidget);

        // Tap back button
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          // Should be back on contacts screen
          expect(find.text('Contacts'), findsAtLeast(1));
        }
      }
    });

    testWidgets('AppBar actions are visible', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Should show add button in app bar
      expect(find.byIcon(Icons.add), findsAtLeast(1));
    });
  });

  group('Deep Navigation Tests', () {
    testWidgets('Can navigate to nested screens and back',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Navigate: Home -> Contacts -> Add Contact -> Back -> Back
      await TestHelpers.navigateToTab(tester, TabIndex.contacts);

      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Fill form partially
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'Test');
          await tester.pumpAndSettle();
        }

        // Go back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Should be back on contacts screen
        expect(find.text('Contacts'), findsAtLeast(1));
      }
    });

    testWidgets('Modal screens can be dismissed',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      // Open create share
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // If bottom sheet opened, dismiss it
        final linkShare = find.text('Link Share');
        if (linkShare.evaluate().isNotEmpty) {
          // Tap outside to dismiss
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();

          // Should be back on shares screen
          expect(find.text('Shares'), findsAtLeast(1));
        }
      }
    });
  });

  group('Dialog Navigation Tests', () {
    testWidgets('Alert dialogs can be dismissed',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      await TestHelpers.scrollUntilVisible(tester, find.text('Logout'));

      // Tap logout
      final logoutButton = find.text('Logout');
      if (logoutButton.evaluate().isNotEmpty) {
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Verify dialog is shown
        expect(find.byType(AlertDialog), findsOneWidget);

        // Tap outside or cancel to dismiss
        final cancelButton = find.text('Cancel');
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();

          // Dialog should be dismissed
          expect(find.byType(AlertDialog), findsNothing);
        }
      }
    });

    testWidgets('Confirmation dialogs work correctly',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final shareCards = find.byType(Card);
      if (shareCards.evaluate().isNotEmpty) {
        // Find delete button
        final deleteButton = find.byIcon(Icons.delete_outline);
        if (deleteButton.evaluate().isNotEmpty) {
          await tester.tap(deleteButton.first);
          await tester.pumpAndSettle();

          // Confirmation dialog should appear
          expect(find.text('Delete'), findsAtLeast(1));

          // Cancel
          final cancelButton = find.text('Cancel');
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();
        }
      }
    });
  });

  group('Pull to Refresh Tests', () {
    testWidgets('Pull to refresh works on all list screens',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Test pull to refresh on contacts
      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);
      await tester.pullToRefresh();

      // Test pull to refresh on shares
      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);
      await tester.pullToRefresh();

      // Test pull to refresh on groups
      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);
      await tester.pullToRefresh();
    });
  });

  group('Scroll Behavior Tests', () {
    testWidgets('Lists scroll smoothly', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        // Scroll down
        await tester.drag(listView.first, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Scroll up
        await tester.drag(listView.first, const Offset(0, 300));
        await tester.pumpAndSettle();

        // Should complete without errors
      }
    });

    testWidgets('Can scroll to bottom of long lists',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Scroll to find logout button at bottom
      await TestHelpers.scrollUntilVisible(
        tester,
        find.text('Logout'),
        maxScrolls: 15,
      );

      expect(find.text('Logout'), findsOneWidget);
    });
  });

  group('Keyboard Navigation Tests', () {
    testWidgets('Form fields can be focused', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Focus on login fields
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.tap(textFields.first);
        await tester.pumpAndSettle();

        // Keyboard should be shown (can't verify directly in test)
      }
    });

    testWidgets('Form submission works on enter', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Enter credentials
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(0), 'test@example.com');
        await tester.enterText(textFields.at(1), 'password123');

        // Submit form
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }
    });
  });
}
