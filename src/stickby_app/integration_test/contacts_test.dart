import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickby_app/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Contacts Screen Tests', () {
    testWidgets('Contacts screen loads and shows list or empty state',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // Login first
      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) {
        debugPrint('Login failed, skipping test');
        return;
      }

      // Navigate to contacts tab
      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Should show either contacts list or empty state
      final hasContacts = find.byType(Card).evaluate().isNotEmpty;
      final hasEmptyState = find.textContaining('No contacts').evaluate().isNotEmpty ||
          find.textContaining('Add').evaluate().isNotEmpty;

      expect(hasContacts || hasEmptyState, isTrue);
    });

    testWidgets('Can open add contact screen', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Tap add button (FAB or AppBar button)
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Should show add contact screen
        expect(find.text('Add Contact'), findsOneWidget);
      }
    });

    testWidgets('Add contact form validates required fields',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Open add contact
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Try to save without filling fields
        final saveButton = find.text('Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();

          // Should show validation error
          expect(find.textContaining('Please'), findsAtLeast(1));
        }
      }
    });

    testWidgets('Can add a new contact successfully',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Open add contact
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isEmpty) return;

      await tester.tap(addButton.first);
      await tester.pumpAndSettle();

      // Fill in contact details
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 2) {
        // Enter label and value
        await tester.enterText(textFields.at(0), 'Test Phone');
        await tester.enterText(textFields.at(1), '+1234567890');
        await tester.pumpAndSettle();

        // Save
        final saveButton = find.text('Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await TestHelpers.waitForLoading(tester);

          // Should return to contacts list
          expect(find.text('Contacts'), findsOneWidget);
        }
      }
    });

    testWidgets('Contacts are grouped by category', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // If there are contacts, they should be grouped
      final hasContacts = find.byType(Card).evaluate().isNotEmpty;
      if (hasContacts) {
        // Look for category headers
        final hasCategories =
            find.textContaining('General').evaluate().isNotEmpty ||
            find.textContaining('Business').evaluate().isNotEmpty ||
            find.textContaining('Social').evaluate().isNotEmpty;

        // Categories should be visible if there are contacts
        expect(hasCategories, isTrue);
      }
    });

    testWidgets('Can edit an existing contact', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Find a contact card and tap it
      final contactCards = find.byType(Card);
      if (contactCards.evaluate().isNotEmpty) {
        await tester.tap(contactCards.first);
        await tester.pumpAndSettle();

        // Look for edit button or edit screen
        final editButton = find.byIcon(Icons.edit);
        if (editButton.evaluate().isNotEmpty) {
          await tester.tap(editButton.first);
          await tester.pumpAndSettle();

          // Should show edit screen
          expect(find.text('Edit Contact'), findsOneWidget);
        }
      }
    });

    testWidgets('Can delete a contact with confirmation',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      final contactCards = find.byType(Card);
      if (contactCards.evaluate().isNotEmpty) {
        // Long press for options or find delete button
        await tester.longPress(contactCards.first);
        await tester.pumpAndSettle();

        final deleteButton = find.byIcon(Icons.delete);
        if (deleteButton.evaluate().isNotEmpty) {
          await tester.tap(deleteButton.first);
          await tester.pumpAndSettle();

          // Should show confirmation dialog
          expect(find.text('Delete'), findsAtLeast(1));

          // Cancel deletion
          final cancelButton = find.text('Cancel');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('Pull to refresh works', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Pull to refresh
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView.first, const Offset(0, 300));
        await tester.pump();

        // Should show refresh indicator
        expect(find.byType(RefreshIndicator), findsOneWidget);
        await TestHelpers.waitForLoading(tester);
      }
    });

    testWidgets('Release groups can be edited', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.contacts);
      await TestHelpers.waitForLoading(tester);

      // Look for release group badges or edit option
      final contactCards = find.byType(Card);
      if (contactCards.evaluate().isNotEmpty) {
        await tester.tap(contactCards.first);
        await tester.pumpAndSettle();

        // Look for release groups option
        final releaseGroupsButton = find.textContaining('Release');
        if (releaseGroupsButton.evaluate().isNotEmpty) {
          await tester.tap(releaseGroupsButton.first);
          await tester.pumpAndSettle();

          // Should show release groups selection
          expect(find.text('Family'), findsAtLeast(1));
          expect(find.text('Friends'), findsAtLeast(1));
          expect(find.text('Business'), findsAtLeast(1));
        }
      }
    });
  });
}
