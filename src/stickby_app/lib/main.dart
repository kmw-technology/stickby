import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/groups_provider.dart';
import 'providers/shares_provider.dart';
import 'providers/profile_provider.dart';
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
      ],
      child: const StickByApp(),
    ),
  );
}
