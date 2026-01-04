// Integration Test Suite for StickBy App
//
// This file imports and runs all integration tests.
// Run with: flutter test integration_test/app_test.dart
// Or for a specific device: flutter test integration_test/app_test.dart -d <device_id>

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Import all test files
import 'auth_test.dart' as auth_tests;
import 'contacts_test.dart' as contacts_tests;
import 'shares_test.dart' as shares_tests;
import 'groups_test.dart' as groups_tests;
import 'profile_test.dart' as profile_tests;
import 'p2p_privacy_test.dart' as p2p_tests;
import 'navigation_test.dart' as navigation_tests;
import 'e2e_user_journey_test.dart' as e2e_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('StickBy Integration Tests', () {
    // Authentication Tests
    group('Authentication', auth_tests.main);

    // Contacts Tests
    group('Contacts', contacts_tests.main);

    // Shares Tests
    group('Shares', shares_tests.main);

    // Groups Tests
    group('Groups', groups_tests.main);

    // Profile Tests
    group('Profile', profile_tests.main);

    // P2P Privacy Mode Tests
    group('P2P Privacy Mode', p2p_tests.main);

    // Navigation Tests
    group('Navigation', navigation_tests.main);

    // End-to-End User Journey Tests
    group('E2E User Journeys', e2e_tests.main);
  });
}
