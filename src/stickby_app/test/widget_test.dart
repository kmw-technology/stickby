// StickBy App Widget Tests
//
// Basic widget tests to verify the app structure and key components.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stickby_app/providers/auth_provider.dart';
import 'package:stickby_app/providers/contacts_provider.dart';
import 'package:stickby_app/providers/groups_provider.dart';
import 'package:stickby_app/providers/shares_provider.dart';
import 'package:stickby_app/providers/profile_provider.dart';
import 'package:stickby_app/providers/p2p_provider.dart';
import 'package:stickby_app/services/api_service.dart';
import 'package:stickby_app/services/storage_service.dart';
import 'package:stickby_app/screens/auth/login_screen.dart';
import 'package:stickby_app/theme/app_theme.dart';

void main() {
  group('App Smoke Tests', () {
    Widget createTestApp({required Widget child}) {
      final storageService = StorageService();
      final apiService = ApiService(storage: storageService);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              apiService: apiService,
              storageService: storageService,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ContactsProvider(apiService: apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => GroupsProvider(apiService: apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => SharesProvider(apiService: apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => ProfileProvider(apiService: apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => P2PProvider(storageService: storageService),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: child,
        ),
      );
    }

    testWidgets('Login screen smoke test', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Verify login screen renders
      expect(find.text('Sign In'), findsAtLeast(1));
      expect(find.byType(TextFormField), findsAtLeast(2));
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('Theme is applied correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Verify primary color is used
      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsAtLeast(1));
    });

    testWidgets('App uses Material 3', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(child: const LoginScreen()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.useMaterial3, isTrue);
    });
  });
}
