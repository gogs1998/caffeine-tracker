/// Computes a caffeine sensitivity multiplier based on current heart rate.
///
/// Logic:
///   - Resting HR baseline is assumed to be [baselineHR] (default 65 bpm).
///   - If heart rate is within 15 % of baseline → multiplier = 1.0 (no change).
///   - If heart rate >= baseline × 1.15  → caffeine is elevating HR;
///     bump multiplier linearly up to 1.3 (capped) at baseline × 1.30.
///
/// Formula in the elevated zone (hr >= threshold):
///   ratio = (hr - threshold) / (baseline * 0.15)   // 0.0 → 1.0
///   multiplier = 1.0 + 0.3 * ratio.clamp(0, 1)
class HeartRateSensitivity {
  const HeartRateSensitivity();

  /// Returns a multiplier in the range [1.0, 1.3].
  ///
  /// [heartRateBpm] — current heart rate reading (null → returns 1.0).
  /// [baselineHR]   — assumed resting HR in bpm (default 65).
  double computeMultiplier(double? heartRateBpm,
      [double baselineHR = 65.0]) {
    if (heartRateBpm == null) return 1.0;

    final threshold = baselineHR * 1.15;

    if (heartRateBpm < threshold) return 1.0;

    // Linearly scale 0 → 0.3 over the band [baseline×1.15, baseline×1.30].
    final band = baselineHR * 0.15; // width of the band
    final ratio = ((heartRateBpm - threshold) / band).clamp(0.0, 1.0);
    return 1.0 + 0.3 * ratio;
  }
}
