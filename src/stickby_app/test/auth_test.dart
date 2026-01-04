import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stickby_app/providers/auth_provider.dart';
import 'package:stickby_app/screens/auth/login_screen.dart';
import 'package:stickby_app/theme/app_theme.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    Widget createLoginScreen({Size size = const Size(800, 600)}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );
    }

    testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Check for StickBy branding
      expect(find.text('StickBy'), findsOneWidget);

      // Check for form fields (2 text fields: email and password)
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Check for Sign Up link
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Email field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Password field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'mypassword');
      await tester.pump();

      expect(find.text('mypassword'), findsOneWidget);
    });

    testWidgets('Empty email shows validation error', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Find and tap the Sign In button (ElevatedButton)
      final signInButton = find.byType(ElevatedButton);
      await tester.tap(signInButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('Invalid email shows validation error', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'notanemail');
      await tester.pump();

      // Enter password so only email error shows
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'somepassword');
      await tester.pump();

      // Tap Sign In
      final signInButton = find.byType(ElevatedButton);
      await tester.tap(signInButton);
      await tester.pump();

      // Should show email validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Empty password shows validation error', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Enter valid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Tap Sign In without password
      final signInButton = find.byType(ElevatedButton);
      await tester.tap(signInButton);
      await tester.pump();

      // Should show password validation error
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Find visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButton, findsOneWidget);

      // Tap to show password
      await tester.tap(visibilityButton);
      await tester.pump();

      // Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('Can enter valid credentials', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Enter valid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      // Enter valid password
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'Test12345');
      await tester.pump();

      // Both fields should have the entered values
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Test12345'), findsOneWidget);
    });
  });
}
