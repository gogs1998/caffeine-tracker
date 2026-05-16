import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../data/models/caffeine_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/ct_widgets.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

const _categories = [
  ('espresso', 'Espresso'),
  ('coffee', 'Coffee'),
  ('tea', 'Tea'),
  ('matcha', 'Matcha'),
  ('energy', 'Energy'),
  ('soda', 'Soda'),
];

const _presets = {
  'espresso': (name: 'Cappuccino', mgPerOz: 20.0, defaultOz: 6.0, sizes: [4.0, 6.0, 8.0, 12.0], sizeLabels: ['4 oz', '6 oz', '8 oz', '12 oz']),
  'coffee': (name: 'Pour-over', mgPerOz: 8.0, defaultOz: 12.0, sizes: [8.0, 12.0, 16.0, 20.0], sizeLabels: ['8 oz', '12 oz', '16 oz', '20 oz']),
  'tea': (name: 'Black tea', mgPerOz: 5.0, defaultOz: 8.0, sizes: [6.0, 8.0, 12.0, 16.0], sizeLabels: ['6 oz', '8 oz', '12 oz', '16 oz']),
  'matcha': (name: 'Matcha latte', mgPerOz: 8.5, defaultOz: 8.0, sizes: [6.0, 8.0, 12.0, 16.0], sizeLabels: ['6 oz', '8 oz', '12 oz', '16 oz']),
  'energy': (name: 'Energy drink', mgPerOz: 10.0, defaultOz: 16.0, sizes: [8.0, 12.0, 16.0, 24.0], sizeLabels: ['8 oz', '12 oz', '16 oz', '24 oz']),
  'soda': (name: 'Cola', mgPerOz: 3.5, defaultOz: 12.0, sizes: [8.0, 12.0, 20.0, 32.0], sizeLabels: ['8 oz', '12 oz', '20 oz', '32 oz']),
};

class _LogScreenState extends ConsumerState<LogScreen> {
  String _category = 'espresso';
  int _sizeIndex = 1;
  final DateTime _logTime = DateTime.now();

  ({String name, double mgPerOz, double defaultOz, List<double> sizes, List<String> sizeLabels}) get _preset =>
      _presets[_category]!;

  double get _selectedOz => _preset.sizes[_sizeIndex];
  double get _mg => (_selectedOz * _preset.mgPerOz).roundToDouble();

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final currentMg = entriesAsync.maybeWhen(
      data: (entries) {
        final now = DateTime.now();
        return entries
            .where((e) =>
                e.consumedAt.year == now.year &&
                e.consumedAt.month == now.month &&
                e.consumedAt.day == now.day)
            .fold(0.0, (s, e) => s + e.mgAmount);
      },
      orElse: () => 0.0,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.crema,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(child: CTEyebrow('Log a drink')),
                  ),
                  const Icon(Icons.search, color: AppColors.ink, size: 22),
                ],
              ),
            ),

            // Category pills
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (id, label) = _categories[i];
                  final active = _category == id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _category = id;
                      _sizeIndex = 1;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.ink : AppColors.bg2,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: active ? AppColors.bg : AppColors.muted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                children: [
                  // Selected drink card
                  CTCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.cremaTn,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: DrinkIcon(kind: _category, size: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _preset.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${_selectedOz.toStringAsFixed(0)} oz · ${_mg.toStringAsFixed(0)} mg caffeine',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.muted2),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Size selector
                  const CTEyebrow('Size'),
                  const SizedBox(height: 8),
                  Row(
                    children: _preset.sizeLabels.asMap().entries.map((e) {
                      final active = e.key == _sizeIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _sizeIndex = e.key),
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: e.key < _preset.sizeLabels.length - 1
                                    ? 8
                                    : 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color:
                                    active ? AppColors.ink : AppColors.bg2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    color: active
                                        ? AppColors.bg
                                        : AppColors.muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Time row
                  CTCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    color: AppColors.bg2,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 18, color: AppColors.muted),
                        const SizedBox(width: 10),
                        const Text(
                          'Just now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('h:mm a').format(_logTime),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mg preview card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '+${_mg.toStringAsFixed(0)}',
                              style: GoogleFonts.newsreader(
                                fontSize: 56,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w300,
                                color: AppColors.bg,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'mg',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                color: AppColors.muted2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total today: ${currentMg.toStringAsFixed(0)} → ${(currentMg + _mg).toStringAsFixed(0)} mg',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppColors.muted2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () async {
                        final entry = CaffeineEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          drinkName: _preset.name,
                          mgAmount: _mg,
                          consumedAt: _logTime,
                        );
                        await ref
                            .read(caffeineRepositoryProvider)
                            .insert(entry);
                        ref.invalidate(entriesProvider);
                        ref.invalidate(currentLevelProvider);
                        if (context.mounted) context.pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.crema,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Add to today',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
