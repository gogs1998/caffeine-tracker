import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/caffeine_entry.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/caffeine_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/health_repository.dart';
import 'caffeine_calculator.dart';
import 'heart_rate_sensitivity.dart';
import 'advice_engine.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

final caffeineRepositoryProvider =
    Provider<CaffeineRepository>((ref) => CaffeineRepository());

final healthRepositoryProvider =
    Provider<HealthRepository>((ref) => HealthRepository());

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

/// Returns a [CaffeineCalculator] built from the current [UserSettings]
/// combined with the live heart-rate sensitivity multiplier.
/// Falls back to defaults while settings are loading / on error.
final calculatorProvider = Provider<CaffeineCalculator>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  final effectiveSensitivity = ref.watch(effectiveSensitivityProvider);
  return settingsAsync.when(
    data: (s) => CaffeineCalculator(
      halfLifeHours: s.halfLifeHours,
      sensitivityMultiplier: effectiveSensitivity,
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

// ── Heart rate (polls every 5 minutes) ───────────────────────────────────────

/// Streams the most recent average heart rate (bpm) over the last 30 minutes,
/// refreshed every 5 minutes. Emits null if unavailable / permission denied.
final heartRateProvider = StreamProvider<double?>((ref) async* {
  final repo = ref.watch(healthRepositoryProvider);

  Future<double?> fetch() async {
    final available = await repo.isAvailable();
    if (!available) return null;
    final granted = await repo.requestPermissions();
    if (!granted) return null;
    return repo.getRecentHeartRate();
  }

  yield await fetch();

  final ticker = Stream<void>.periodic(const Duration(minutes: 5));
  await for (final _ in ticker) {
    yield await fetch();
  }
});

// ── Effective sensitivity (GLP-1 × heart-rate multiplier) ────────────────────

/// Combines the user's base [sensitivityMultiplier] (from settings, which may
/// already reflect GLP-1 mode) with the live heart-rate multiplier so that
/// an elevated heart rate further increases caffeine sensitivity.
final effectiveSensitivityProvider = Provider<double>((ref) {
  // ignore: no_leading_underscores_for_local_identifiers
  const hrs = HeartRateSensitivity();

  final settingsAsync = ref.watch(settingsProvider);
  final heartRateAsync = ref.watch(heartRateProvider);

  final baseSensitivity = settingsAsync.maybeWhen(
    data: (s) => s.sensitivityMultiplier,
    orElse: () => 1.0,
  );

  final heartRate = heartRateAsync.maybeWhen(
    data: (hr) => hr,
    orElse: () => null,
  );

  final hrMultiplier = hrs.computeMultiplier(heartRate);

  return baseSensitivity * hrMultiplier;
});

// ── Advice provider ───────────────────────────────────────────────────────────

/// Builds a [CaffeineState] from live providers and runs [AdviceEngine.assess].
/// Returns an [AsyncValue<CaffeineAdvice>] so the UI can handle loading/error.
final adviceProvider = FutureProvider<CaffeineAdvice>((ref) async {
  final entries = await ref.watch(entriesProvider.future);
  final settings = await ref.watch(settingsProvider.future);
  final heartRate = ref.watch(heartRateProvider).asData?.value;

  final calc = ref.watch(calculatorProvider);
  final now = DateTime.now();

  final currentMg = calc.currentLevel(entries, now);

  // Peak today: max level at any logged drink time today
  final todayEntries = entries.where((e) {
    return e.consumedAt.year == now.year &&
        e.consumedAt.month == now.month &&
        e.consumedAt.day == now.day;
  }).toList();
  double peakMg = currentMg;
  for (final e in todayEntries) {
    final levelAt = calc.levelAt(entries, e.consumedAt);
    if (levelAt > peakMg) peakMg = levelAt;
  }

  final bedtime = DateTime(
      now.year, now.month, now.day, settings.bedtimeHour, settings.bedtimeMinute);
  final safeToSleepAt = calc.safeToSleepTime(entries, now, settings.safeThresholdMg);

  final state = CaffeineState(
    currentMg: currentMg,
    peakMg: peakMg,
    heartRateBpm: heartRate,
    safeToSleepAt: safeToSleepAt,
    bedtime: bedtime,
    glp1Mode: settings.glp1Mode,
    glp1Medication: settings.glp1Medication,
    halfLifeHours: settings.halfLifeHours,
    totalDrinksToday: todayEntries.length,
    now: now,
  );

  return const AdviceEngine().assess(state);
});

