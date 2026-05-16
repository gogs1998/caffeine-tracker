import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ct_widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

const _libraryGroups = [
  (
    'Espresso & Coffee',
    [
      ('Espresso', 'espresso', '1 oz', 63.0),
      ('Cortado', 'espresso', '4 oz', 80.0),
      ('Cappuccino', 'espresso', '6 oz', 120.0),
      ('Latte', 'espresso', '12 oz', 128.0),
      ('Pour-over', 'coffee', '12 oz', 95.0),
      ('Cold brew', 'coffee', '12 oz', 200.0),
      ('Drip coffee', 'coffee', '8 oz', 95.0),
    ]
  ),
  (
    'Tea',
    [
      ('Black tea', 'tea', '8 oz', 47.0),
      ('Green tea', 'tea', '8 oz', 28.0),
      ('Matcha latte', 'matcha', '8 oz', 70.0),
      ('Oolong tea', 'tea', '8 oz', 37.0),
    ]
  ),
  (
    'Energy & Other',
    [
      ('Red Bull (8.4 oz)', 'energy', '8.4 oz', 80.0),
      ('Monster (16 oz)', 'energy', '16 oz', 160.0),
      ('Cola (12 oz)', 'soda', '12 oz', 34.0),
      ('Diet Cola (12 oz)', 'soda', '12 oz', 46.0),
    ]
  ),
];

const _favorites = [
  ('Cortado', 'espresso', 80.0),
  ('Pour-over', 'coffee', 95.0),
  ('Matcha latte', 'matcha', 70.0),
];

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Library',
                    style: GoogleFonts.newsreader(
                      fontSize: 28,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      boxShadow: surfaceCard().boxShadow,
                    ),
                    child: const Icon(Icons.add, size: 20, color: AppColors.ink),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: CTCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: AppColors.muted2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v.toLowerCase()),
                        decoration: const InputDecoration(
                          hintText: 'Search drinks...',
                          hintStyle: TextStyle(
                              color: AppColors.muted2, fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                            color: AppColors.ink, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                children: [
                  if (_query.isEmpty) ...[
                    // Favorites horizontal scroll
                    const Padding(
                      padding: EdgeInsets.fromLTRB(22, 0, 0, 10),
                      child: CTEyebrow('Favorites'),
                    ),
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: _favorites.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final (name, kind, mg) = _favorites[i];
                          return SizedBox(
                            width: 140,
                            child: CTCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.cremaTn,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: DrinkIcon(kind: kind, size: 20),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${mg.toStringAsFixed(0)} mg',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Grouped sections
                  ..._libraryGroups.map((group) {
                    final items = group.$2.where((d) =>
                        _query.isEmpty ||
                        d.$1.toLowerCase().contains(_query)).toList();
                    if (items.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CTEyebrow(group.$1),
                          ),
                          CTCard(
                            child: Column(
                              children: items.asMap().entries.map((e) {
                                final isLast = e.key == items.length - 1;
                                final (name, kind, vol, mg) = e.value;
                                return Column(
                                  children: [
                                    _LibRow(
                                        name: name,
                                        kind: kind,
                                        vol: vol,
                                        mg: mg),
                                    if (!isLast)
                                      const Divider(
                                          height: 1,
                                          thickness: 0.5,
                                          color: AppColors.line,
                                          indent: 58,
                                          endIndent: 18),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            CTTabBar(
              activeIndex: 4,
              onTap: (i) {
                if (i == 0) context.go('/');
                if (i == 2) context.push('/log');
                if (i == 1) context.push('/history');
                if (i == 3) context.push('/sleep');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LibRow extends StatelessWidget {
  final String name;
  final String kind;
  final String vol;
  final double mg;

  const _LibRow({
    required this.name,
    required this.kind,
    required this.vol,
    required this.mg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: DrinkIcon(kind: kind, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  vol,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${mg.toStringAsFixed(0)} mg',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.muted2),
        ],
      ),
    );
  }
}
