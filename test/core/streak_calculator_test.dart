import 'package:flutter_test/flutter_test.dart';
import 'package:caffeine_tracker/core/streak_calculator.dart';
import 'package:caffeine_tracker/data/models/caffeine_entry.dart';

CaffeineEntry _entry(String id, DateTime at, double mg) => CaffeineEntry(
      id: id,
      drinkName: 'Coffee',
      mgAmount: mg,
      consumedAt: at,
    );

void main() {
  const calc = StreakCalculator(safeThresholdMg: 50.0);
  final baseDay = DateTime(2024, 6, 10, 0, 0);

  group('StreakCalculator', () {
    test('0 entries → streak 0', () {
      final result = calc.calculate([], now: baseDay);
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.todayIsSafe, true);
    });

    test('3 consecutive safe days → streak 3', () {
      final now = DateTime(2024, 6, 12, 12, 0);
      // Each day has evening mg < 50 (just morning coffee)
      final entries = [
        _entry('1', DateTime(2024, 6, 10, 8, 0), 80), // morning, not evening
        _entry('2', DateTime(2024, 6, 11, 9, 0), 80),
        _entry('3', DateTime(2024, 6, 12, 9, 0), 80),
      ];
      final result = calc.calculate(entries, now: now);
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
    });

    test('Safe streak broken resets to 0 before break', () {
      final now = DateTime(2024, 6, 12, 22, 0);
      final entries = [
        _entry('1', DateTime(2024, 6, 10, 8, 0), 80), // day1 safe
        // day2: evening caffeine > 50 → not safe
        _entry('2', DateTime(2024, 6, 11, 20, 0), 100),
        _entry('3', DateTime(2024, 6, 12, 8, 0), 80), // day3 safe
      ];
      final result = calc.calculate(entries, now: now);
      // current streak is just today (day3)
      expect(result.currentStreak, 1);
      // longest streak is 1 (day1 or day3)
      expect(result.longestStreak, 1);
    });

    test('Today counted correctly — unsafe today breaks streak', () {
      final now = DateTime(2024, 6, 12, 22, 0);
      final entries = [
        _entry('1', DateTime(2024, 6, 10, 8, 0), 80), // safe
        _entry('2', DateTime(2024, 6, 11, 8, 0), 80), // safe
        // today: evening over threshold
        _entry('3', DateTime(2024, 6, 12, 20, 0), 100),
      ];
      final result = calc.calculate(entries, now: now);
      expect(result.currentStreak, 0);
      expect(result.todayIsSafe, false);
    });

    test('Today counted correctly — safe today continues streak', () {
      final now = DateTime(2024, 6, 12, 12, 0);
      final entries = [
        _entry('1', DateTime(2024, 6, 10, 8, 0), 80),
        _entry('2', DateTime(2024, 6, 11, 8, 0), 80),
        _entry('3', DateTime(2024, 6, 12, 8, 0), 80),
      ];
      final result = calc.calculate(entries, now: now);
      expect(result.currentStreak, 3);
      expect(result.todayIsSafe, true);
    });

    test('lastNDays returns correct booleans', () {
      final now = DateTime(2024, 6, 12, 12, 0);
      final entries = [
        _entry('1', DateTime(2024, 6, 10, 8, 0), 80), // safe
        _entry('2', DateTime(2024, 6, 11, 20, 0), 100), // unsafe
        _entry('3', DateTime(2024, 6, 12, 8, 0), 80), // safe
      ];
      final last3 = calc.lastNDays(entries, 3, now: now);
      expect(last3, [true, false, true]);
    });
  });
}
