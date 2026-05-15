import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/advice_engine.dart';
import '../../core/providers.dart';

class AdviceCard extends ConsumerWidget {
  const AdviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adviceAsync = ref.watch(adviceProvider);

    return adviceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (advice) => _AdviceCardContent(advice: advice),
    );
  }
}

class _AdviceCardContent extends StatefulWidget {
  final CaffeineAdvice advice;
  const _AdviceCardContent({required this.advice});

  @override
  State<_AdviceCardContent> createState() => _AdviceCardContentState();
}

class _AdviceCardContentState extends State<_AdviceCardContent> {
  bool _expanded = false;

  Color get _borderColor {
    switch (widget.advice.level) {
      case AdviceLevel.warning:
        return Colors.redAccent;
      case AdviceLevel.caution:
        return Colors.amber;
      case AdviceLevel.ok:
        return Colors.greenAccent;
    }
  }

  IconData get _icon {
    switch (widget.advice.level) {
      case AdviceLevel.warning:
        return Icons.warning_amber_rounded;
      case AdviceLevel.caution:
        return Icons.info_outline_rounded;
      case AdviceLevel.ok:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/advice'),
      child: Card(
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Coloured left border
              Container(width: 4, color: _borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Icon(_icon, color: _borderColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.advice.headline,
                              style: TextStyle(
                                color: _borderColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white30,
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Body text
                      Text(
                        widget.advice.body,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                      // Expandable tips
                      if (widget.advice.tips.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _expanded = !_expanded),
                          child: Row(
                            children: [
                              Text(
                                _expanded ? 'Hide tips' : 'Show tips',
                                style: TextStyle(
                                    color: _borderColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: _borderColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        if (_expanded) ...[
                          const SizedBox(height: 6),
                          ...widget.advice.tips.map(
                            (tip) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 4, left: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ',
                                      style: TextStyle(
                                          color: _borderColor, fontSize: 12)),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
