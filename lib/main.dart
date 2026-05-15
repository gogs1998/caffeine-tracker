import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'data/db/database_helper.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/log_drink_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/scanner_screen.dart';
import 'ui/screens/advice_screen.dart';
import 'ui/screens/paywall_screen.dart';
import 'ui/theme/app_theme.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await DatabaseHelper.seedWebData();
  }
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
      theme: AppTheme.build(),
    );
  }
}
