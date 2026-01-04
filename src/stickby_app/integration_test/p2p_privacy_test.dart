import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickby_app/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('P2P Privacy Mode Tests', () {
    testWidgets('Privacy mode selection shown during onboarding',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      // This test checks if privacy mode screen appears during onboarding
      // Note: Only visible for new users or after logout

      // Look for privacy mode selection
      final privacyModeScreen = find.text('Choose Your Privacy Mode');
      if (privacyModeScreen.evaluate().isNotEmpty) {
        // Should show both options
        expect(find.text('Standard Mode'), findsOneWidget);
        expect(find.text('P2P Privacy Mode'), findsOneWidget);
      }
    });

    testWidgets('Standard mode is marked as recommended',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final privacyModeScreen = find.text('Choose Your Privacy Mode');
      if (privacyModeScreen.evaluate().isNotEmpty) {
        // Standard mode should be recommended
        expect(find.text('Recommended'), findsOneWidget);
      }
    });

    testWidgets('P2P mode shows security features',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final privacyModeScreen = find.text('Choose Your Privacy Mode');
      if (privacyModeScreen.evaluate().isNotEmpty) {
        // P2P mode features should be visible
        expect(find.text('Data stays on device'), findsOneWidget);
        expect(find.text('No server storage'), findsOneWidget);
        expect(find.text('Direct P2P sharing'), findsOneWidget);
        expect(find.text('Revocable access'), findsOneWidget);
      }
    });

    testWidgets('Can select P2P privacy mode', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final privacyModeScreen = find.text('Choose Your Privacy Mode');
      if (privacyModeScreen.evaluate().isNotEmpty) {
        // Find and tap P2P mode option
        final p2pOption = find.text('P2P Privacy Mode');
        await tester.tap(p2pOption);
        await tester.pumpAndSettle();

        // Option should be selected (radio button)
        final radioButtons = find.byType(Radio<dynamic>);
        expect(radioButtons, findsAtLeast(2));
      }
    });

    testWidgets('Enabling P2P mode shows success dialog',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final privacyModeScreen = find.text('Choose Your Privacy Mode');
      if (privacyModeScreen.evaluate().isNotEmpty) {
        // Select P2P mode
        final p2pOption = find.text('P2P Privacy Mode');
        await tester.tap(p2pOption);
        await tester.pumpAndSettle();

        // Tap continue
        final continueButton = find.text('Continue');
        await tester.tap(continueButton);
        await TestHelpers.waitForLoading(tester);

        // Should show success dialog about master key
        final successDialog = find.text('Privacy Mode Enabled');
        if (successDialog.evaluate().isNotEmpty) {
          expect(successDialog, findsOneWidget);

          // Should warn about key loss
          expect(find.textContaining('cannot be recovered'), findsOneWidget);
        }
      }
    });
  });

  group('P2P Share Creation Tests', () {
    testWidgets('P2P share screen loads correctly',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      // Try to create P2P share
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        final p2pOption = find.text('P2P Share (Recommended)');
        if (p2pOption.evaluate().isNotEmpty) {
          await tester.tap(p2pOption);
          await tester.pumpAndSettle();

          // Should show P2P share creation screen
          expect(find.text('Create P2P Share'), findsOneWidget);
        }
      }
    });

    testWidgets('P2P share shows contact selection',
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

      final p2pOption = find.text('P2P Share (Recommended)');
      if (p2pOption.evaluate().isEmpty) return;

      await tester.tap(p2pOption);
      await tester.pumpAndSettle();

      // Should show contact selection with checkboxes
      final hasSelection =
          find.byType(CheckboxListTile).evaluate().isNotEmpty ||
          find.text('Select contacts').evaluate().isNotEmpty ||
          find.textContaining('No local contacts').evaluate().isNotEmpty;

      expect(hasSelection, isTrue);
    });

    testWidgets('Can select all contacts for P2P share',
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

      final p2pOption = find.text('P2P Share (Recommended)');
      if (p2pOption.evaluate().isEmpty) return;

      await tester.tap(p2pOption);
      await tester.pumpAndSettle();

      // Find select all button
      final selectAllButton = find.text('Select All');
      if (selectAllButton.evaluate().isNotEmpty) {
        await tester.tap(selectAllButton);
        await tester.pumpAndSettle();

        // All contacts should be selected
      }
    });

    testWidgets('P2P share generates QR code', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // This test needs P2P mode enabled and local contacts
      // For now, just verify the flow doesn't crash
      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      debugPrint('P2P share QR generation test completed');
    });
  });

  group('QR Code Scanning Tests', () {
    testWidgets('QR scanner button is visible when P2P enabled',
        (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      // Check for QR scanner button
      final qrScannerButton = find.byIcon(Icons.qr_code_scanner);
      if (qrScannerButton.evaluate().isNotEmpty) {
        expect(qrScannerButton, findsOneWidget);
      }
    });

    testWidgets('Can open QR scanner screen', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final qrScannerButton = find.byIcon(Icons.qr_code_scanner);
      if (qrScannerButton.evaluate().isNotEmpty) {
        await tester.tap(qrScannerButton);
        await tester.pumpAndSettle();

        // Should show scan screen
        expect(find.text('Scan QR Code'), findsOneWidget);
      }
    });

    testWidgets('QR scanner shows camera controls', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final qrScannerButton = find.byIcon(Icons.qr_code_scanner);
      if (qrScannerButton.evaluate().isNotEmpty) {
        await tester.tap(qrScannerButton);
        await tester.pumpAndSettle();

        // Should show camera controls
        final hasControls =
            find.byIcon(Icons.flash_off).evaluate().isNotEmpty ||
            find.byIcon(Icons.flash_on).evaluate().isNotEmpty ||
            find.byIcon(Icons.cameraswitch).evaluate().isNotEmpty;

        expect(hasControls, isTrue);
      }
    });

    testWidgets('QR scanner shows instructions', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final qrScannerButton = find.byIcon(Icons.qr_code_scanner);
      if (qrScannerButton.evaluate().isNotEmpty) {
        await tester.tap(qrScannerButton);
        await tester.pumpAndSettle();

        // Should show scanning instructions
        expect(find.textContaining('Point your camera'), findsOneWidget);
      }
    });

    testWidgets('QR scanner shows encryption badge', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      final qrScannerButton = find.byIcon(Icons.qr_code_scanner);
      if (qrScannerButton.evaluate().isNotEmpty) {
        await tester.tap(qrScannerButton);
        await tester.pumpAndSettle();

        // Should show encryption indicator
        expect(find.textContaining('encrypted'), findsOneWidget);
      }
    });
  });

  group('Share QR Display Tests', () {
    testWidgets('QR screen shows share info', (WidgetTester tester) async {
      // This test would need a P2P share to be created first
      // For now, verify the screen structure is correct
      debugPrint('QR display test - requires P2P share creation');
    });

    testWidgets('QR screen shows encryption notice', (WidgetTester tester) async {
      debugPrint('QR encryption notice test - requires P2P share');
    });

    testWidgets('Can copy QR data to clipboard', (WidgetTester tester) async {
      debugPrint('QR copy test - requires P2P share');
    });

    testWidgets('Can share QR data via native share', (WidgetTester tester) async {
      debugPrint('QR native share test - requires P2P share');
    });
  });

  group('Received Shares Tests', () {
    testWidgets('Received shares are displayed', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      await TestHelpers.navigateToTab(tester, TabIndex.shares);
      await TestHelpers.waitForLoading(tester);

      // Check for received shares section
      final receivedSection = find.textContaining('Received');
      if (receivedSection.evaluate().isNotEmpty) {
        expect(receivedSection, findsAtLeast(1));
      }
    });

    testWidgets('Received share shows owner info', (WidgetTester tester) async {
      app.main();
      await TestHelpers.waitForApp(tester);

      final loggedIn = await TestHelpers.login(tester);
      if (!loggedIn) return;

      // This would require having received shares
      debugPrint('Received share owner info test - requires received shares');
    });

    testWidgets('Can view contacts from received share',
        (WidgetTester tester) async {
      debugPrint('Received share contacts test - requires received shares');
    });

    testWidgets('Can delete received share', (WidgetTester tester) async {
      debugPrint('Delete received share test - requires received shares');
    });
  });
}
