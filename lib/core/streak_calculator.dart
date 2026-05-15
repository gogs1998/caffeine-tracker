import '../data/models/caffeine_entry.dart';

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final bool todayIsSafe;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.todayIsSafe,
  });
}

class StreakCalculator {
  final double safeThresholdMg;

  const StreakCalculator({this.safeThresholdMg = 50.0});

  /// A day is "safe" if total caffeine consumed after 18:00 was < safeThresholdMg.
  bool isDaySafe(List<CaffeineEntry> dayEntries) {
    final eveningMg = dayEntries
        .where((e) => e.consumedAt.hour >= 18)
        .fold(0.0, (sum, e) => sum + e.mgAmount);
    return eveningMg < safeThresholdMg;
  }

  StreakData calculate(List<CaffeineEntry> allEntries, {DateTime? now}) {
    final today = now ?? DateTime.now();

    if (allEntries.isEmpty) {
      return const StreakData(
          currentStreak: 0, longestStreak: 0, todayIsSafe: true);
    }

    // Group entries by date (local date string)
    final Map<String, List<CaffeineEntry>> byDay = {};
    for (final e in allEntries) {
      final key =
          '${e.consumedAt.year}-${e.consumedAt.month.toString().padLeft(2, '0')}-${e.consumedAt.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(key, () => []).add(e);
    }

    // Determine the full date range from earliest entry to today
    final earliest = allEntries
        .map((e) => e.consumedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final days = <DateTime>[];
    var cursor = DateTime(earliest.year, earliest.month, earliest.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    while (!cursor.isAfter(todayDate)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    // Build safety list per day
    final safeList = days.map((d) {
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final entries = byDay[key] ?? [];
      return isDaySafe(entries);
    }).toList();

    // Today's safety
    final todayKey =
        '${todayDate.year}-${todayDate.month.toString().padLeft(2, '0')}-${todayDate.day.toString().padLeft(2, '0')}';
    final todayEntries = byDay[todayKey] ?? [];
    final todayIsSafe = isDaySafe(todayEntries);

    // Calculate current streak (going backwards from today)
    int currentStreak = 0;
    for (int i = safeList.length - 1; i >= 0; i--) {
      if (safeList[i]) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Calculate longest streak
    int longestStreak = 0;
    int runningStreak = 0;
    for (final safe in safeList) {
      if (safe) {
        runningStreak++;
        if (runningStreak > longestStreak) longestStreak = runningStreak;
      } else {
        runningStreak = 0;
      }
    }

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      todayIsSafe: todayIsSafe,
    );
  }

  /// Returns last [days] days safety status (true = safe, false = not safe / no data treated as safe if no entries)
  List<bool> lastNDays(List<CaffeineEntry> allEntries, int days,
      {DateTime? now}) {
    final today = now ?? DateTime.now();
    final result = <bool>[];
    for (int i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final dayEntries = allEntries.where((e) {
        return e.consumedAt.year == d.year &&
            e.consumedAt.month == d.month &&
            e.consumedAt.day == d.day;
      }).toList();
      result.add(isDaySafe(dayEntries));
    }
    return result;
  }
}
