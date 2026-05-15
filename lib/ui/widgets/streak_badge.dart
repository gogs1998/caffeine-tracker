import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/streak_calculator.dart';
import '../theme/app_theme.dart';

class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return entriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        final threshold = settingsAsync.maybeWhen(
          data: (s) => s.safeThresholdMg,
          orElse: () => 50.0,
        );
        final calc = StreakCalculator(safeThresholdMg: threshold);
        final data = calc.calculate(entries);

        return GestureDetector(
          onTap: () => _showSheet(context, entries, calc),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: data.currentStreak > 0
                    ? AppColors.orange.withAlpha(80)
                    : AppColors.glassBorder,
              ),
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
                        color: AppColors.orange.withAlpha(22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🔥',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Streak',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      data.todayIsSafe
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: data.todayIsSafe
                          ? AppColors.safe
                          : AppColors.caution,
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${data.currentStreak} days',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Best: ${data.longestStreak}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSheet(BuildContext context, dynamic entries, StreakCalculator calc) {
    final last7 = calc.lastNDays(entries, 7);
    final now = DateTime.now();
    const dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return i == 6 ? 'Today' : dayAbbr[d.weekday - 1];
    });

    showModalBottomSheet(
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
            const Text(
              'Streak History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Days where evening caffeine stayed below your threshold',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final safe = last7[i];
                final color = safe ? AppColors.safe : AppColors.danger;
                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withAlpha(80)),
                      ),
                      child: Center(
                        child: Text(
                          safe ? '✓' : '✗',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
