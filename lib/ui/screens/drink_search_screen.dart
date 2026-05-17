import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers.dart';
import '../../core/providers/drink_search_provider.dart';
import '../../data/models/caffeine_entry.dart';
import '../../data/models/drink_db_preset.dart';
import '../../data/repositories/drink_search_repository.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

class DrinkSearchScreen extends ConsumerStatefulWidget {
  const DrinkSearchScreen({super.key});

  @override
  ConsumerState<DrinkSearchScreen> createState() => _DrinkSearchScreenState();
}

class _DrinkSearchScreenState extends ConsumerState<DrinkSearchScreen> {
  final _controller = TextEditingController();
  String _selectedCategory = 'all';

  static const _categories = [
    ('all', 'All'),
    ('coffee', 'Coffee'),
    ('energy_drink', 'Energy'),
    ('soft_drink', 'Soft Drink'),
    ('tea', 'Tea'),
    ('supplement', 'Supplement'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logDrink(BuildContext context, DrinkDbPreset drink) async {
    final repo = ref.read(caffeineRepositoryProvider);
    final entry = CaffeineEntry(
      id: _uuid.v4(),
      drinkName: drink.name,
      mgAmount: drink.caffeineMg.toDouble(),
      consumedAt: DateTime.now(),
      presetId: drink.id,
    );
    await repo.insert(entry);
    ref.invalidate(entriesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${drink.caffeineMg}mg from ${drink.name}'),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(drinkSearchQueryProvider);
    final resultsAsync = ref.watch(drinkSearchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          'Search Drinks',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.dmSans(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Search by name or brand…',
                hintStyle: GoogleFonts.dmSans(color: AppColors.muted2),
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.muted),
                        onPressed: () {
                          _controller.clear();
                          ref.read(drinkSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                ref.read(drinkSearchQueryProvider.notifier).state = v;
              },
            ),
          ),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (cat, label) = _categories[i];
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? AppColors.card : AppColors.ink,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.crema,
                  backgroundColor: AppColors.card,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: query.isEmpty
                ? _EmptyState(
                    category: _selectedCategory,
                    onTap: (drink) => _logDrink(context, drink),
                  )
                : resultsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.crema),
                    ),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (results) {
                      final filtered = _selectedCategory == 'all'
                          ? results
                          : results
                              .where((d) => d.category == _selectedCategory)
                              .toList();
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No drinks found',
                            style: GoogleFonts.dmSans(
                              color: AppColors.muted2,
                              fontSize: 15,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) => _DrinkTile(
                          drink: filtered[i],
                          onTap: () => _logDrink(context, filtered[i]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DrinkTile extends StatelessWidget {
  final DrinkDbPreset drink;
  final VoidCallback onTap;

  const _DrinkTile({required this.drink, required this.onTap});

  Color get _badgeColor {
    if (drink.caffeineMg < 100) return const Color(0xFF5F7A3F);
    if (drink.caffeineMg <= 200) return const Color(0xFFC77D3F);
    return const Color(0xFFB23A28);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drink.name,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${drink.brand} · ${drink.sizeMl} ml',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _badgeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _badgeColor.withAlpha(80)),
              ),
              child: Text(
                '${drink.caffeineMg} mg',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatefulWidget {
  final String category;
  final void Function(DrinkDbPreset) onTap;

  const _EmptyState({required this.category, required this.onTap});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  List<DrinkDbPreset>? _generics;

  @override
  void initState() {
    super.initState();
    _loadGenerics();
  }

  @override
  void didUpdateWidget(_EmptyState old) {
    super.didUpdateWidget(old);
    if (old.category != widget.category) _loadGenerics();
  }

  Future<void> _loadGenerics() async {
    final repo = DrinkSearchRepository();
    final List<DrinkDbPreset> list;
    if (widget.category == 'all') {
      list = await repo.getGenerics();
    } else {
      final all = await repo.getByCategory(widget.category);
      list = all
          .where((d) => d.brand.toLowerCase() == 'generic')
          .take(20)
          .toList();
    }
    if (mounted) setState(() => _generics = list);
  }

  @override
  Widget build(BuildContext context) {
    final items = _generics;
    if (items == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.crema),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Quick Add',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ...items.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DrinkTile(drink: d, onTap: () => widget.onTap(d)),
          ),
        ),
      ],
    );
  }
}
