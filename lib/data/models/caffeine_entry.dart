class CaffeineEntry {
  final String id;
  final String drinkName;
  final double mgAmount;
  final DateTime consumedAt;
  final String? notes;
  final String? presetId;

  const CaffeineEntry({
    required this.id,
    required this.drinkName,
    required this.mgAmount,
    required this.consumedAt,
    this.notes,
    this.presetId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'drink_name': drinkName,
        'mg_amount': mgAmount,
        'consumed_at': consumedAt.toIso8601String(),
        'notes': notes,
        'preset_id': presetId,
      };

  factory CaffeineEntry.fromMap(Map<String, dynamic> map) => CaffeineEntry(
        id: map['id'] as String,
        drinkName: map['drink_name'] as String,
        mgAmount: (map['mg_amount'] as num).toDouble(),
        consumedAt: DateTime.parse(map['consumed_at'] as String),
        notes: map['notes'] as String?,
        presetId: map['preset_id'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaffeineEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CaffeineEntry(id: $id, drinkName: $drinkName, mgAmount: $mgAmount, consumedAt: $consumedAt)';
}
