import 'package:flutter_test/flutter_test.dart';
import 'package:caffeine_tracker/core/heart_rate_sensitivity.dart';

void main() {
  const hrs = HeartRateSensitivity();
  const baseline = 65.0;

  group('HeartRateSensitivity.computeMultiplier', () {
    test('null HR → 1.0', () {
      expect(hrs.computeMultiplier(null, baseline), 1.0);
    });

    test('HR == baseline → 1.0', () {
      expect(hrs.computeMultiplier(baseline, baseline), 1.0);
    });

    test('HR just below threshold (baseline * 1.14) → 1.0', () {
      const hr = baseline * 1.14;
      expect(hrs.computeMultiplier(hr, baseline), 1.0);
    });

    test('HR == baseline * 1.15 → 1.0 (threshold boundary)', () {
      const hr = baseline * 1.15;
      // Exactly at threshold: ratio = 0 → multiplier = 1.0
      expect(hrs.computeMultiplier(hr, baseline), closeTo(1.0, 0.001));
    });

    test('HR == baseline * 1.225 (midpoint) → ~1.15', () {
      // midpoint of [1.15, 1.30] → ratio = 0.5 → multiplier = 1.15
      const hr = baseline * 1.225;
      expect(hrs.computeMultiplier(hr, baseline), closeTo(1.15, 0.01));
    });

    test('HR == baseline * 1.30 → 1.3 (cap)', () {
      const hr = baseline * 1.30;
      expect(hrs.computeMultiplier(hr, baseline), closeTo(1.3, 0.001));
    });

    test('HR well above baseline * 1.30 → capped at 1.3', () {
      const hr = baseline * 2.0;
      expect(hrs.computeMultiplier(hr, baseline), closeTo(1.3, 0.001));
    });

    test('default baseline (65) used when omitted with null', () {
      expect(hrs.computeMultiplier(null), 1.0);
    });
  });
}
