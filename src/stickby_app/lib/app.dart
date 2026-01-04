import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/demo_provider.dart';
import 'providers/p2p_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/loading_indicator.dart';

class StickByApp extends StatefulWidget {
  const StickByApp({super.key});

  @override
  State<StickByApp> createState() => _StickByAppState();
}

class _StickByAppState extends State<StickByApp> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Check auth status, demo mode, and initialize P2P mode on app start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize demo mode first
      await context.read<DemoProvider>().initialize();
      // Then check auth status (will be skipped if demo mode is active)
      if (!context.read<DemoProvider>().isDemoMode) {
        await context.read<AuthProvider>().checkAuthStatus();
      }
      context.read<P2PProvider>().initialize();
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StickBy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isInitializing
          ? const Scaffold(
              body: LoadingIndicator(
                message: 'Loading...',
              ),
            )
          : Consumer2<AuthProvider, DemoProvider>(
              builder: (context, authProvider, demoProvider, child) {
                // Demo mode takes priority - show main screen with demo data
                if (demoProvider.isDemoMode) {
                  return const MainScreen();
                }

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

                  case AuthStatus.needsOnboarding:
                    return const WelcomeScreen();

                  case AuthStatus.unauthenticated:
                  case AuthStatus.error:
                    return const LoginScreen();
                }
              },
            ),
    );
  }
}
