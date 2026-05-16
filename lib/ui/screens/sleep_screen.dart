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
import '../widgets/caffeine_curve.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    final settings = settingsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => const UserSettings(),
    );

    final entries = entriesAsync.maybeWhen(
      data: (e) => e as List<CaffeineEntry>,
      orElse: () => <CaffeineEntry>[],
    );

    final now = DateTime.now();
    final calc = CaffeineCalculator(halfLifeHours: settings.halfLifeHours);

    final bedtime = DateTime(
        now.year, now.month, now.day, settings.bedtimeHour, settings.bedtimeMinute);
    final bedMg = calc.levelAt(entries, bedtime);
    final bedH = settings.bedtimeHour + settings.bedtimeMinute / 60.0;

    final safeTime = calc.safeToSleepTime(entries, now, settings.safeThresholdMg);

    final sleepOk = bedMg < settings.safeThresholdMg;

    return Scaffold(
      backgroundColor: AppColors.night,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              AppColors.night2.withAlpha(200),
              AppColors.night,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              CTStatusBar(
                time: DateFormat('H:mm').format(now),
                dark: true,
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
                  children: [
                    // Title
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CTEyebrow('Sleep Impact'),
                    ),

                    // Glass card with curve
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withAlpha(25),
                          width: 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bedtime mg
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                bedMg.toStringAsFixed(0),
                                style: GoogleFonts.newsreader(
                                  fontSize: 88,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  height: 0.95,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'mg',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 14,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CTPill(
                                    label: sleepOk ? 'Sleep OK' : 'High caffeine',
                                    tone: sleepOk
                                        ? CTPillTone.tea
                                        : CTPillTone.burnt,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'at bedtime',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 12),

                          CaffeineCurve(
                            entries: entries,
                            now: now,
                            bedtimeHour: bedH,
                            limitMg: 400,
                            halfLifeHours: settings.halfLifeHours,
                            nightScheme: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stat strip
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        children: [
                          _NightStat(
                            label: 'Bedtime',
                            value:
                                '${settings.bedtimeHour}:${settings.bedtimeMinute.toString().padLeft(2, '0')}',
                            hint: 'target',
                          ),
                          Container(
                              width: 0.5,
                              height: 40,
                              color: Colors.white24),
                          _NightStat(
                            label: 'At bed',
                            value: '${bedMg.toStringAsFixed(0)} mg',
                            hint: sleepOk ? 'Low risk' : 'High risk',
                          ),
                          Container(
                              width: 0.5,
                              height: 40,
                              color: Colors.white24),
                          _NightStat(
                            label: 'Clears by',
                            value: safeTime != null
                                ? DateFormat('h:mm a').format(safeTime)
                                : '—',
                            hint: '< ${settings.safeThresholdMg.toStringAsFixed(0)} mg',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // White recommendation card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(Icons.coffee_outlined,
                              color: AppColors.crema, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Last safe drink',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  safeTime != null
                                      ? DateFormat('h:mm a').format(
                                          safeTime.subtract(const Duration(
                                              hours: 6)))
                                      : 'You\'re clear',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Wind-down tips
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withAlpha(20),
                          width: 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WIND-DOWN TIPS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...const [
                            'Avoid caffeine 6+ hours before bed',
                            'Dim screens 1 hour before sleep',
                            'Keep room cool (65–68°F / 18–20°C)',
                            'Consistent sleep schedule helps',
                          ].map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 16, color: Colors.white38),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
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
                activeIndex: 3,
                dark: true,
                onTap: (i) {
                  if (i == 0) context.go('/');
                  if (i == 2) context.push('/log');
                  if (i == 1) context.push('/history');
                  if (i == 4) context.push('/library');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NightStat extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _NightStat({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Text(
              hint,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
