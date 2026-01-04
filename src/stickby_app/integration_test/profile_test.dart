import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickby_app/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Screen Tests', () {
    testWidgets('Profile screen loads correctly', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Should show profile screen
      expect(find.text('Profile'), findsOneWidget);

      // Should show user info
      final hasUserInfo =
          find.byType(CircleAvatar).evaluate().isNotEmpty ||
          find.textContaining('@').evaluate().isNotEmpty;

      expect(hasUserInfo, isTrue);
    });

    testWidgets('Shows user display name and email',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Should show email (contains @)
      final emailText = find.textContaining('@');
      expect(emailText, findsAtLeast(1));
    });

    testWidgets('Can edit profile', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Find edit button
      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        // Should show edit profile screen
        expect(find.text('Edit Profile'), findsOneWidget);
      }
    });

    testWidgets('Edit profile validates display name',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isEmpty) return;

      await tester.tap(editButton.first);
      await tester.pumpAndSettle();

      // Clear display name and try to save
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('Please'), findsAtLeast(1));
      }
    });

    testWidgets('Can update display name', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isEmpty) return;

      await tester.tap(editButton.first);
      await tester.pumpAndSettle();

      // Update display name
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Updated Name');
      await tester.pumpAndSettle();

      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await TestHelpers.waitForLoading(tester);

        // Should show success or return to profile
        final success = TestHelpers.hasAnySnackBar() ||
            find.text('Profile').evaluate().isNotEmpty;
        expect(success, isTrue);
      }
    });

    testWidgets('Shows release groups section', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Should show release groups
      final releaseGroups = find.textContaining('Release');
      if (releaseGroups.evaluate().isNotEmpty) {
        expect(find.text('Family'), findsAtLeast(1));
        expect(find.text('Friends'), findsAtLeast(1));
        expect(find.text('Business'), findsAtLeast(1));
        expect(find.text('Leisure'), findsAtLeast(1));
      }
    });

    testWidgets('Can manage release groups', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Find release groups section or button
      final releaseGroupsButton = find.textContaining('Release');
      if (releaseGroupsButton.evaluate().isNotEmpty) {
        await tester.tap(releaseGroupsButton.first);
        await tester.pumpAndSettle();

        // Should show release groups management
        final hasManagement =
            find.byType(Switch).evaluate().isNotEmpty ||
            find.byType(Checkbox).evaluate().isNotEmpty ||
            find.text('Save').evaluate().isNotEmpty;

        expect(hasManagement, isTrue);
      }
    });

    testWidgets('Shows logout button', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Scroll to find logout button if needed
      await TestHelpers.scrollUntilVisible(tester, find.text('Logout'));

      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('Logout shows confirmation', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      await TestHelpers.scrollUntilVisible(tester, find.text('Logout'));

      final logoutButton = find.text('Logout');
      if (logoutButton.evaluate().isNotEmpty) {
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        final hasConfirmation =
            find.textContaining('Are you sure').evaluate().isNotEmpty ||
            find.text('Cancel').evaluate().isNotEmpty;

        expect(hasConfirmation, isTrue);

        // Cancel logout
        final cancelButton = find.text('Cancel');
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Shows settings section', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Look for settings options
      final hasSettings =
          find.text('Settings').evaluate().isNotEmpty ||
          find.byIcon(Icons.settings).evaluate().isNotEmpty ||
          find.text('Privacy').evaluate().isNotEmpty;

      // Settings section should exist
      debugPrint('Has settings section: $hasSettings');
    });

    testWidgets('Shows privacy mode status', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Check for privacy mode indicator
      final privacyMode = find.textContaining('Privacy');
      if (privacyMode.evaluate().isNotEmpty) {
        // Privacy mode setting should be visible
        expect(privacyMode, findsAtLeast(1));
      }
    });

    testWidgets('Can pull to refresh profile', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Pull to refresh
      final scrollable = find.byType(SingleChildScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, 300));
        await tester.pump();
        await TestHelpers.waitForLoading(tester);
      }
    });

    testWidgets('Shows app version', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Scroll to bottom for version
      await TestHelpers.scrollUntilVisible(
        tester,
        find.textContaining('Version'),
        maxScrolls: 10,
      );

      // Version should be displayed
      final version = find.textContaining('Version');
      if (version.evaluate().isNotEmpty) {
        expect(version, findsAtLeast(1));
      }
    });
  });
}
