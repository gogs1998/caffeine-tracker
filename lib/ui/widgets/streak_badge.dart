import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/streak_calculator.dart';

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
        final streakData = calc.calculate(entries);

        return GestureDetector(
          onTap: () => _showStreakSheet(context, entries, calc),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: streakData.currentStreak > 0
                    ? Colors.orange.withAlpha(120)
                    : Colors.white12,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${streakData.currentStreak} day streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Best: ${streakData.longestStreak} days',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      streakData.todayIsSafe
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      color: streakData.todayIsSafe
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      streakData.todayIsSafe ? 'Today ✓' : 'At risk',
                      style: TextStyle(
                        color: streakData.todayIsSafe
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right,
                        color: Colors.white30, size: 18),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStreakSheet(
      BuildContext context, dynamic entries, StreakCalculator calc) {
    final last7 = calc.lastNDays(entries, 7);
    final now = DateTime.now();
    final dayNames = <String>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      dayNames.add(i == 0
          ? 'Today'
          : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔥 Streak History',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Days where evening caffeine was below your threshold',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final safe = last7[i];
                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: safe
                            ? Colors.greenAccent.withAlpha(40)
                            : Colors.redAccent.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: safe ? Colors.greenAccent : Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          safe ? '✓' : '✗',
                          style: TextStyle(
                            color:
                                safe ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayNames[i],
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
