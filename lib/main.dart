import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/log_drink_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/scanner_screen.dart';
import 'ui/screens/advice_screen.dart';
import 'ui/screens/paywall_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/log',
      builder: (_, __) => const LogDrinkScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (_, __) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/advice',
      builder: (_, __) => const AdviceScreen(),
    ),
    GoRoute(
      path: '/paywall',
      builder: (_, __) => const PaywallScreen(),
    ),
  ],
);

void main() {
  runApp(const ProviderScope(child: CaffeineTrackerApp()));
}

class CaffeineTrackerApp extends StatelessWidget {
  const CaffeineTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Caffeine Tracker',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12121A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.orange,
          surface: Color(0xFF1E1E2E),
          onPrimary: Colors.black87,
          onSecondary: Colors.black87,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A28),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          color: Color(0xFF1E1E2E),
          elevation: 4,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
        useMaterial3: true,
      ),
    );
  }
}
