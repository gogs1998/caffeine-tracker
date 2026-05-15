import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/heart_rate_sensitivity.dart';
import '../theme/app_theme.dart';

class HeartRateBadge extends ConsumerWidget {
  const HeartRateBadge({super.key});

  static const double _baselineHR = 65.0;
  static const _hrs = HeartRateSensitivity();

  Color _colorForHr(double? bpm) {
    if (bpm == null) return AppColors.textDisabled;
    final m = _hrs.computeMultiplier(bpm, _baselineHR);
    if (m >= 1.20) return AppColors.danger;
    if (m > 1.0) return AppColors.caution;
    return AppColors.safe;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hrAsync = ref.watch(heartRateProvider);
    return hrAsync.when(
      loading: () => const _Card(bpm: null, color: AppColors.textDisabled, isLoading: true),
      error: (_, __) => const _Card(bpm: null, color: AppColors.textDisabled),
      data: (bpm) => _Card(bpm: bpm, color: _colorForHr(bpm)),
    );
  }
}

class _Card extends StatelessWidget {
  final double? bpm;
  final Color color;
  final bool isLoading;
  const _Card({required this.bpm, required this.color, this.isLoading = false});

  void _showInfo(BuildContext context) {
    const hrs = HeartRateSensitivity();
    const baseline = 65.0;
    final m = hrs.computeMultiplier(bpm, baseline);
    final pct = ((m - 1.0) * 100).toStringAsFixed(0);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.favorite_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Heart Rate & Caffeine',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              bpm == null
                  ? 'No heart rate data available. Grant Health / HealthKit permission to enable this feature.'
                  : 'Your current heart rate is ${bpm!.toStringAsFixed(0)} bpm '
                      '(baseline: ${baseline.toStringAsFixed(0)} bpm).\n\n'
                      'This is $pct% above your baseline, so caffeine is estimated '
                      'to stay in your system $pct% longer than normal.',
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.6, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              '🟢  < +15 %   →  no adjustment\n'
              '🟡  +15 – 20 %  →  up to ×1.2\n'
              '🔴  > +20 %   →  ×1.3 (capped)',
              style: TextStyle(
                  color: AppColors.textTertiary, fontSize: 12, height: 1.8),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showInfo(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.favorite_rounded, color: color, size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Heart Rate',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.textDisabled, size: 14),
              ],
            ),
            const SizedBox(height: 10),
            isLoading
                ? const SizedBox(
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppColors.textDisabled),
                  )
                : Text(
                    bpm == null ? '– –' : '${bpm!.toStringAsFixed(0)} bpm',
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
