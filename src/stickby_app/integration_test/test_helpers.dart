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
import 'package:stickby_app/app.dart';

/// Test configuration
class TestConfig {
  // Replace with actual test credentials
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'Test1234!';
  static const String testDisplayName = 'Test User';

  // Timeouts
  static const Duration shortTimeout = Duration(seconds: 2);
  static const Duration mediumTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(seconds: 10);
}

/// Helper class for common test operations
class TestHelpers {
  /// Create a test app with all providers
  static Widget createTestApp() {
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
      child: const StickByApp(),
    );
  }

  /// Wait for the app to settle and loading to complete
  static Future<void> waitForApp(WidgetTester tester) async {
    await tester.pumpAndSettle(TestConfig.mediumTimeout);
  }

  /// Wait for loading indicators to disappear
  static Future<void> waitForLoading(WidgetTester tester) async {
    await tester.pumpAndSettle();

    // Wait while CircularProgressIndicator is visible
    int attempts = 0;
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
        attempts < 20) {
      await tester.pump(const Duration(milliseconds: 500));
      attempts++;
    }
    await tester.pumpAndSettle();
  }

  /// Login with given credentials
  static Future<bool> login(
    WidgetTester tester, {
    String email = TestConfig.testEmail,
    String password = TestConfig.testPassword,
  }) async {
    await waitForApp(tester);

    // Find text fields
    final textFields = find.byType(TextFormField);
    if (textFields.evaluate().length < 2) {
      // Try TextField instead
      final textInputs = find.byType(TextField);
      if (textInputs.evaluate().length < 2) {
        debugPrint('Could not find login fields');
        return false;
      }
      await tester.enterText(textInputs.at(0), email);
      await tester.enterText(textInputs.at(1), password);
    } else {
      await tester.enterText(textFields.at(0), email);
      await tester.enterText(textFields.at(1), password);
    }
    await tester.pumpAndSettle();

    // Find and tap login button
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    if (loginButton.evaluate().isEmpty) {
      debugPrint('Could not find login button');
      return false;
    }

    await tester.tap(loginButton);
    await waitForLoading(tester);

    // Check if we're on main screen
    return find.byType(BottomNavigationBar).evaluate().isNotEmpty;
  }

  /// Logout from the app
  static Future<void> logout(WidgetTester tester) async {
    // Navigate to profile tab
    await navigateToTab(tester, TabIndex.profile);

    // Find logout button
    final logoutButton = find.text('Logout');
    if (logoutButton.evaluate().isNotEmpty) {
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Confirm logout if dialog appears
      final confirmButton = find.widgetWithText(TextButton, 'Logout');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();
      }
    }
  }

  /// Navigate to a specific tab
  static Future<void> navigateToTab(WidgetTester tester, TabIndex tab) async {
    final bottomNav = find.byType(BottomNavigationBar);
    if (bottomNav.evaluate().isEmpty) {
      debugPrint('BottomNavigationBar not found');
      return;
    }

    IconData icon;
    switch (tab) {
      case TabIndex.home:
        icon = Icons.home_outlined;
        break;
      case TabIndex.contacts:
        icon = Icons.contacts_outlined;
        break;
      case TabIndex.shares:
        icon = Icons.share_outlined;
        break;
      case TabIndex.groups:
        icon = Icons.group_outlined;
        break;
      case TabIndex.profile:
        icon = Icons.person_outlined;
        break;
    }

    final tabIcon = find.byIcon(icon);
    if (tabIcon.evaluate().isNotEmpty) {
      await tester.tap(tabIcon.first);
      await tester.pumpAndSettle();
    }
  }

  /// Scroll until a widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
    double delta = 100,
    int maxScrolls = 20,
  }) async {
    int scrolls = 0;
    while (finder.evaluate().isEmpty && scrolls < maxScrolls) {
      await tester.drag(
        scrollable ?? find.byType(ListView).first,
        Offset(0, -delta),
      );
      await tester.pumpAndSettle();
      scrolls++;
    }
  }

  /// Find a widget by its key
  static Finder byKey(String key) {
    return find.byKey(Key(key));
  }

  /// Check if a SnackBar with specific text is shown
  static bool hasSnackBar(String text) {
    return find.widgetWithText(SnackBar, text).evaluate().isNotEmpty;
  }

  /// Check if any SnackBar is shown
  static bool hasAnySnackBar() {
    return find.byType(SnackBar).evaluate().isNotEmpty;
  }

  /// Get text from a Text widget
  static String? getTextContent(Finder finder) {
    if (finder.evaluate().isEmpty) return null;
    final widget = finder.evaluate().first.widget;
    if (widget is Text) {
      return widget.data;
    }
    return null;
  }

  /// Fill a form field by label
  static Future<void> fillFormField(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final field = find.widgetWithText(TextFormField, label);
    if (field.evaluate().isNotEmpty) {
      await tester.enterText(field, value);
      await tester.pumpAndSettle();
    }
  }

  /// Tap a button by text
  static Future<void> tapButton(WidgetTester tester, String text) async {
    final button = find.widgetWithText(ElevatedButton, text);
    if (button.evaluate().isNotEmpty) {
      await tester.tap(button);
      await tester.pumpAndSettle();
    } else {
      // Try TextButton
      final textButton = find.widgetWithText(TextButton, text);
      if (textButton.evaluate().isNotEmpty) {
        await tester.tap(textButton);
        await tester.pumpAndSettle();
      }
    }
  }

  /// Take a screenshot (for debugging)
  static Future<void> takeScreenshot(WidgetTester tester, String name) async {
    debugPrint('Screenshot: $name');
  }

  /// Print all visible text widgets (for debugging)
  static void printVisibleTexts(WidgetTester tester) {
    final textWidgets = find.byType(Text);
    debugPrint('=== Visible Texts ===');
    for (final element in textWidgets.evaluate()) {
      final widget = element.widget as Text;
      debugPrint('- ${widget.data}');
    }
    debugPrint('====================');
  }
}

/// Tab indices for navigation
enum TabIndex { home, contacts, shares, groups, profile }

/// Extension methods for WidgetTester
extension WidgetTesterExtensions on WidgetTester {
  /// Tap a widget and wait for animations
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enter text and wait for animations
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Long press and wait
  Future<void> longPressAndSettle(Finder finder) async {
    await longPress(finder);
    await pumpAndSettle();
  }

  /// Swipe to dismiss
  Future<void> swipeToDismiss(Finder finder) async {
    await drag(finder, const Offset(-300, 0));
    await pumpAndSettle();
  }

  /// Pull to refresh
  Future<void> pullToRefresh() async {
    final listView = find.byType(ListView);
    if (listView.evaluate().isNotEmpty) {
      await drag(listView.first, const Offset(0, 300));
      await pumpAndSettle(TestConfig.mediumTimeout);
    }
  }
}

/// Custom matchers for integration tests
class CustomMatchers {
  /// Check if widget is enabled
  static Matcher isEnabled() => _IsEnabledMatcher();

  /// Check if widget is disabled
  static Matcher isDisabled() => _IsDisabledMatcher();
}

class _IsEnabledMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Element) {
      final widget = item.widget;
      if (widget is ElevatedButton) {
        return widget.onPressed != null;
      }
      if (widget is TextButton) {
        return widget.onPressed != null;
      }
      if (widget is IconButton) {
        return widget.onPressed != null;
      }
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('widget is enabled');
}

class _IsDisabledMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Element) {
      final widget = item.widget;
      if (widget is ElevatedButton) {
        return widget.onPressed == null;
      }
      if (widget is TextButton) {
        return widget.onPressed == null;
      }
      if (widget is IconButton) {
        return widget.onPressed == null;
      }
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('widget is disabled');
}
