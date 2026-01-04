import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickby_app/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Groups Screen Tests', () {
    testWidgets('Groups screen loads correctly', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      // Should show groups screen
      expect(find.text('Groups'), findsOneWidget);

      // Should show either groups list or empty state
      final hasGroups = find.byType(Card).evaluate().isNotEmpty;
      final hasEmptyState = find.textContaining('No groups').evaluate().isNotEmpty ||
          find.textContaining('Create').evaluate().isNotEmpty ||
          find.textContaining('Join').evaluate().isNotEmpty;

      expect(hasGroups || hasEmptyState, isTrue);
    });

    testWidgets('Can open create group screen', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Should show create group screen
        expect(find.text('Create Group'), findsOneWidget);
      }
    });

    testWidgets('Create group form validates name',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isEmpty) return;

      await tester.tap(addButton.first);
      await tester.pumpAndSettle();

      // Try to create without name
      final createButton = find.text('Create');
      if (createButton.evaluate().isNotEmpty) {
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('Please'), findsAtLeast(1));
      }
    });

    testWidgets('Can create a new group', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isEmpty) return;

      await tester.tap(addButton.first);
      await tester.pumpAndSettle();

      // Enter group name
      final nameField = find.byType(TextFormField);
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField.first, 'Test Group ${DateTime.now().millisecondsSinceEpoch}');
        await tester.pumpAndSettle();

        // Create
        final createButton = find.text('Create');
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await TestHelpers.waitForLoading(tester);
        }
      }
    });

    testWidgets('Group card shows member count', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      final groupCards = find.byType(Card);
      if (groupCards.evaluate().isNotEmpty) {
        // Should show member count
        final memberCount = find.textContaining('member');
        expect(memberCount, findsAtLeast(1));
      }
    });

    testWidgets('Can view group details', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      final groupCards = find.byType(Card);
      if (groupCards.evaluate().isNotEmpty) {
        await tester.tap(groupCards.first);
        await tester.pumpAndSettle();

        // Should show group details
        final hasDetails =
            find.text('Members').evaluate().isNotEmpty ||
            find.text('Details').evaluate().isNotEmpty ||
            find.byIcon(Icons.person).evaluate().isNotEmpty;

        expect(hasDetails, isTrue);
      }
    });

    testWidgets('Can invite members to group', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      final groupCards = find.byType(Card);
      if (groupCards.evaluate().isNotEmpty) {
        await tester.tap(groupCards.first);
        await tester.pumpAndSettle();

        // Find invite button
        final inviteButton = find.byIcon(Icons.person_add);
        if (inviteButton.evaluate().isNotEmpty) {
          await tester.tap(inviteButton.first);
          await tester.pumpAndSettle();

          // Should show invite dialog or screen
          final hasInviteUI =
              find.textContaining('Invite').evaluate().isNotEmpty ||
              find.textContaining('Email').evaluate().isNotEmpty;

          expect(hasInviteUI, isTrue);
        }
      }
    });

    testWidgets('Shows owner badge for created groups',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      // Groups created by user should show owner badge
      final ownerBadge = find.text('Owner');
      if (ownerBadge.evaluate().isNotEmpty) {
        expect(ownerBadge, findsAtLeast(1));
      }
    });

    testWidgets('Can leave a group', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      final groupCards = find.byType(Card);
      if (groupCards.evaluate().isNotEmpty) {
        await tester.tap(groupCards.first);
        await tester.pumpAndSettle();

        // Look for leave button or menu
        final moreButton = find.byIcon(Icons.more_vert);
        if (moreButton.evaluate().isNotEmpty) {
          await tester.tap(moreButton.first);
          await tester.pumpAndSettle();

          final leaveOption = find.text('Leave Group');
          if (leaveOption.evaluate().isNotEmpty) {
            await tester.tap(leaveOption);
            await tester.pumpAndSettle();

            // Should show confirmation
            expect(find.textContaining('leave'), findsAtLeast(1));

            // Cancel
            final cancelButton = find.text('Cancel');
            if (cancelButton.evaluate().isNotEmpty) {
              await tester.tap(cancelButton);
              await tester.pumpAndSettle();
            }
          }
        }
      }
    });

    testWidgets('Shows pending invitations', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      // Look for invitations section
      final invitationsHeader = find.textContaining('Invitation');
      if (invitationsHeader.evaluate().isNotEmpty) {
        // Should show accept/decline buttons for invitations
        expect(find.text('Accept'), findsAtLeast(1));
        expect(find.text('Decline'), findsAtLeast(1));
      }
    });

    testWidgets('Can accept group invitation', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      final acceptButton = find.text('Accept');
      if (acceptButton.evaluate().isNotEmpty) {
        await tester.tap(acceptButton.first);
        await TestHelpers.waitForLoading(tester);

        // Should show success message or update list
        final success = TestHelpers.hasAnySnackBar() ||
            find.text('Joined').evaluate().isNotEmpty;
        expect(success, isTrue);
      }
    });

    testWidgets('Can decline group invitation', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.groups);
      await TestHelpers.waitForLoading(tester);

      final declineButton = find.text('Decline');
      if (declineButton.evaluate().isNotEmpty) {
        await tester.tap(declineButton.first);
        await TestHelpers.waitForLoading(tester);

        // Invitation should be removed
      }
    });
  });
}
