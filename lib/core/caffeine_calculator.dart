import 'dart:math';
import '../data/models/caffeine_entry.dart';

/// Caffeine half-life decay calculator.
///
/// Formula: C(t) = Σ [ mg_i * (0.5)^(hours_since_i / effectiveHalfLife) ]
/// where effectiveHalfLife = halfLifeHours * sensitivityMultiplier
class CaffeineCalculator {
  /// Physiological half-life of caffeine in hours (default: 5.0).
  final double halfLifeHours;

  /// Multiplier for sensitivity (e.g. GLP-1 users may metabolise slower).
  /// Effective half-life = halfLifeHours * sensitivityMultiplier.
  final double sensitivityMultiplier;

  const CaffeineCalculator({
    this.halfLifeHours = 5.0,
    this.sensitivityMultiplier = 1.0,
  });

  double get _effectiveHalfLife => halfLifeHours * sensitivityMultiplier;

  /// Caffeine level [mg] right now.
  double currentLevel(List<CaffeineEntry> entries, DateTime now) =>
      levelAt(entries, now);

  /// Caffeine level [mg] at [target] time.
  /// Entries consumed after [target] are ignored.
  double levelAt(List<CaffeineEntry> entries, DateTime target) {
    double total = 0.0;
    for (final e in entries) {
      if (e.consumedAt.isAfter(target)) continue;
      final hoursSince =
          target.difference(e.consumedAt).inMicroseconds / 3600000000.0;
      total += e.mgAmount * pow(0.5, hoursSince / _effectiveHalfLife);
    }
    return total;
  }

  /// Returns the earliest [DateTime] >= [from] when the total caffeine level
  /// drops to or below [thresholdMg]. Returns null if already safe.
  ///
  /// Uses binary search over a 72-hour window (1-minute resolution).
  DateTime? safeToSleepTime(
    List<CaffeineEntry> entries,
    DateTime from,
    double thresholdMg,
  ) {
    if (levelAt(entries, from) <= thresholdMg) return null;

    // Binary search: level is monotonically decreasing (no future entries).
    var lo = from;
    var hi = from.add(const Duration(hours: 72));

    // Verify we will actually reach threshold within 72 hours.
    if (levelAt(entries, hi) > thresholdMg) return null;

    while (hi.difference(lo).inSeconds > 60) {
      final mid = lo.add(Duration(
        microseconds: hi.difference(lo).inMicroseconds ~/ 2,
      ));
      if (levelAt(entries, mid) > thresholdMg) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return hi;
  }

  /// Returns [points] evenly-spaced (DateTime, level) pairs from [from] to [to].
  List<MapEntry<DateTime, double>> decayCurve(
    List<CaffeineEntry> entries,
    DateTime from,
    DateTime to, {
    int points = 100,
  }) {
    final totalMicros = to.difference(from).inMicroseconds;
    final step = totalMicros / (points - 1);
    return List.generate(points, (i) {
      final t = from
          .add(Duration(microseconds: (step * i).round()));
      return MapEntry(t, levelAt(entries, t));
    });
  }
}
