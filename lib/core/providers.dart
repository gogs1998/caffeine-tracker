import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/caffeine_entry.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/caffeine_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'caffeine_calculator.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

final caffeineRepositoryProvider =
    Provider<CaffeineRepository>((ref) => CaffeineRepository());

/// Async provider that creates a [SettingsRepository] once SharedPreferences
/// is available.
final settingsRepositoryProvider =
    FutureProvider<SettingsRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SettingsRepository(prefs);
});

// ── Data providers ────────────────────────────────────────────────────────────

final entriesProvider = FutureProvider<List<CaffeineEntry>>((ref) async {
  return ref.watch(caffeineRepositoryProvider).getAll();
});

final settingsProvider = FutureProvider<UserSettings>((ref) async {
  final repo = await ref.watch(settingsRepositoryProvider.future);
  return repo.load();
});

// ── Calculator ────────────────────────────────────────────────────────────────

/// Returns a [CaffeineCalculator] built from the current [UserSettings].
/// Falls back to defaults while settings are loading / on error.
final calculatorProvider = Provider<CaffeineCalculator>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (s) => CaffeineCalculator(
      halfLifeHours: s.halfLifeHours,
      sensitivityMultiplier: s.sensitivityMultiplier,
    ),
    loading: () => const CaffeineCalculator(),
    error: (_, __) => const CaffeineCalculator(),
  );
});

// ── Current level stream (ticks every 60 s) ───────────────────────────────────

final currentLevelProvider = StreamProvider<double>((ref) async* {
  Future<double> compute() async {
    final entries = await ref.read(caffeineRepositoryProvider).getAll();
    final calc = ref.read(calculatorProvider);
    return calc.currentLevel(entries, DateTime.now());
  }

  // Emit immediately, then every 60 seconds.
  yield await compute();

  final ticker = Stream<void>.periodic(const Duration(seconds: 60));
  await for (final _ in ticker) {
    yield await compute();
  }
});
