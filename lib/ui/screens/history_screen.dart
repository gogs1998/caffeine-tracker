import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../core/caffeine_calculator.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/caffeine_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/ct_widgets.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _rangeIndex = 0; // 0=Week, 1=Month, 2=Year
  static const _rangeLabels = ['Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    final settings = settingsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => const UserSettings(),
    );
    final entries = entriesAsync.maybeWhen(
      data: (e) => e,
      orElse: () => <CaffeineEntry>[],
    );

    // Compute daily totals for the past 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final dayEntries = entries.where((e) =>
          e.consumedAt.year == d.year &&
          e.consumedAt.month == d.month &&
          e.consumedAt.day == d.day);
      return dayEntries.fold(0.0, (s, e) => s + e.mgAmount);
    });

    final avg = days.isEmpty ? 0.0 : days.fold(0.0, (s, d) => s + d) / 7;
    final maxDay = days.fold(0.0, (a, b) => a > b ? a : b);

    final today = entries.where((e) {
      return e.consumedAt.year == now.year &&
          e.consumedAt.month == now.month &&
          e.consumedAt.day == now.day;
    }).toList();
    final totalToday = today.fold(0.0, (s, e) => s + e.mgAmount);

    final calc = CaffeineCalculator(halfLifeHours: settings.halfLifeHours);
    final currentMg = calc.levelAt(entries, now);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History',
                    style: GoogleFonts.newsreader(
                      fontSize: 28,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  ),
                  // Range toggle
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: _rangeLabels.asMap().entries.map((e) {
                        final active = e.key == _rangeIndex;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _rangeIndex = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: active ? AppColors.card : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: AppColors.ink.withAlpha(15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? AppColors.ink
                                    : AppColors.muted2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
                children: [
                  // Avg card with bar chart
                  CTCard(
                    radius: 24,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CTEyebrow('Daily average'),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                avg.toStringAsFixed(0),
                                style: GoogleFonts.newsreader(
                                  fontSize: 80,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.ink,
                                  height: 0.95,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  'mg',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Bar chart
                          SizedBox(
                            height: 80,
                            child: CustomPaint(
                              painter: _BarChartPainter(
                                  values: days, maxVal: maxDay > 0 ? maxDay : 400),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: days.asMap().entries.map((e) {
                                  final d = now.subtract(
                                      Duration(days: 6 - e.key));
                                  return Expanded(
                                    child: Center(
                                      child: Text(
                                        DateFormat('E').format(d)[0],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.muted2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2x2 mini stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _MiniStat(
                        label: 'Today',
                        value: '${totalToday.toStringAsFixed(0)} mg',
                        dotColor: AppColors.crema,
                      ),
                      _MiniStat(
                        label: 'In body now',
                        value: '${currentMg.toStringAsFixed(0)} mg',
                        dotColor: AppColors.tea,
                      ),
                      _MiniStat(
                        label: 'Peak (7d)',
                        value: '${maxDay.toStringAsFixed(0)} mg',
                        dotColor: AppColors.burnt,
                      ),
                      _MiniStat(
                        label: 'Drinks today',
                        value: '${today.length}',
                        dotColor: AppColors.night,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Insight card
                  CTCard(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.teaTn,
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.tea, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            avg < 200
                                ? 'Your average is well within the recommended limit. Great balance!'
                                : avg < 400
                                    ? 'You\'re within the limit but close to recommended daily max of 400 mg.'
                                    : 'Your 7-day average exceeds 400 mg/day. Consider cutting back.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.tea,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            CTTabBar(
              activeIndex: 1,
              onTap: (i) {
                if (i == 0) context.go('/');
                if (i == 2) context.push('/log');
                if (i == 3) context.push('/sleep');
                if (i == 4) context.push('/library');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return CTCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final double maxVal;

  const _BarChartPainter({required this.values, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    final barW = (size.width / values.length) * 0.55;
    final gap = (size.width / values.length) * 0.45;
    final chartH = size.height - 18; // space for labels

    for (int i = 0; i < values.length; i++) {
      final isToday = i == values.length - 1;
      final barH = maxVal > 0 ? (values[i] / maxVal) * chartH : 0.0;
      final x = i * (barW + gap) + gap / 2;
      final y = chartH - barH;

      final paint = Paint()
        ..color = isToday ? AppColors.crema : AppColors.bg2
        ..style = PaintingStyle.fill;

      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rr, paint);
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.values != values;
}
