import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../core/caffeine_calculator.dart';
import '../../data/models/caffeine_entry.dart';
import '../../data/models/user_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/ct_widgets.dart';
import '../widgets/caffeine_curve.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: entriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.crema),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) {
          final settings = settingsAsync.maybeWhen(
            data: (s) => s,
            orElse: () => const UserSettings(),
          );
          return _HomeBody(
            entries: entries,
            settings: settings,
            ref: ref,
          );
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final List<CaffeineEntry> entries;
  final UserSettings settings;
  final WidgetRef ref;

  const _HomeBody({
    required this.entries,
    required this.settings,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final calc = CaffeineCalculator(halfLifeHours: settings.halfLifeHours);
    const dailyLimit = 400.0;

    // Today's entries
    final today = entries.where((e) =>
        e.consumedAt.year == now.year &&
        e.consumedAt.month == now.month &&
        e.consumedAt.day == now.day).toList()
      ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

    final totalMg = today.fold(0.0, (s, e) => s + e.mgAmount);
    final nowMg = calc.levelAt(entries, now);

    final bedtime = DateTime(
        now.year, now.month, now.day, settings.bedtimeHour, settings.bedtimeMinute);
    final bedMg = calc.levelAt(entries, bedtime);

    final clearTime = calc.safeToSleepTime(entries, now, 10.0);
    final clearStr = clearTime != null
        ? DateFormat('h:mm a').format(clearTime)
        : '—';

    final pct = (totalMg / dailyLimit).clamp(0.0, 1.0);
    final isOver = totalMg > dailyLimit;

    final bedH = settings.bedtimeHour + settings.bedtimeMinute / 60.0;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Status bar
          CTStatusBar(time: DateFormat('H:mm').format(now)),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 4),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.crema, AppColors.cremaDk],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      settings.name.isNotEmpty
                          ? settings.name[0].toLowerCase()
                          : 'g',
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: AppColors.bg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CTEyebrow(DateFormat('EEEE').format(now)),
                    Text(
                      DateFormat('MMMM d').format(now),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Bell button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withAlpha(10),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      size: 18, color: AppColors.ink),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 130),
              children: [
                // Hero card
                CTCard(
                  radius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const CTEyebrow('Today'),
                            CTPill(
                              label: isOver ? 'Over limit' : 'Below limit',
                              tone: isOver ? CTPillTone.burnt : CTPillTone.tea,
                              dotColor: isOver ? '#B23A28' : '#5F7A3F',
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  totalMg.toStringAsFixed(0),
                                  style: displayStyle(size: 88),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Text(
                                    'mg',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 13,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'OF 400 MG DAILY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(pct * 100).round()}% · ${(dailyLimit - totalMg).abs().toStringAsFixed(0)} mg ${isOver ? 'over' : 'left'}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Caffeine curve
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
                        child: CaffeineCurve(
                          entries: entries,
                          now: now,
                          bedtimeHour: bedH,
                          limitMg: dailyLimit,
                          halfLifeHours: settings.halfLifeHours,
                        ),
                      ),

                      // Stat strip
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.line, width: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              _Stat(
                                label: 'Now',
                                value: '${nowMg.toStringAsFixed(0)} mg',
                                hint: 'in body',
                              ),
                              _StatDivider(),
                              _Stat(
                                label:
                                    'Bed · ${settings.bedtimeHour}:${settings.bedtimeMinute.toString().padLeft(2, '0')}',
                                value: '${bedMg.toStringAsFixed(0)} mg',
                                hint: bedMg < 50
                                    ? 'Low risk'
                                    : bedMg < 100
                                        ? 'Moderate'
                                        : 'High risk',
                                tone: bedMg < 50
                                    ? 'tea'
                                    : bedMg < 100
                                        ? 'crema'
                                        : 'burnt',
                              ),
                              _StatDivider(),
                              _Stat(
                                label: 'Clears by',
                                value: clearStr,
                                hint: '< 10 mg',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // "N logged today" header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${today.length}',
                          style: GoogleFonts.newsreader(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'logged today',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Drink rows
                if (today.isEmpty)
                  const CTCard(
                    padding: EdgeInsets.symmetric(
                        vertical: 32, horizontal: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.coffee_outlined,
                              size: 32, color: AppColors.muted2),
                          SizedBox(height: 8),
                          Text(
                            'No drinks logged today',
                            style: TextStyle(
                                color: AppColors.muted2, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...today.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DrinkRow(entry: e, ref: ref),
                      )),
              ],
            ),
          ),

          // Bottom tab bar
          CTTabBar(
            activeIndex: 0,
            onTap: (i) {
              if (i == 2) {
                context.push('/log');
              } else if (i == 4) {
                context.push('/library');
              } else if (i == 1) {
                context.push('/history');
              } else if (i == 3) {
                context.push('/sleep');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final String tone;

  const _Stat({
    required this.label,
    required this.value,
    required this.hint,
    this.tone = 'neutral',
  });

  Color get _valueColor {
    switch (tone) {
      case 'tea':
        return AppColors.tea;
      case 'crema':
        return AppColors.cremaDk;
      case 'burnt':
        return AppColors.burnt;
      default:
        return AppColors.ink;
    }
  }

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
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _valueColor,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              hint,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 48,
      color: AppColors.line,
    );
  }
}

class _DrinkRow extends StatelessWidget {
  final CaffeineEntry entry;
  final WidgetRef ref;

  const _DrinkRow({required this.entry, required this.ref});

  String get _kind {
    final name = entry.drinkName.toLowerCase();
    if (name.contains('espresso') || name.contains('cortado') ||
        name.contains('cappuccino') || name.contains('latte')) return 'espresso';
    if (name.contains('matcha')) return 'matcha';
    if (name.contains('tea')) return 'tea';
    if (name.contains('energy') || name.contains('red bull') ||
        name.contains('monster')) return 'energy';
    if (name.contains('soda') || name.contains('cola') ||
        name.contains('coke')) return 'soda';
    return 'coffee';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.burntTn,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.burnt, size: 20),
      ),
      onDismissed: (_) async {
        await ref.read(caffeineRepositoryProvider).delete(entry.id);
        ref.invalidate(entriesProvider);
        ref.invalidate(currentLevelProvider);
      },
      child: Container(
        decoration: surfaceCard(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: DrinkIcon(kind: _kind, size: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.drinkName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(entry.consumedAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              entry.mgAmount.toStringAsFixed(0),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            Text(
              ' mg',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
