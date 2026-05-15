import 'package:flutter_test/flutter_test.dart';
import 'package:caffeine_tracker/core/advice_engine.dart';

void main() {
  const engine = AdviceEngine();

  // Helper: build a baseline state and allow overriding fields
  CaffeineState base({
    double currentMg = 100,
    double peakMg = 100,
    double? heartRateBpm,
    DateTime? safeToSleepAt,
    DateTime? bedtime,
    bool glp1Mode = false,
    String? glp1Medication,
    double halfLifeHours = 5.0,
    int totalDrinksToday = 1,
    DateTime? now,
  }) {
    final n = now ?? DateTime(2025, 6, 1, 10, 0); // 10:00 AM
    return CaffeineState(
      currentMg: currentMg,
      peakMg: peakMg,
      heartRateBpm: heartRateBpm,
      safeToSleepAt: safeToSleepAt,
      bedtime: bedtime ?? DateTime(2025, 6, 1, 23, 0),
      glp1Mode: glp1Mode,
      glp1Medication: glp1Medication,
      halfLifeHours: halfLifeHours,
      totalDrinksToday: totalDrinksToday,
      now: n,
    );
  }

  group('Rule 1 — over 400 mg', () {
    test('currentMg = 401 → warning about daily limit', () {
      final advice = engine.assess(base(currentMg: 401, peakMg: 401));
      expect(advice.level, AdviceLevel.warning);
      expect(advice.headline, contains('daily safe limit'));
    });

    test('currentMg = 400 exactly → does NOT trigger rule 1', () {
      final advice = engine.assess(base(currentMg: 400, peakMg: 400));
      expect(advice.level, isNot(AdviceLevel.warning));
    });
  });

  group('Rule 2 — too much caffeine too late', () {
    test('currentMg > 200 and safeToSleepAt after bedtime → warning', () {
      final bedtime = DateTime(2025, 6, 1, 23, 0);
      final safeAt = DateTime(2025, 6, 2, 1, 0); // 2 AM — after bedtime
      final advice = engine.assess(base(
        currentMg: 250,
        peakMg: 250,
        safeToSleepAt: safeAt,
        bedtime: bedtime,
      ));
      expect(advice.level, AdviceLevel.warning);
      expect(advice.headline, contains('Too much caffeine too late'));
    });

    test('currentMg = 180 (≤200) does not trigger rule 2 even if late', () {
      final bedtime = DateTime(2025, 6, 1, 23, 0);
      final safeAt = DateTime(2025, 6, 2, 1, 0);
      final advice = engine.assess(base(
        currentMg: 180,
        peakMg: 180,
        safeToSleepAt: safeAt,
        bedtime: bedtime,
      ));
      // Should not be rule-2 warning; may still be ok/caution from other rules
      expect(
          advice.headline, isNot(contains('Too much caffeine too late')));
    });
  });

  group('Rule 3 — elevated heart rate', () {
    test('heartRate = 105 → caution about heart rate', () {
      final advice = engine.assess(base(heartRateBpm: 105));
      expect(advice.level, AdviceLevel.caution);
      expect(advice.headline, contains('heart rate'));
    });

    test('heartRate = 100 exactly → does not trigger rule 3', () {
      final advice = engine.assess(base(heartRateBpm: 100));
      expect(advice.headline, isNot(contains('heart rate')));
    });

    test('no heartRate → no heart-rate caution', () {
      final advice = engine.assess(base());
      expect(advice.headline, isNot(contains('heart rate')));
    });
  });

  group('Rule 4 — GLP-1 + currentMg > 150', () {
    test('glp1Mode=true, currentMg=200 → caution about GLP-1', () {
      final advice =
          engine.assess(base(glp1Mode: true, currentMg: 200, peakMg: 200));
      expect(advice.level, AdviceLevel.caution);
      expect(advice.headline, contains('GLP-1'));
    });

    test('glp1Mode=true, currentMg=100 (≤150) → no GLP-1 caution', () {
      final advice =
          engine.assess(base(glp1Mode: true, currentMg: 100, peakMg: 100));
      expect(advice.headline, isNot(contains('GLP-1')));
    });

    test('glp1Mode=false, currentMg=200 → no GLP-1 caution', () {
      final advice =
          engine.assess(base(glp1Mode: false, currentMg: 200, peakMg: 200));
      expect(advice.headline, isNot(contains('GLP-1')));
    });
  });

  group('Rule 5 — safeToSleepAt within 30 min of bedtime', () {
    test('safeToSleepAt 20 min before bedtime → caution cutting it close', () {
      final bedtime = DateTime(2025, 6, 1, 23, 0);
      final safeAt = DateTime(2025, 6, 1, 22, 40); // 20 min before bedtime
      final advice = engine.assess(base(
        currentMg: 80,
        peakMg: 80,
        safeToSleepAt: safeAt,
        bedtime: bedtime,
      ));
      expect(advice.level, AdviceLevel.caution);
      expect(advice.headline, contains('close to bedtime'));
    });

    test('safeToSleepAt 60 min before bedtime → does not trigger rule 5', () {
      final bedtime = DateTime(2025, 6, 1, 23, 0);
      final safeAt = DateTime(2025, 6, 1, 22, 0); // 60 min before bedtime
      final advice = engine.assess(base(
        currentMg: 80,
        peakMg: 80,
        safeToSleepAt: safeAt,
        bedtime: bedtime,
      ));
      expect(advice.headline, isNot(contains('close to bedtime')));
    });
  });

  group('Rule 6 — low level, early day', () {
    test('currentMg=30, hour=10 → ok, in the zone', () {
      final advice = engine.assess(base(
        currentMg: 30,
        peakMg: 30,
        now: DateTime(2025, 6, 1, 10, 0),
      ));
      expect(advice.level, AdviceLevel.ok);
      expect(advice.headline, contains('in the zone'));
    });

    test('currentMg=30 but hour=15 → does not trigger rule 6', () {
      final advice = engine.assess(base(
        currentMg: 30,
        peakMg: 30,
        now: DateTime(2025, 6, 1, 15, 0),
      ));
      expect(advice.headline, isNot(contains('in the zone')));
    });
  });

  group('Rule 7 — default ok', () {
    test('moderate caffeine, no special conditions → on track', () {
      final advice = engine.assess(base(currentMg: 120, peakMg: 120));
      expect(advice.level, AdviceLevel.ok);
      expect(advice.headline, contains('on track'));
    });
  });
}
