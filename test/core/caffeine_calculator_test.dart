import 'package:flutter_test/flutter_test.dart';
import 'package:caffeine_tracker/core/caffeine_calculator.dart';
import 'package:caffeine_tracker/data/models/caffeine_entry.dart';

void main() {
  const halfLife = 5.0; // hours
  const calc = CaffeineCalculator(halfLifeHours: halfLife);

  final t0 = DateTime(2024, 1, 1, 8, 0); // 08:00

  CaffeineEntry entry({
    String id = '1',
    double mg = 200,
    DateTime? at,
  }) =>
      CaffeineEntry(
        id: id,
        drinkName: 'Coffee',
        mgAmount: mg,
        consumedAt: at ?? t0,
      );

  group('CaffeineCalculator.levelAt', () {
    test('200mg at t=0 → 200mg at t=0', () {
      final result = calc.levelAt([entry()], t0);
      expect(result, closeTo(200.0, 0.001));
    });

    test('200mg at t=0 → 100mg after 5 hours (one half-life)', () {
      final fiveHoursLater = t0.add(const Duration(hours: 5));
      final result = calc.levelAt([entry()], fiveHoursLater);
      expect(result, closeTo(100.0, 0.001));
    });

    test('no doses → 0mg', () {
      final result = calc.levelAt([], t0);
      expect(result, 0.0);
    });

    test('two doses stack and decay correctly', () {
      final e1 = entry(id: '1', mg: 200, at: t0);
      final e2 = entry(id: '2', mg: 100, at: t0);
      // At t0: 200 + 100 = 300
      final atT0 = calc.levelAt([e1, e2], t0);
      expect(atT0, closeTo(300.0, 0.001));

      // After 5 hours: 100 + 50 = 150
      final fiveHoursLater = t0.add(const Duration(hours: 5));
      final after5 = calc.levelAt([e1, e2], fiveHoursLater);
      expect(after5, closeTo(150.0, 0.001));
    });

    test('entry consumed in the future is ignored', () {
      final futureEntry = entry(at: t0.add(const Duration(hours: 2)));
      final result = calc.levelAt([futureEntry], t0);
      expect(result, 0.0);
    });
  });

  group('CaffeineCalculator.currentLevel', () {
    test('delegates to levelAt with DateTime.now() equivalent', () {
      // Simply verify it does not throw and returns >= 0
      final result = calc.currentLevel([entry()], t0);
      expect(result, greaterThanOrEqualTo(0.0));
    });
  });

  group('CaffeineCalculator.safeToSleepTime', () {
    test('200mg, threshold=50mg → ~14.35 hours after dose (log2(4) * 5h)', () {
      // 200 * (0.5)^(t/5) = 50  →  t = 5 * log2(4) = 10 hours
      const threshold = 50.0;
      final result = calc.safeToSleepTime([entry()], t0, threshold);
      expect(result, isNotNull);
      // Expected: t0 + 10 hours
      final expected = t0.add(const Duration(hours: 10));
      expect(
        result!.difference(expected).inMinutes.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('no doses → returns null (already safe)', () {
      final result = calc.safeToSleepTime([], t0, 50.0);
      expect(result, isNull);
    });

    test('already below threshold → returns null', () {
      // Level at t0 is 10mg which is below 50mg threshold
      final smallEntry = entry(mg: 10);
      final result = calc.safeToSleepTime([smallEntry], t0, 50.0);
      expect(result, isNull);
    });
  });

  group('CaffeineCalculator.decayCurve', () {
    test('returns correct number of points', () {
      final to = t0.add(const Duration(hours: 24));
      final curve = calc.decayCurve([entry()], t0, to, points: 25);
      expect(curve.length, 25);
    });

    test('curve starts at mgAmount and decays to near-zero', () {
      final to = t0.add(const Duration(hours: 48));
      final curve = calc.decayCurve([entry()], t0, to);
      expect(curve.first.value, closeTo(200.0, 0.001));
      expect(curve.last.value, lessThan(5.0));
    });

    test('empty entries → all zeros', () {
      final to = t0.add(const Duration(hours: 10));
      final curve = calc.decayCurve([], t0, to, points: 10);
      for (final point in curve) {
        expect(point.value, 0.0);
      }
    });
  });

  group('sensitivityMultiplier', () {
    test('multiplier=2.0 doubles effective half-life', () {
      const slowCalc =
          CaffeineCalculator(halfLifeHours: halfLife, sensitivityMultiplier: 2.0);
      // With multiplier=2, effective half-life becomes 10h
      // 200mg after 10h should be ~100mg
      final tenHoursLater = t0.add(const Duration(hours: 10));
      final result = slowCalc.levelAt([entry()], tenHoursLater);
      expect(result, closeTo(100.0, 0.001));
    });
  });
}
