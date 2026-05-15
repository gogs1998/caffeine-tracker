import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import 'arc_gauge.dart';
import '../theme/app_theme.dart';

class CurrentLevelCard extends ConsumerWidget {
  const CurrentLevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(currentLevelProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final entriesAsync = ref.watch(entriesProvider);
    final calc = ref.watch(calculatorProvider);

    final settings = settingsAsync.valueOrNull;
    final threshold = settings?.safeThresholdMg ?? 50.0;
    final glp1Mode = settings?.glp1Mode ?? false;

    return levelAsync.when(
      loading: () => const _Shell(
        child: SizedBox(
          height: 240,
          child: Center(
            child: ArcGauge(value: 0, size: 180, strokeWidth: 16),
          ),
        ),
      ),
      error: (e, _) => _Shell(
        child: Text('$e', style: const TextStyle(color: AppColors.danger)),
      ),
      data: (level) {
        final Color gaugeColor = level < 100
            ? AppColors.safe
            : level < 200
                ? AppColors.caution
                : AppColors.danger;

        final entries = entriesAsync.valueOrNull ?? [];
        final safe =
            calc.safeToSleepTime(entries, DateTime.now(), threshold);
        final isSafe = safe == null;
        final sleepLabel = isSafe
            ? 'Safe to sleep now'
            : 'Sleep-safe at ${DateFormat('HH:mm').format(safe)}';

        return _Shell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header row ──────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'CAFFEINE LEVEL',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (glp1Mode)
                    const _Pill(
                      label: 'GLP-1',
                      color: AppColors.purple,
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Arc gauge + animated number ─────────────────────────
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ArcGauge(
                      value: (level / 400).clamp(0.0, 1.0),
                      size: 200,
                      strokeWidth: 18,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedCount(
                          target: level,
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w700,
                            color: gaugeColor,
                            letterSpacing: -2,
                            height: 1.0,
                          ),
                        ),
                        const Text(
                          'mg',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Scale labels ────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0',
                        style: TextStyle(
                            color: AppColors.textDisabled, fontSize: 10)),
                    Text('100',
                        style: TextStyle(
                            color: AppColors.textDisabled, fontSize: 10)),
                    Text('200',
                        style: TextStyle(
                            color: AppColors.textDisabled, fontSize: 10)),
                    Text('300',
                        style: TextStyle(
                            color: AppColors.textDisabled, fontSize: 10)),
                    Text('400+',
                        style: TextStyle(
                            color: AppColors.textDisabled, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Sleep status pill ────────────────────────────────────
              _SleepPill(isSafe: isSafe, label: sleepLabel),
            ],
          ),
        );
      },
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SleepPill extends StatelessWidget {
  final bool isSafe;
  final String label;
  const _SleepPill({required this.isSafe, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = isSafe ? AppColors.safe : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSafe ? AppColors.safe.withAlpha(22) : AppColors.glassLayer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSafe ? AppColors.safe.withAlpha(70) : AppColors.glassBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSafe ? Icons.bedtime_outlined : Icons.schedule_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Counts up (or transitions) to [target] with a tween animation.
class _AnimatedCount extends StatefulWidget {
  final double target;
  final TextStyle style;
  const _AnimatedCount({required this.target, required this.style});

  @override
  State<_AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<_AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCount old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _from = old.target * _anim.value +
          old.target * (1 - _anim.value); // current visual
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final v = _from + _anim.value * (widget.target - _from);
        return Text(v.toStringAsFixed(0), style: widget.style);
      },
    );
  }
}
