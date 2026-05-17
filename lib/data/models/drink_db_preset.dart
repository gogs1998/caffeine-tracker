/// A drink entry loaded from the bundled caffeine_database.json asset.
/// Distinct from [DrinkPreset] (the user-editable preset model).
class DrinkDbPreset {
  final String id;
  final String brand;
  final String name;
  final int sizeMl;
  final int caffeineMg;
  final String category; // coffee, energy_drink, soft_drink, tea, supplement, food
  final String subcategory; // espresso, latte, cappuccino, filter, etc.

  const DrinkDbPreset({
    required this.id,
    required this.brand,
    required this.name,
    required this.sizeMl,
    required this.caffeineMg,
    required this.category,
    required this.subcategory,
  });

  factory DrinkDbPreset.fromJson(Map<String, dynamic> j) => DrinkDbPreset(
        id: j['id'] as String,
        brand: j['brand'] as String,
        name: j['name'] as String,
        sizeMl: j['size_ml'] as int,
        caffeineMg: j['caffeine_mg'] as int,
        category: j['category'] as String,
        subcategory: j['subcategory'] as String,
      );
}
