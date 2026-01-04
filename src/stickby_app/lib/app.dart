import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/loading_indicator.dart';

class StickByApp extends StatefulWidget {
  const StickByApp({super.key});

  @override
  State<StickByApp> createState() => _StickByAppState();
}

class _StickByAppState extends State<StickByApp> {
  @override
  void initState() {
    super.initState();
    // Check auth status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StickBy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          switch (authProvider.status) {
            case AuthStatus.initial:
            case AuthStatus.loading:
              return const Scaffold(
                body: LoadingIndicator(
                  message: 'Loading...',
                ),
              );

            case AuthStatus.authenticated:
              return const MainScreen();

            case AuthStatus.unauthenticated:
            case AuthStatus.error:
              return const LoginScreen();
          }
        },
      ),
    );
  }
}
