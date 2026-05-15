import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../data/models/user_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/current_level_card.dart';
import '../widgets/decay_graph.dart';
import '../widgets/heart_rate_badge.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/advice_card.dart';
import '../widgets/streak_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(UserSettings s, double mg) {
    final h = DateTime.now().hour;
    final name = s.name;
    if (h < 12) {
      return mg > s.safeThresholdMg ? 'Steady there, $name' : 'Good morning, $name';
    } else if (h < 18) {
      return mg > s.safeThresholdMg * 2 ? 'Easy on the coffee, $name' : 'Good afternoon, $name';
    } else {
      return mg > s.safeThresholdMg ? 'Time to switch, $name' : 'Good evening, $name';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currentLevelAsync = ref.watch(currentLevelProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: _PremiumAppBar(
        title: settingsAsync.when(
          loading: () => 'Caffeine',
          error: (_, __) => 'Caffeine',
          data: (s) {
            final mg = currentLevelAsync.maybeWhen(
                data: (v) => v, orElse: () => 0.0);
            return _greeting(s, mg);
          },
        ),
        onSettings: () => context.push('/settings'),
      ),
      body: RefreshIndicator(
        color: AppColors.amber,
        backgroundColor: AppColors.surface,
        displacement: 80,
        onRefresh: () async {
          ref.invalidate(entriesProvider);
          ref.invalidate(settingsProvider);
          ref.invalidate(currentLevelProvider);
          ref.invalidate(heartRateProvider);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            16,
            100,
          ),
          children: [
            // ── Hero gauge ──────────────────────────────────────────────
            const CurrentLevelCard(),
            const SizedBox(height: 12),

            // ── Stats row: Heart Rate + Streak ───────────────────────────
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: HeartRateBadge()),
                SizedBox(width: 12),
                Expanded(child: StreakBadge()),
              ],
            ),
            const SizedBox(height: 12),

            // ── Advice card ──────────────────────────────────────────────
            const AdviceCard(),
            const SizedBox(height: 12),

            // ── Decay graph ──────────────────────────────────────────────
            _GraphCard(),
            const SizedBox(height: 12),

            // ── Today's drinks ───────────────────────────────────────────
            const _SectionLabel(text: "TODAY'S DRINKS"),
            const SizedBox(height: 8),
            _TodaysDrinks(entriesAsync: entriesAsync, ref: ref),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const VoiceInputButton(),
          const SizedBox(height: 12),
          _GlowFab(
            heroTag: 'manualFab',
            color: AppColors.amber,
            onTap: () => context.push('/log'),
            tooltip: 'Log drink',
            child: const Text('☕', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 12),
          _GlowFab(
            heroTag: 'scanFab',
            color: AppColors.orange,
            onTap: () => context.push('/scan'),
            tooltip: 'Scan barcode',
            child: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
    );
  }
}

// ─── Premium transparent app bar ─────────────────────────────────────────────

class _PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onSettings;
  const _PremiumAppBar({required this.title, required this.onSettings});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bg.withAlpha(200),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            DateFormat('EEEE, d MMMM').format(DateTime.now()),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.glassLayer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.settings_outlined,
                color: AppColors.textSecondary, size: 18),
          ),
          onPressed: onSettings,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Graph card ───────────────────────────────────────────────────────────────

class _GraphCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Row(
              children: [
                Icon(Icons.show_chart_rounded,
                    size: 16, color: AppColors.textTertiary),
                SizedBox(width: 6),
                Text(
                  'CAFFEINE DECAY  ·  24 H',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 4, 8),
            child: DecayGraph(),
          ),
        ],
      ),
    );
  }
}

// ─── Today's drinks section ───────────────────────────────────────────────────

class _TodaysDrinks extends StatelessWidget {
  final AsyncValue entriesAsync;
  final WidgetRef ref;
  const _TodaysDrinks({required this.entriesAsync, required this.ref});

  @override
  Widget build(BuildContext context) {
    return entriesAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
      error: (e, _) =>
          Text('$e', style: const TextStyle(color: AppColors.danger)),
      data: (entries) {
        final today = DateTime.now();
        final todayEntries = (entries as List).where((e) {
          return e.consumedAt.year == today.year &&
              e.consumedAt.month == today.month &&
              e.consumedAt.day == today.day;
        }).toList()
          ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

        if (todayEntries.isEmpty) {
          return Container(
            decoration: surfaceCard(),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: const Center(
              child: Column(
                children: [
                  Text('☕',
                      style: TextStyle(
                          fontSize: 32,
                          color: AppColors.textDisabled)),
                  SizedBox(height: 8),
                  Text(
                    'No drinks logged today',
                    style: TextStyle(
                        color: AppColors.textDisabled, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: surfaceCard(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: todayEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isLast = idx == todayEntries.length - 1;
                return Column(
                  children: [
                    _DrinkRow(
                      item: item,
                      isFirst: idx == 0,
                      isLast: isLast,
                      onDelete: () async {
                        await ref
                            .read(caffeineRepositoryProvider)
                            .delete(item.id);
                        ref.invalidate(entriesProvider);
                        ref.invalidate(currentLevelProvider);
                      },
                    ),
                    if (!isLast)
                      const Divider(
                          height: 1, color: AppColors.glassBorder,
                          indent: 20, endIndent: 20),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _DrinkRow extends StatelessWidget {
  final dynamic item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onDelete;
  const _DrinkRow(
      {required this.item,
      required this.isFirst,
      required this.isLast,
      required this.onDelete});

  Color get _mgColor {
    final mg = item.mgAmount as double;
    if (mg < 80) return AppColors.safe;
    if (mg < 200) return AppColors.caution;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id as String),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.danger.withAlpha(30),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 20),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            // Emoji container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _mgColor.withAlpha(22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _mgColor.withAlpha(50)),
              ),
              child: const Center(
                child: Text('☕', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.drinkName as String,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(item.consumedAt as DateTime),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _mgColor.withAlpha(22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _mgColor.withAlpha(60)),
              ),
              child: Text(
                '${(item.mgAmount as double).toStringAsFixed(0)} mg',
                style: TextStyle(
                  color: _mgColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _GlowFab extends StatelessWidget {
  final String heroTag;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final Widget child;
  const _GlowFab({
    required this.heroTag,
    required this.color,
    required this.onTap,
    required this.tooltip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        backgroundColor: color,
        foregroundColor: Colors.black,
        onPressed: onTap,
        tooltip: tooltip,
        child: child,
      ),
    );
  }
}
