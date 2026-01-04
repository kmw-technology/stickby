// Test Runner for Individual Test Suites
//
// This file provides a way to run specific test suites individually.
//
// Usage:
//   flutter test integration_test/run_tests.dart --dart-define=SUITE=auth
//   flutter test integration_test/run_tests.dart --dart-define=SUITE=contacts
//   flutter test integration_test/run_tests.dart --dart-define=SUITE=shares
//   flutter test integration_test/run_tests.dart --dart-define=SUITE=groups
//   flutter test integration_test/run_tests.dart --dart-define=SUITE=profile
//   flutter test integration_test/run_tests.dart --dart-define=SUITE=p2p
//   flutter test integration_test/run_tests.dart --dart-define=SUITE=navigation
//   flutter test integration_test/run_tests.dart --dart-define=SUITE=e2e
//   flutter test integration_test/run_tests.dart --dart-define=SUITE=all

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'auth_test.dart' as auth_tests;
import 'contacts_test.dart' as contacts_tests;
import 'shares_test.dart' as shares_tests;
import 'groups_test.dart' as groups_tests;
import 'profile_test.dart' as profile_tests;
import 'p2p_privacy_test.dart' as p2p_tests;
import 'navigation_test.dart' as navigation_tests;
import 'e2e_user_journey_test.dart' as e2e_tests;

const String suite = String.fromEnvironment('SUITE', defaultValue: 'all');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  switch (suite.toLowerCase()) {
    case 'auth':
      auth_tests.main();
      break;

    case 'contacts':
      contacts_tests.main();
      break;

    case 'shares':
      shares_tests.main();
      break;

    case 'groups':
      groups_tests.main();
      break;

    case 'profile':
      profile_tests.main();
      break;

    case 'p2p':
      p2p_tests.main();
      break;

    case 'navigation':
      navigation_tests.main();
      break;

    case 'e2e':
      e2e_tests.main();
      break;

    case 'all':
    default:
      group('All StickBy Integration Tests', () {
        group('Authentication', auth_tests.main);
        group('Contacts', contacts_tests.main);
        group('Shares', shares_tests.main);
        group('Groups', groups_tests.main);
        group('Profile', profile_tests.main);
        group('P2P Privacy Mode', p2p_tests.main);
        group('Navigation', navigation_tests.main);
        group('E2E User Journeys', e2e_tests.main);
      });
      break;
  }
}
