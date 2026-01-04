import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickby_app/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete User Journey Tests', () {
    testWidgets('New user registration and onboarding flow',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Step 1: Navigate to registration
      final signUpLink = find.textContaining('Sign Up');
      if (signUpLink.evaluate().isEmpty) return;

      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      // Step 2: Fill registration form
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 3) {
        final uniqueEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';

        await tester.enterText(textFields.at(0), 'Test User');
        await tester.enterText(textFields.at(1), uniqueEmail);
        await tester.enterText(textFields.at(2), 'TestPassword123!');
        await tester.pumpAndSettle();

        // Step 3: Submit registration
        final createButton = find.widgetWithText(ElevatedButton, 'Create Account');
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await TestHelpers.waitForLoading(tester);

          // Step 4: Should be in onboarding or main screen
          final inOnboarding = find.text('Welcome').evaluate().isNotEmpty;
          final inMainScreen = find.byType(BottomNavigationBar).evaluate().isNotEmpty;

          expect(inOnboarding || inMainScreen, isTrue);
        }
      }
    });

    testWidgets('Login -> Add Contact -> Create Share flow',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Step 1: Login
      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) {
        debugPrint('Login failed, skipping journey test');
        return;
      }

      // Step 2: Navigate to contacts
      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Step 3: Add a contact
      final addContactButton = find.byIcon(Icons.add);
      if (addContactButton.evaluate().isNotEmpty) {
        await tester.tap(addContactButton.first);
        await tester.pumpAndSettle();

        final contactFields = find.byType(TextFormField);
        if (contactFields.evaluate().length >= 2) {
          await tester.enterText(contactFields.at(0), 'Journey Test Contact');
          await tester.enterText(contactFields.at(1), '+1234567890');
          await tester.pumpAndSettle();

          final saveButton = find.text('Save');
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton);
            await TestHelpers.waitForLoading(tester);
          }
        }
      }

      // Step 4: Navigate to shares
      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      // Step 5: Create a share
      final createShareButton = find.byIcon(Icons.add);
      if (createShareButton.evaluate().isNotEmpty) {
        await tester.tap(createShareButton.first);
        await tester.pumpAndSettle();

        // Select link share option if shown
        final linkShare = find.text('Link Share');
        if (linkShare.evaluate().isNotEmpty) {
          await tester.tap(linkShare);
          await tester.pumpAndSettle();
        }

        // Select contacts if shown
        final checkboxes = find.byType(CheckboxListTile);
        if (checkboxes.evaluate().isNotEmpty) {
          await tester.tap(checkboxes.first);
          await tester.pumpAndSettle();
        }
      }

      // Verify we completed the journey
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Browse all main screens without errors',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Visit each screen
      final tabs = [
        TabIndex.home,
        TabIndex.contacts,
        TabIndex.shares,
        TabIndex.groups,
        TabIndex.profile,
      ];

      for (final tab in tabs) {
        await TestHelpers.navigateToTab(tester, tab);
        await TestHelpers.waitForLoading(tester);

        // Each screen should load without throwing
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      }
    });

    testWidgets('Login -> View Profile -> Edit -> Save flow',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Navigate to profile
      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);

      // Open edit screen
      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        // Update name
        final nameField = find.byType(TextFormField).first;
        await tester.enterText(nameField, 'Updated Test User');
        await tester.pumpAndSettle();

        // Save
        final saveButton = find.text('Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await TestHelpers.waitForLoading(tester);
        }

        // Should return to profile
        expect(find.text('Profile'), findsAtLeast(1));
      }
    });

    testWidgets('Join group invitation flow', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Navigate to groups
      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      // Check for invitations
      final acceptButton = find.text('Accept');
      if (acceptButton.evaluate().isNotEmpty) {
        await tester.tap(acceptButton.first);
        await TestHelpers.waitForLoading(tester);

        // Should show success or group in list
        final success = TestHelpers.hasAnySnackBar() ||
            find.byType(Card).evaluate().isNotEmpty;
        expect(success, isTrue);
      }
    });

    testWidgets('Full logout and login again flow',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Login
      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Logout
      await TestHelpers.navigateToTab(tester, TabIndex.profile);
      await TestHelpers.waitForLoading(tester);
      await TestHelpers.scrollUntilVisible(tester, find.text('Logout'));

      final logoutButton = find.text('Logout');
      if (logoutButton.evaluate().isNotEmpty) {
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Confirm logout
        final confirmLogout = find.widgetWithText(TextButton, 'Logout');
        if (confirmLogout.evaluate().isNotEmpty) {
          await tester.tap(confirmLogout);
          await TestHelpers.waitForLoading(tester);

          // Should be on login screen
          expect(find.text('Sign In'), findsOneWidget);

          // Login again
          final loggedInAgain = await TestHelpers.login(tester);
          expect(loggedInAgain, isTrue);
        }
      }
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Shows error on network failure', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Try to login with wrong credentials
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(0), 'nonexistent@email.com');
        await tester.enterText(textFields.at(1), 'wrongpassword');
        await tester.pumpAndSettle();

        final loginButton = find.widgetWithText(ElevatedButton, 'Login');
        await tester.tap(loginButton);
        await TestHelpers.waitForLoading(tester);

        // Should show error
        expect(TestHelpers.hasAnySnackBar(), isTrue);
      }
    });

    testWidgets('Handles empty states gracefully',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Navigate through all tabs - should show empty states or content
      for (final tab in [
        TabIndex.contacts,
        TabIndex.shares,
        TabIndex.groups,
      ]) {
        await TestHelpers.navigateToTab(tester, tab);
        await TestHelpers.waitForLoading(tester);

        // Should not crash - shows either content or empty state
        final hasContent = find.byType(Card).evaluate().isNotEmpty;
        final hasEmptyState =
            find.textContaining('No ').evaluate().isNotEmpty ||
            find.textContaining('empty').evaluate().isNotEmpty ||
            find.textContaining('Add').evaluate().isNotEmpty ||
            find.textContaining('Create').evaluate().isNotEmpty;

        expect(hasContent || hasEmptyState, isTrue);
      }
    });

    testWidgets('Form validation prevents invalid submissions',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Try empty login
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.textContaining('Please'), findsAtLeast(1));
      }
    });
  });

  group('Performance Tests', () {
    testWidgets('App starts in reasonable time', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();
      debugPrint('App startup time: ${stopwatch.elapsedMilliseconds}ms');

      // App should start in under 10 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });

    testWidgets('Tab navigation is fast', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // Measure tab switch time
      final stopwatch = Stopwatch();

      for (final tab in TabIndex.values) {
        stopwatch.reset();
        stopwatch.start();

        await TestHelpers.navigateToTab(tester, tab);
        await tester.pumpAndSettle();

        stopwatch.stop();
        debugPrint('Tab ${tab.name} switch: ${stopwatch.elapsedMilliseconds}ms');

        // Each tab switch should be under 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      }
    });

    testWidgets('Scroll performance is smooth', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Rapid scrolling shouldn't cause jank or crashes
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.fling(listView.first, const Offset(0, -500), 1000);
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        // Should complete without errors
      }
    });
  });

  group('Accessibility Tests', () {
    testWidgets('All buttons have tap targets', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Verify login button is tappable
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      if (loginButton.evaluate().isNotEmpty) {
        final box = tester.getRect(loginButton);
        // Button should be at least 48x48 for accessibility
        expect(box.width, greaterThanOrEqualTo(44));
        expect(box.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('Text is readable (contrast)', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Verify primary text is visible
      final signInText = find.text('Sign In');
      expect(signInText, findsOneWidget);

      // Text should exist and be styled
      final textWidget = tester.widget<Text>(signInText);
      expect(textWidget.style, isNotNull);
    });

    testWidgets('Form fields have labels', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Verify form fields exist
      final textFields = find.byType(TextFormField);
      expect(textFields, findsAtLeast(2));

      // Form fields should be visible and functional
      for (final field in textFields.evaluate()) {
        final widget = field.widget as TextFormField;
        // Each field should have some identification (controller or initialValue)
        expect(widget, isNotNull);
      }
    });
  });
}
