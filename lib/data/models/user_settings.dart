class UserSettings {
  final double halfLifeHours;
  final int bedtimeHour;
  final int bedtimeMinute;
  final bool glp1Mode;
  final String? glp1Medication;
  final double sensitivityMultiplier;
  final double safeThresholdMg;

  const UserSettings({
    this.halfLifeHours = 5.0,
    this.bedtimeHour = 23,
    this.bedtimeMinute = 0,
    this.glp1Mode = false,
    this.glp1Medication,
    this.sensitivityMultiplier = 1.0,
    this.safeThresholdMg = 50.0,
  });

  UserSettings copyWith({
    double? halfLifeHours,
    int? bedtimeHour,
    int? bedtimeMinute,
    bool? glp1Mode,
    String? glp1Medication,
    double? sensitivityMultiplier,
    double? safeThresholdMg,
  }) {
    return UserSettings(
      halfLifeHours: halfLifeHours ?? this.halfLifeHours,
      bedtimeHour: bedtimeHour ?? this.bedtimeHour,
      bedtimeMinute: bedtimeMinute ?? this.bedtimeMinute,
      glp1Mode: glp1Mode ?? this.glp1Mode,
      glp1Medication: glp1Medication ?? this.glp1Medication,
      sensitivityMultiplier:
          sensitivityMultiplier ?? this.sensitivityMultiplier,
      safeThresholdMg: safeThresholdMg ?? this.safeThresholdMg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          runtimeType == other.runtimeType &&
          halfLifeHours == other.halfLifeHours &&
          bedtimeHour == other.bedtimeHour &&
          bedtimeMinute == other.bedtimeMinute &&
          glp1Mode == other.glp1Mode &&
          glp1Medication == other.glp1Medication &&
          sensitivityMultiplier == other.sensitivityMultiplier &&
          safeThresholdMg == other.safeThresholdMg;

  @override
  int get hashCode => Object.hash(
        halfLifeHours,
        bedtimeHour,
        bedtimeMinute,
        glp1Mode,
        glp1Medication,
        sensitivityMultiplier,
        safeThresholdMg,
      );

  @override
  String toString() => 'UserSettings('
      'halfLifeHours: $halfLifeHours, '
      'bedtimeHour: $bedtimeHour, '
      'bedtimeMinute: $bedtimeMinute, '
      'glp1Mode: $glp1Mode, '
      'glp1Medication: $glp1Medication, '
      'sensitivityMultiplier: $sensitivityMultiplier, '
      'safeThresholdMg: $safeThresholdMg)';
}
