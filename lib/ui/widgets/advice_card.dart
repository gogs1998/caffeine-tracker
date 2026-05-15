import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/advice_engine.dart';
import '../../core/providers.dart';
import '../theme/app_theme.dart';

class AdviceCard extends ConsumerWidget {
  const AdviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adviceAsync = ref.watch(adviceProvider);
    return adviceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (advice) => _AdviceContent(advice: advice),
    );
  }
}

class _AdviceContent extends StatefulWidget {
  final CaffeineAdvice advice;
  const _AdviceContent({required this.advice});

  @override
  State<_AdviceContent> createState() => _AdviceContentState();
}

class _AdviceContentState extends State<_AdviceContent> {
  bool _expanded = false;

  Color get _accent {
    return switch (widget.advice.level) {
      AdviceLevel.warning => AppColors.danger,
      AdviceLevel.caution => AppColors.caution,
      AdviceLevel.ok => AppColors.safe,
    };
  }

  IconData get _icon {
    return switch (widget.advice.level) {
      AdviceLevel.warning => Icons.warning_amber_rounded,
      AdviceLevel.caution => Icons.info_outline_rounded,
      AdviceLevel.ok => Icons.check_circle_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/advice'),
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
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gradient left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_accent, _accent.withAlpha(80)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _accent.withAlpha(22),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_icon, color: _accent, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.advice.headline,
                              style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.textDisabled,
                            size: 12,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.advice.body,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      if (widget.advice.tips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              setState(() => _expanded = !_expanded),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _expanded ? 'Hide tips' : 'Show tips',
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _expanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: _accent,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox(width: double.infinity),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.advice.tips
                                  .map(
                                    (tip) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 5),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(
                                                top: 5, right: 8),
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: _accent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: const TextStyle(
                                                color:
                                                    AppColors.textSecondary,
                                                fontSize: 12,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          crossFadeState: _expanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
