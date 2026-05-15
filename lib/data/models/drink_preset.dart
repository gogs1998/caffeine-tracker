class DrinkPreset {
  final String id;
  final String name;
  final double mgAmount;
  final String category; // coffee, tea, energy, cola, other
  final String? brand;
  final String? iconEmoji;

  const DrinkPreset({
    required this.id,
    required this.name,
    required this.mgAmount,
    required this.category,
    this.brand,
    this.iconEmoji,
  });

  factory DrinkPreset.fromJson(Map<String, dynamic> json) {
    return DrinkPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      mgAmount: (json['mgAmount'] as num).toDouble(),
      category: json['category'] as String,
      brand: json['brand'] as String?,
      iconEmoji: json['iconEmoji'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mgAmount': mgAmount,
      'category': category,
      if (brand != null) 'brand': brand,
      if (iconEmoji != null) 'iconEmoji': iconEmoji,
    };
  }

  DrinkPreset copyWith({
    String? id,
    String? name,
    double? mgAmount,
    String? category,
    String? brand,
    String? iconEmoji,
  }) {
    return DrinkPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      mgAmount: mgAmount ?? this.mgAmount,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DrinkPreset && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DrinkPreset(id: $id, name: $name, mgAmount: $mgAmount, category: $category)';
}
