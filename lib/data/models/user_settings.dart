class UserSettings {
  final double halfLifeHours;
  final int bedtimeHour;
  final int bedtimeMinute;
  final bool glp1Mode;
  final String? glp1Medication;
  final double sensitivityMultiplier;
  final double safeThresholdMg;
  final String name;
  final bool notifySleepSafe;
  final bool notifyDailySummary;

  const UserSettings({
    this.halfLifeHours = 5.0,
    this.bedtimeHour = 23,
    this.bedtimeMinute = 0,
    this.glp1Mode = false,
    this.glp1Medication,
    this.sensitivityMultiplier = 1.0,
    this.safeThresholdMg = 50.0,
    this.name = 'Gordon',
    this.notifySleepSafe = false,
    this.notifyDailySummary = false,
  });

  UserSettings copyWith({
    double? halfLifeHours,
    int? bedtimeHour,
    int? bedtimeMinute,
    bool? glp1Mode,
    String? glp1Medication,
    double? sensitivityMultiplier,
    double? safeThresholdMg,
    String? name,
    bool? notifySleepSafe,
    bool? notifyDailySummary,
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
      name: name ?? this.name,
      notifySleepSafe: notifySleepSafe ?? this.notifySleepSafe,
      notifyDailySummary: notifyDailySummary ?? this.notifyDailySummary,
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
          safeThresholdMg == other.safeThresholdMg &&
          name == other.name &&
          notifySleepSafe == other.notifySleepSafe &&
          notifyDailySummary == other.notifyDailySummary;

  @override
  int get hashCode => Object.hash(
        halfLifeHours,
        bedtimeHour,
        bedtimeMinute,
        glp1Mode,
        glp1Medication,
        sensitivityMultiplier,
        safeThresholdMg,
        name,
        notifySleepSafe,
        notifyDailySummary,
      );

  @override
  String toString() => 'UserSettings('
      'halfLifeHours: $halfLifeHours, '
      'bedtimeHour: $bedtimeHour, '
      'bedtimeMinute: $bedtimeMinute, '
      'glp1Mode: $glp1Mode, '
      'glp1Medication: $glp1Medication, '
      'sensitivityMultiplier: $sensitivityMultiplier, '
      'safeThresholdMg: $safeThresholdMg, '
      'name: $name)';
}
