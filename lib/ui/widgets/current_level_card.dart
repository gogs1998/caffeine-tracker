import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';

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
      loading: () => const _CardShell(
          child: CircularProgressIndicator(color: Colors.amber)),
      error: (e, _) =>
          _CardShell(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
      data: (level) {
        // Colour coding
        final Color ringColor;
        if (level < 100) {
          ringColor = Colors.greenAccent;
        } else if (level < 200) {
          ringColor = Colors.amber;
        } else {
          ringColor = Colors.redAccent;
        }

        // Safe to sleep
        String sleepLabel;
        final entries = entriesAsync.valueOrNull ?? [];
        final safe = calc.safeToSleepTime(entries, DateTime.now(), threshold);
        if (safe == null) {
          sleepLabel = 'Safe to sleep now ✓';
        } else {
          sleepLabel = 'Safe to sleep at ${DateFormat('HH:mm').format(safe)}';
        }

        return _CardShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: (level / 400).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        level.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: ringColor,
                        ),
                      ),
                      const Text('mg',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (glp1Mode)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(60),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple),
                  ),
                  child: const Text('GLP-1 Mode',
                      style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              Text(
                sleepLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: child),
      ),
    );
  }
}
