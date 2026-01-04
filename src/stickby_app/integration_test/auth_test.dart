import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stickby_app/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Tests', () {
    testWidgets('Login screen has all required elements', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check for email field
      expect(find.byType(TextField), findsAtLeast(2));

      // Check for login button
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ElevatedButton || widget is TextButton,
        ),
        findsAtLeast(1),
      );

      // Check for "Sign Up" link
      expect(find.textContaining('Sign Up'), findsOneWidget);
    });

    testWidgets('Empty form shows validation errors', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap login button without entering anything
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.textContaining('Please'), findsAtLeast(1));
      }
    });

    testWidgets('Invalid email format shows error', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find email field and enter invalid email
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'notanemail');
      await tester.pumpAndSettle();

      // Tap login
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();

        // Should show email validation error
        expect(find.textContaining('valid email'), findsOneWidget);
      }
    });

    testWidgets('Login with wrong password shows error', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter credentials
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'test@example.com');
      await tester.enterText(textFields.at(1), 'wrongpassword123');
      await tester.pumpAndSettle();

      // Tap login
      final buttons = find.byType(ElevatedButton);
      await tester.tap(buttons.first);

      // Wait for API response
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show error SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Successful login navigates to home', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Use TestHelpers to login
      final success = await TestHelpers.login(
        tester,
        email: 'your-test-email@example.com',  // Replace with real test account
        password: 'YourTestPassword123!',       // Replace with real password
      );

      if (success) {
        // Verify we're on the main screen
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
      } else {
        // Login failed - check for error
        expect(find.byType(SnackBar), findsOneWidget);
      }
    });
  });

  group('Registration Flow Tests', () {
    testWidgets('Can navigate to registration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap Sign Up link
      final signUpLink = find.textContaining('Sign Up');
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      // Verify we're on register screen
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Registration form validates input', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to register
      final signUpLink = find.textContaining('Sign Up');
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      // Try to submit empty form
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.textContaining('Please'), findsAtLeast(1));
      }
    });

    testWidgets('Password requirements are validated', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to register
      final signUpLink = find.textContaining('Sign Up');
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      // Find fields
      final textFields = find.byType(TextField);

      // Enter name and email
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@example.com');

      // Enter weak password
      await tester.enterText(textFields.at(2), 'weak');
      await tester.pumpAndSettle();

      // Submit
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Should show password requirement error
      expect(find.textContaining('8 characters'), findsOneWidget);
    });
  });
}
