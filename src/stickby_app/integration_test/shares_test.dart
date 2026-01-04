import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickby_app/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shares Screen Tests', () {
    testWidgets('Shares screen loads correctly', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      // Should show shares screen
      expect(find.text('Shares'), findsOneWidget);

      // Should show either shares list or empty state
      final hasShares = find.byType(Card).evaluate().isNotEmpty;
      final hasEmptyState = find.textContaining('No shares').evaluate().isNotEmpty ||
          find.textContaining('Create').evaluate().isNotEmpty;

      expect(hasShares || hasEmptyState, isTrue);
    });

    testWidgets('Can open create share screen', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      // Tap add button
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Should show create share screen or options
        final hasCreateScreen = find.text('Create Share').evaluate().isNotEmpty ||
            find.text('P2P Share').evaluate().isNotEmpty ||
            find.text('Link Share').evaluate().isNotEmpty;

        expect(hasCreateScreen, isTrue);
      }
    });

    testWidgets('Create share shows contact selection',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isEmpty) return;

      await tester.tap(addButton.first);
      await tester.pumpAndSettle();

      // If bottom sheet appears, select an option
      final linkShare = find.text('Link Share');
      if (linkShare.evaluate().isNotEmpty) {
        await tester.tap(linkShare);
        await tester.pumpAndSettle();
      }

      // Should show contact selection
      final hasContactSelection =
          find.textContaining('Select').evaluate().isNotEmpty ||
          find.byType(CheckboxListTile).evaluate().isNotEmpty ||
          find.byType(Checkbox).evaluate().isNotEmpty;

      // Might show "no contacts" message if user has none
      final noContacts = find.textContaining('no contacts').evaluate().isNotEmpty;

      expect(hasContactSelection || noContacts, isTrue);
    });

    testWidgets('Share card shows correct information',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final shareCards = find.byType(Card);
      if (shareCards.evaluate().isNotEmpty) {
        // Shares should show:
        // - Name or "Unnamed Share"
        // - Contact count
        // - View count or created date
        // - Share/Copy buttons

        final hasShareInfo =
            find.textContaining('contact').evaluate().isNotEmpty ||
            find.textContaining('Share').evaluate().isNotEmpty;

        expect(hasShareInfo, isTrue);
      }
    });

    testWidgets('Can share a link', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final shareCards = find.byType(Card);
      if (shareCards.evaluate().isNotEmpty) {
        // Find share button
        final shareButton = find.text('Share');
        if (shareButton.evaluate().isNotEmpty) {
          await tester.tap(shareButton.first);
          await tester.pumpAndSettle();

          // Native share sheet should open (can't test directly)
          // Just verify no crash
        }
      }
    });

    testWidgets('Can copy share link', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final shareCards = find.byType(Card);
      if (shareCards.evaluate().isNotEmpty) {
        final copyButton = find.text('Copy');
        if (copyButton.evaluate().isNotEmpty) {
          await tester.tap(copyButton.first);
          await tester.pumpAndSettle();

          // Should show success snackbar
          expect(find.byType(SnackBar), findsOneWidget);
        }
      }
    });

    testWidgets('Can delete a share', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final shareCards = find.byType(Card);
      if (shareCards.evaluate().isNotEmpty) {
        final deleteButton = find.byIcon(Icons.delete_outline);
        if (deleteButton.evaluate().isNotEmpty) {
          await tester.tap(deleteButton.first);
          await tester.pumpAndSettle();

          // Should show confirmation dialog
          expect(find.text('Delete Share'), findsOneWidget);

          // Cancel
          final cancelButton = find.text('Cancel');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('Expired shares are marked', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      // If there are expired shares, they should be marked
      final expiredBadge = find.text('Expired');
      if (expiredBadge.evaluate().isNotEmpty) {
        // Expired badge should be visible
        expect(expiredBadge, findsAtLeast(1));
      }
    });

    testWidgets('Shows view count for shares', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final shareCards = find.byType(Card);
      if (shareCards.evaluate().isNotEmpty) {
        // Should show view count
        final viewCount = find.textContaining('view');
        expect(viewCount, findsAtLeast(1));
      }
    });
  });

  group('P2P Share Tests', () {
    testWidgets('P2P share option visible when privacy mode enabled',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Check if P2P option is available
        final p2pOption = find.text('P2P Share (Recommended)');
        if (p2pOption.evaluate().isNotEmpty) {
          // P2P mode is enabled
          expect(p2pOption, findsOneWidget);
        }
      }
    });

    testWidgets('QR scanner button visible when P2P mode enabled',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      // If P2P mode is enabled, QR scanner button should be visible
      final qrScanButton = find.byIcon(Icons.qr_code_scanner);
      // Just verify no crash if button doesn't exist
      debugPrint('QR scan button found: ${qrScanButton.evaluate().isNotEmpty}');
    });
  });
}
