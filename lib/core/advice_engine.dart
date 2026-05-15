/// Pure Dart, no Flutter imports — fully testable without a device.
library;

enum AdviceLevel { ok, caution, warning }

class CaffeineState {
  final double currentMg;
  final double peakMg;
  final double? heartRateBpm;
  final DateTime? safeToSleepAt;
  final DateTime bedtime;
  final bool glp1Mode;
  final String? glp1Medication;
  final double halfLifeHours;
  final int totalDrinksToday;
  final DateTime now;

  const CaffeineState({
    required this.currentMg,
    required this.peakMg,
    this.heartRateBpm,
    this.safeToSleepAt,
    required this.bedtime,
    required this.glp1Mode,
    this.glp1Medication,
    required this.halfLifeHours,
    required this.totalDrinksToday,
    required this.now,
  });
}

class CaffeineAdvice {
  final String headline;
  final String body;
  final AdviceLevel level;
  final List<String> tips;

  const CaffeineAdvice({
    required this.headline,
    required this.body,
    required this.level,
    required this.tips,
  });
}

class AdviceEngine {
  const AdviceEngine();

  CaffeineAdvice assess(CaffeineState state) {
    // Rule 1 — over daily safe limit
    if (state.currentMg > 400) {
      return CaffeineAdvice(
        headline: "You've hit the daily safe limit",
        body:
            'Your current caffeine level (${state.currentMg.toStringAsFixed(0)} mg) '
            'exceeds the 400 mg recommended maximum. '
            'High intake increases the risk of jitteriness, anxiety and disrupted sleep.',
        level: AdviceLevel.warning,
        tips: [
          'Stop all caffeinated drinks for the rest of the day.',
          'Switch to herbal tea or water.',
          'Rest and allow your body to metabolise the caffeine naturally.',
          'Consider an earlier bedtime tonight.',
        ],
      );
    }

    // Rule 2 — too much caffeine too late (safe sleep time is after bedtime)
    if (state.currentMg > 200 &&
        state.safeToSleepAt != null &&
        state.safeToSleepAt!.isAfter(state.bedtime)) {
      final diff = state.safeToSleepAt!.difference(state.bedtime);
      final overMins = diff.inMinutes;
      return CaffeineAdvice(
        headline: 'Too much caffeine too late',
        body:
            "At ${state.currentMg.toStringAsFixed(0)} mg you won't reach a safe sleep level "
            'until roughly $overMins minute${overMins == 1 ? '' : 's'} after your bedtime. '
            'Caffeine in your system at bedtime reduces sleep quality and delays sleep onset.',
        level: AdviceLevel.warning,
        tips: [
          'Stop caffeine intake now.',
          'Switch to decaf or herbal tea for the remainder of the evening.',
          'Consider pushing bedtime back slightly to let levels drop.',
          'Avoid caffeine after ${_formatHour(state.bedtime.hour - 6)} tomorrow.',
        ],
      );
    }

    // Rule 3 — elevated heart rate
    if (state.heartRateBpm != null && state.heartRateBpm! > 100) {
      return CaffeineAdvice(
        headline: 'Elevated heart rate detected',
        body:
            'Your heart rate (${state.heartRateBpm!.toStringAsFixed(0)} bpm) is above 100. '
            'Caffeine is a stimulant that can elevate heart rate; '
            'it is wise to pause intake and let your body settle.',
        level: AdviceLevel.caution,
        tips: [
          'Hold off on any more caffeine for now.',
          'Drink a glass of water to stay hydrated.',
          'Do a few minutes of slow, deep breathing.',
          'If your heart rate stays elevated, consult a healthcare provider.',
        ],
      );
    }

    // Rule 4 — GLP-1 + moderate caffeine
    if (state.glp1Mode && state.currentMg > 150) {
      final med = state.glp1Medication != null
          ? ' (${state.glp1Medication})'
          : '';
      return CaffeineAdvice(
        headline: 'GLP-1 slows caffeine metabolism — go easy',
        body:
            'Your GLP-1 medication$med slows gastric emptying, which can extend '
            'how long caffeine stays active in your body. '
            'At ${state.currentMg.toStringAsFixed(0)} mg you may feel effects more strongly than expected.',
        level: AdviceLevel.caution,
        tips: [
          'Wait longer between drinks than you normally would.',
          'Stick to a single serving at a time.',
          'Prefer half-caff or decaf options for your next drink.',
          'Monitor for jitteriness or nausea — common signs of caffeine sensitivity on GLP-1s.',
        ],
      );
    }

    // Rule 5 — safe-sleep time is within 30 minutes of bedtime
    if (state.safeToSleepAt != null) {
      final gap = state.bedtime.difference(state.safeToSleepAt!);
      if (gap.inMinutes >= 0 && gap.inMinutes <= 30) {
        return CaffeineAdvice(
          headline: 'Cutting it close to bedtime',
          body:
              "You'll reach a safe caffeine level about ${gap.inMinutes} minute${gap.inMinutes == 1 ? '' : 's'} "
              'before your bedtime — that is very close. '
              'Even small residual amounts can reduce sleep depth.',
          level: AdviceLevel.caution,
          tips: [
            'Avoid any more caffeine today.',
            'A relaxing wind-down routine will help bridge the gap.',
            'Keep the room cool and dark to maximise sleep quality.',
          ],
        );
      }
    }

    // Rule 6 — low level, early in the day
    if (state.currentMg < 50 && state.now.hour < 14) {
      return CaffeineAdvice(
        headline: "Good level — you're in the zone",
        body:
            'Your caffeine level (${state.currentMg.toStringAsFixed(0)} mg) is low and comfortable. '
            'If you need a boost, now is a great time for a drink — '
            "you'll have plenty of time to metabolise it before bed.",
        level: AdviceLevel.ok,
        tips: [
          'One coffee or tea now is a great choice.',
          'Stay hydrated — alternate caffeinated drinks with water.',
          'Avoid caffeine after early afternoon to protect your sleep.',
        ],
      );
    }

    // Rule 7 — default OK
    return CaffeineAdvice(
      headline: "You're on track",
      body:
          'Your caffeine intake (${state.currentMg.toStringAsFixed(0)} mg) looks fine. '
          'Keep an eye on the decay curve and stop well before bedtime.',
      level: AdviceLevel.ok,
      tips: [
        'Keep an eye on your total intake across the day.',
        'Aim to finish caffeine at least 6 hours before your bedtime.',
        'Stay hydrated with water between drinks.',
      ],
    );
  }

  String _formatHour(int hour) {
    final h = hour.clamp(0, 23);
    final period = h >= 12 ? 'PM' : 'AM';
    final display = h % 12 == 0 ? 12 : h % 12;
    return '$display:00 $period';
  }
}
