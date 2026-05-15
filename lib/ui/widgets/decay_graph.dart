import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';

class DecayGraph extends ConsumerStatefulWidget {
  const DecayGraph({super.key});

  @override
  ConsumerState<DecayGraph> createState() => _DecayGraphState();
}

class _DecayGraphState extends ConsumerState<DecayGraph> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final calc = ref.watch(calculatorProvider);

    return entriesAsync.when(
      loading: () =>
          const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          SizedBox(height: 250, child: Center(child: Text('Error: $e'))),
      data: (entries) {
        final settings = settingsAsync.valueOrNull;
        final threshold = settings?.safeThresholdMg ?? 50.0;
        final bedtimeHour = settings?.bedtimeHour ?? 23;
        final bedtimeMinute = settings?.bedtimeMinute ?? 0;

        final now = DateTime.now();
        final windowStart = now.subtract(const Duration(hours: 8));
        final windowEnd = now.add(const Duration(hours: 16));

        // Bedtime today (or tomorrow if already past)
        var bedtime = DateTime(
          now.year, now.month, now.day, bedtimeHour, bedtimeMinute);
        if (bedtime.isBefore(now)) {
          bedtime = bedtime.add(const Duration(days: 1));
        }

        final curve = calc.decayCurve(entries, windowStart, windowEnd, points: 100);

        // Find peak for Y axis
        final peak = curve.fold<double>(
            0, (prev, e) => e.value > prev ? e.value : prev);
        final yMax = (peak * 1.2).clamp(threshold * 2, double.infinity);

        // Convert to FlSpot (x = minutes from windowStart)
        final spots = curve.map((e) {
          final x = e.key.difference(windowStart).inSeconds / 60.0;
          return FlSpot(x, e.value);
        }).toList();

        final totalMinutes = windowEnd.difference(windowStart).inSeconds / 60.0;
        final nowX = now.difference(windowStart).inSeconds / 60.0;
        final bedtimeX = bedtime.difference(windowStart).inSeconds / 60.0;

        return SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: totalMinutes,
                minY: 0,
                maxY: yMax,
                clipData: const FlClipData.all(),
                // ── Extra lines: now, bedtime, threshold ──────────────────
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    // Now — yellow
                    VerticalLine(
                      x: nowX,
                      color: Colors.yellow,
                      strokeWidth: 2,
                      label: VerticalLineLabel(
                        show: true,
                        labelResolver: (_) => 'Now',
                        style: const TextStyle(
                            color: Colors.yellow, fontSize: 10),
                        alignment: Alignment.topRight,
                      ),
                    ),
                    // Bedtime — red dashed
                    if (bedtimeX >= 0 && bedtimeX <= totalMinutes)
                      VerticalLine(
                        x: bedtimeX,
                        color: Colors.redAccent,
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: VerticalLineLabel(
                          show: true,
                          labelResolver: (_) => 'Bed',
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 10),
                          alignment: Alignment.topLeft,
                        ),
                      ),
                  ],
                  horizontalLines: [
                    // Safe threshold — green dashed
                    HorizontalLine(
                      y: threshold,
                      color: Colors.greenAccent,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) =>
                            '${threshold.toStringAsFixed(0)} mg',
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 10),
                        alignment: Alignment.topRight,
                      ),
                    ),
                  ],
                ),
                // ── Decay line ────────────────────────────────────────────
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      // Shaded red area above threshold past bedtime
                      color: Colors.red.withAlpha(40),
                      applyCutOffY: true,
                      cutOffY: threshold,
                    ),
                  ),
                ],
                // ── Touch tooltip ─────────────────────────────────────────
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.grey[900]!,
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final t = windowStart.add(
                            Duration(seconds: (s.x * 60).round()));
                        final timeStr = DateFormat('HH:mm').format(t);
                        return LineTooltipItem(
                          '$timeStr\n${s.y.toStringAsFixed(1)} mg',
                          const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                // ── Axes ──────────────────────────────────────────────────
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 120, // every 2 hours
                      getTitlesWidget: (value, _) {
                        final t = windowStart
                            .add(Duration(seconds: (value * 60).round()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('HH:mm').format(t),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                 getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.white12, strokeWidth: 0.5),
                 getDrawingVerticalLine: (_) =>
                      const FlLine(color: Colors.white12, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
