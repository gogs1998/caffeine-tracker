import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/firebase_options.dart';
import 'data/db/database_helper.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/log_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/sleep_screen.dart';
import 'ui/screens/library_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/scanner_screen.dart';
import 'ui/screens/advice_screen.dart';
import 'ui/screens/drink_search_screen.dart';
import 'ui/screens/paywall_screen.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/theme/app_theme.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/log',
      builder: (_, __) => const LogScreen(),
    ),
    GoRoute(
      path: '/sleep',
      builder: (_, __) => const SleepScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (_, __) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/library',
      builder: (_, __) => const LibraryScreen(),
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
    GoRoute(
      path: '/auth',
      builder: (_, __) => const AuthScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (_, __) => const DrinkSearchScreen(),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // await DatabaseHelper.seedWebData(); // disabled for clean web demo
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase not configured yet — app runs without it.
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
