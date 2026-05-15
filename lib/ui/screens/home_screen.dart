import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../widgets/current_level_card.dart';
import '../widgets/decay_graph.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Row(
          children: [
            Text('☕', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Caffeine Tracker',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.amber,
        onRefresh: () async {
          ref.invalidate(entriesProvider);
          ref.invalidate(settingsProvider);
          ref.invalidate(currentLevelProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Current level card ───────────────────────────────────────
            const CurrentLevelCard(),
            const SizedBox(height: 16),

            // ── Decay graph ───────────────────────────────────────────────
            Card(
              color: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(8, 12, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(
                        'Caffeine decay (24 h)',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    DecayGraph(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Today's drinks ────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "Today's drinks",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
            entriesAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: Colors.amber)),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: Colors.redAccent)),
              data: (entries) {
                // Filter to today
                final today = DateTime.now();
                final todayEntries = entries.where((e) {
                  return e.consumedAt.year == today.year &&
                      e.consumedAt.month == today.month &&
                      e.consumedAt.day == today.day;
                }).toList()
                  ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

                if (todayEntries.isEmpty) {
                  return const Card(
                    color: Color(0xFF1E1E2E),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('No drinks logged today',
                            style: TextStyle(color: Colors.white38)),
                      ),
                    ),
                  );
                }

                return Card(
                  color: const Color(0xFF1E1E2E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Column(
                    children: todayEntries.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(60),
                                borderRadius: idx == 0
                                    ? const BorderRadius.vertical(
                                        top: Radius.circular(16))
                                    : null,
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                            ),
                            onDismissed: (_) async {
                              await ref
                                  .read(caffeineRepositoryProvider)
                                  .delete(item.id);
                              ref.invalidate(entriesProvider);
                              ref.invalidate(currentLevelProvider);
                            },
                            child: ListTile(
                              leading: const Text('☕',
                                  style: TextStyle(fontSize: 22)),
                              title: Text(item.drinkName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                DateFormat('HH:mm').format(item.consumedAt),
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                              trailing: Text(
                                '${item.mgAmount.toStringAsFixed(0)} mg',
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          if (idx < todayEntries.length - 1)
                            const Divider(
                                color: Colors.white12, height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 80), // space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        onPressed: () => context.push('/log'),
        child: const Text('☕', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}
