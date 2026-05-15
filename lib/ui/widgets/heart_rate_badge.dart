import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/heart_rate_sensitivity.dart';

/// A small card showing the current heart rate (bpm) with a colour-coded
/// indicator reflecting the caffeine-sensitivity impact:
///
///   - Green  → within resting range (< baseline × 1.15)
///   - Amber  → mildly elevated (baseline × 1.15 – 1.30)
///   - Red    → significantly elevated (>= baseline × 1.30)
///
/// Tapping the card shows a bottom sheet explaining the heart rate → caffeine
/// sensitivity relationship.
class HeartRateBadge extends ConsumerWidget {
  const HeartRateBadge({super.key});

  static const double _baselineHR = 65.0;
  static const _hrs = HeartRateSensitivity();

  Color _colourForHr(double? bpm) {
    if (bpm == null) return Colors.white24;
    final multiplier = _hrs.computeMultiplier(bpm, _baselineHR);
    if (multiplier >= 1.20) return Colors.redAccent;
    if (multiplier > 1.0) return Colors.amber;
    return Colors.greenAccent;
  }

  String _labelForHr(double? bpm) {
    if (bpm == null) return '– –';
    return '${bpm.toStringAsFixed(0)} bpm';
  }

  void _showExplanation(BuildContext context, double? bpm) {
    final multiplier = _hrs.computeMultiplier(bpm, _baselineHR);
    final pct = ((multiplier - 1.0) * 100).toStringAsFixed(0);
    final colour = _colourForHr(bpm);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: colour, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Heart Rate & Caffeine',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              bpm == null
                  ? 'No heart rate data available. Grant Health / HealthKit '
                      'permission to enable this feature.'
                  : 'Your current heart rate is ${bpm.toStringAsFixed(0)} bpm '
                      '(baseline: ${_baselineHR.toStringAsFixed(0)} bpm).\n\n'
                      'This is $pct% above your sensitivity baseline, '
                      'so the caffeine decay model is running with a ×${multiplier.toStringAsFixed(2)} '
                      'sensitivity multiplier — meaning caffeine is estimated to '
                      'stay in your system $pct% longer than normal.',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '🟢 Green  < +15 % above resting  →  no adjustment\n'
              '🟡 Amber  +15 – 30 %  →  up to ×1.2 sensitivity\n'
              '🔴 Red    > +30 %  →  ×1.3 sensitivity (capped)',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartRateAsync = ref.watch(heartRateProvider);

    return heartRateAsync.when(
      loading: () => _buildCard(context, null, isLoading: true),
      error: (_, __) => _buildCard(context, null),
      data: (bpm) => _buildCard(context, bpm),
    );
  }

  Widget _buildCard(BuildContext context, double? bpm,
      {bool isLoading = false}) {
    final colour = _colourForHr(bpm);

    return GestureDetector(
      onTap: () => _showExplanation(context, bpm),
      child: Card(
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.favorite, color: colour, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Heart Rate',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white38),
                )
              else
                Text(
                  _labelForHr(bpm),
                  style: TextStyle(
                    color: colour,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.info_outline, color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
