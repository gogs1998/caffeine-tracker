import 'package:flutter/material.dart';
import '../../data/models/drink_preset.dart';
import '../../data/repositories/presets_repository.dart';

class PresetPickerScreen extends StatefulWidget {
  const PresetPickerScreen({super.key});

  @override
  State<PresetPickerScreen> createState() => _PresetPickerScreenState();
}

class _PresetPickerScreenState extends State<PresetPickerScreen>
    with SingleTickerProviderStateMixin {
  final PresetsRepository _repo = PresetsRepository();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  List<DrinkPreset> _allPresets = [];
  List<DrinkPreset> _recents = [];
  bool _loading = true;
  String _query = '';

  static const _tabs = ['All', 'Coffee', 'Tea', 'Energy', 'Cola', 'Other'];
  static const _categories = ['all', 'coffee', 'tea', 'energy', 'cola', 'other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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

  void _onSearchChanged(String value) {
    setState(() => _query = value);
  }

  Color _mgColor(double mg) {
    if (mg == 0) return Colors.grey;
    if (mg < 80) return Colors.green;
    if (mg < 200) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Drink'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search drinks…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
              ],
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _tabs.asMap().entries.map((entry) {
                      final category = _categories[entry.key];
                      return _buildList(category);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String category) {
    List<DrinkPreset> items = _allPresets;
    if (category != 'all') {
      items = _allPresets.where((p) => p.category == category).toList();
    }
    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      items = items
          .where((p) =>
              p.name.toLowerCase().contains(lower) ||
              (p.brand?.toLowerCase().contains(lower) ?? false))
          .toList();
    }

    final showRecents = category == 'all' && _recents.isNotEmpty && _query.isEmpty;

    if (items.isEmpty && !showRecents) {
      return const Center(child: Text('No drinks found'));
    }

    return ListView.builder(
      itemCount: (showRecents ? _recents.length + 2 : 0) + items.length,
      itemBuilder: (context, index) {
        if (showRecents) {
          if (index == 0) {
            return const _SectionHeader(title: 'Recent');
          }
          if (index <= _recents.length) {
            return _DrinkTile(
              preset: _recents[index - 1],
              mgColor: _mgColor(_recents[index - 1].mgAmount),
              onTap: () => Navigator.pop(context, _recents[index - 1]),
            );
          }
          if (index == _recents.length + 1) {
            return const _SectionHeader(title: 'All Drinks');
          }
          final itemIndex = index - _recents.length - 2;
          return _DrinkTile(
            preset: items[itemIndex],
            mgColor: _mgColor(items[itemIndex].mgAmount),
            onTap: () => Navigator.pop(context, items[itemIndex]),
          );
        } else {
          return _DrinkTile(
            preset: items[index],
            mgColor: _mgColor(items[index].mgAmount),
            onTap: () => Navigator.pop(context, items[index]),
          );
        }
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _DrinkTile extends StatelessWidget {
  final DrinkPreset preset;
  final Color mgColor;
  final VoidCallback onTap;

  const _DrinkTile({
    required this.preset,
    required this.mgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(preset.iconEmoji ?? '☕', style: const TextStyle(fontSize: 26)),
      title: Text(preset.name),
      subtitle: preset.brand != null ? Text(preset.brand!) : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: mgColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: mgColor.withValues(alpha: 0.6)),
        ),
        child: Text(
          '${preset.mgAmount.toInt()} mg',
          style: TextStyle(
            color: mgColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
