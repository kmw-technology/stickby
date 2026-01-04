import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/demo_provider.dart';
import 'providers/demo_sync_provider.dart';
import 'providers/groups_provider.dart';
import 'providers/insights_provider.dart';
import 'providers/shares_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/p2p_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  final apiService = ApiService(storage: storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DemoProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => DemoSyncProvider(),
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
        ChangeNotifierProvider(
          create: (_) => InsightsProvider(),
        ),
      ],
      child: const StickByApp(),
    ),
  );
}
