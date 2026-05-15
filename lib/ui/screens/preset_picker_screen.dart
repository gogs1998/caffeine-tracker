import 'package:flutter/material.dart';
import '../../data/models/drink_preset.dart';
import '../../data/repositories/presets_repository.dart';
import '../theme/app_theme.dart';

class PresetPickerScreen extends StatefulWidget {
  const PresetPickerScreen({super.key});

  @override
  State<PresetPickerScreen> createState() => _PresetPickerScreenState();
}

class _PresetPickerScreenState extends State<PresetPickerScreen> {
  final PresetsRepository _repo = PresetsRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  List<DrinkPreset> _allPresets = [];
  List<DrinkPreset> _recents = [];
  bool _loading = true;
  String _query = '';
  String _selectedCategory = 'all';

  static const _categories = [
    ('all', 'All', '✨'),
    ('coffee', 'Coffee', '☕'),
    ('tea', 'Tea', '🍵'),
    ('energy', 'Energy', '⚡'),
    ('cola', 'Cola', '🥤'),
    ('other', 'Other', '🍶'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await _repo.getAll();
    final recents = await _repo.getRecents();
    if (mounted) {
      setState(() {
        _allPresets = all;
        _recents = recents;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DrinkPreset> get _filtered {
    var items = _selectedCategory == 'all'
        ? _allPresets
        : _allPresets.where((p) => p.category == _selectedCategory).toList();
    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      items = items
          .where((p) =>
              p.name.toLowerCase().contains(lower) ||
              (p.brand?.toLowerCase().contains(lower) ?? false))
          .toList();
    }
    return items;
  }

  Color _mgColor(double mg) {
    if (mg == 0) return Colors.grey;
    if (mg < 80) return AppColors.safe;
    if (mg < 200) return AppColors.caution;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Choose a Drink'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search drinks…',
                  hintStyle: const TextStyle(color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textTertiary, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppColors.textTertiary, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Category chips ───────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (cat, label, emoji) = _categories[i];
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.amber.withAlpha(30)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.amber.withAlpha(120)
                            : AppColors.glassBorder,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '$emoji  $label',
                      style: TextStyle(
                        color: selected
                            ? AppColors.amber
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.amber, strokeWidth: 2))
                : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final items = _filtered;
    final showRecents = _selectedCategory == 'all' &&
        _recents.isNotEmpty &&
        _query.isEmpty;

    if (items.isEmpty && !showRecents) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔍', style: TextStyle(fontSize: 36)),
            SizedBox(height: 12),
            Text(
              'No drinks found',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (showRecents) ...[
          const _SliverHeader(title: 'RECENT'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _DrinkCard(
                  preset: _recents[i],
                  mgColor: _mgColor(_recents[i].mgAmount),
                  onTap: () => Navigator.pop(context, _recents[i]),
                ),
                childCount: _recents.length,
              ),
            ),
          ),
          const _SliverHeader(title: 'ALL DRINKS'),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _DrinkCard(
                preset: items[i],
                mgColor: _mgColor(items[i].mgAmount),
                onTap: () => Navigator.pop(context, items[i]),
              ),
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sliver section header ────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final String title;
  const _SliverHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─── Drink grid card ──────────────────────────────────────────────────────────

class _DrinkCard extends StatefulWidget {
  final DrinkPreset preset;
  final Color mgColor;
  final VoidCallback onTap;

  const _DrinkCard({
    required this.preset,
    required this.mgColor,
    required this.onTap,
  });

  @override
  State<_DrinkCard> createState() => _DrinkCardState();
}

class _DrinkCardState extends State<_DrinkCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.preset.iconEmoji ?? '☕',
                    style: const TextStyle(fontSize: 26),
                  ),
                  const Spacer(),
                  // mg badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.mgColor.withAlpha(22),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: widget.mgColor.withAlpha(60)),
                    ),
                    child: Text(
                      '${widget.preset.mgAmount.toInt()} mg',
                      style: TextStyle(
                        color: widget.mgColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.preset.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.preset.brand != null)
                Text(
                  widget.preset.brand!,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
