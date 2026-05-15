import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/drink_preset.dart';
import '../db/database_helper.dart';

class PresetsRepository {
  static List<DrinkPreset>? _cache;

  Future<List<DrinkPreset>> getAll() async {
    if (_cache != null) return _cache!;
    final jsonString =
        await rootBundle.loadString('assets/presets/drinks.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    _cache = jsonList
        .map((e) => DrinkPreset.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<List<DrinkPreset>> search(String query) async {
    if (query.trim().isEmpty) return getAll();
    final all = await getAll();
    final lower = query.toLowerCase();
    return all.where((p) {
      final nameMatch = p.name.toLowerCase().contains(lower);
      final brandMatch = p.brand?.toLowerCase().contains(lower) ?? false;
      return nameMatch || brandMatch;
    }).toList();
  }

  Future<List<DrinkPreset>> getByCategory(String category) async {
    final all = await getAll();
    if (category == 'all') return all;
    return all.where((p) => p.category == category).toList();
  }

  /// Returns the last 5 distinct presets that were logged, from SQLite.
  Future<List<DrinkPreset>> getRecents() async {
    List<Map<String, dynamic>> rows;
    if (kIsWeb) {
      final allEntries = await DatabaseHelper.instance.getAllEntries();
      final Map<String, String> latestByPreset = {};
      for (final row in allEntries) {
        final pid = row['preset_id'] as String?;
        if (pid == null) continue;
        final t = row['consumed_at'] as String;
        if (!latestByPreset.containsKey(pid) ||
            t.compareTo(latestByPreset[pid]!) > 0) {
          latestByPreset[pid] = t;
        }
      }
      final sorted = latestByPreset.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      rows = sorted
          .take(5)
          .map((e) => <String, dynamic>{'preset_id': e.key})
          .toList();
    } else {
      final db = (await DatabaseHelper.instance.database)!;
      rows = await db.rawQuery('''
        SELECT preset_id
        FROM caffeine_entries
        WHERE preset_id IS NOT NULL
        GROUP BY preset_id
        ORDER BY MAX(consumed_at) DESC
        LIMIT 5
      ''');
    }

    if (rows.isEmpty) return [];

    final all = await getAll();
    final allById = {for (final p in all) p.id: p};

    final recents = <DrinkPreset>[];
    for (final row in rows) {
      final id = row['preset_id'] as String?;
      if (id != null && allById.containsKey(id)) {
        recents.add(allById[id]!);
      }
    }
    return recents;
  }

  /// Clear the in-memory cache (useful for testing).
  void clearCache() => _cache = null;
}
