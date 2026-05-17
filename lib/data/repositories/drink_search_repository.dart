import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/drink_db_preset.dart';

class DrinkSearchRepository {
  static List<DrinkDbPreset>? _cache;

  Future<List<DrinkDbPreset>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/caffeine_database.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map((e) => DrinkDbPreset.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<List<DrinkDbPreset>> search(String query) async {
    final all = await _load();
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    final results = all
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.brand.toLowerCase().contains(q))
        .toList();
    results.sort((a, b) {
      final aGeneric = a.brand.toLowerCase() == 'generic' ? 0 : 1;
      final bGeneric = b.brand.toLowerCase() == 'generic' ? 0 : 1;
      if (aGeneric != bGeneric) return aGeneric.compareTo(bGeneric);
      final brandCmp = a.brand.compareTo(b.brand);
      if (brandCmp != 0) return brandCmp;
      return a.name.compareTo(b.name);
    });
    return results.take(30).toList();
  }

  Future<List<DrinkDbPreset>> getByCategory(String category) async {
    final all = await _load();
    return all.where((d) => d.category == category).toList();
  }

  Future<List<DrinkDbPreset>> getGenerics() async {
    final all = await _load();
    return all
        .where((d) => d.brand.toLowerCase() == 'generic')
        .take(20)
        .toList();
  }
}
