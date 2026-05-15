import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';

/// GLP-1 medication sensitivity multipliers.
const Map<String, double> glp1Multipliers = {
  'Mounjaro': 1.5,
  'Ozempic': 1.4,
  'Wegovy': 1.4,
  'Zepbound': 1.5,
};

class SettingsRepository {
  static const _keyHalfLifeHours = 'half_life_hours';
  static const _keyBedtimeHour = 'bedtime_hour';
  static const _keyBedtimeMinute = 'bedtime_minute';
  static const _keyGlp1Mode = 'glp1_mode';
  static const _keyGlp1Medication = 'glp1_medication';
  static const _keySensitivityMultiplier = 'sensitivity_multiplier';
  static const _keySafeThresholdMg = 'safe_threshold_mg';
  static const _keyName = 'user_name';
  static const _keyNotifySleepSafe = 'notif_sleep_safe';
  static const _keyNotifyDailySummary = 'notif_daily_summary';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  UserSettings load() {
    return UserSettings(
      halfLifeHours: _prefs.getDouble(_keyHalfLifeHours) ?? 5.0,
      bedtimeHour: _prefs.getInt(_keyBedtimeHour) ?? 23,
      bedtimeMinute: _prefs.getInt(_keyBedtimeMinute) ?? 0,
      glp1Mode: _prefs.getBool(_keyGlp1Mode) ?? false,
      glp1Medication: _prefs.getString(_keyGlp1Medication),
      sensitivityMultiplier:
          _prefs.getDouble(_keySensitivityMultiplier) ?? 1.0,
      safeThresholdMg: _prefs.getDouble(_keySafeThresholdMg) ?? 50.0,
      name: _prefs.getString(_keyName) ?? 'Gordon',
      notifySleepSafe: _prefs.getBool(_keyNotifySleepSafe) ?? false,
      notifyDailySummary: _prefs.getBool(_keyNotifyDailySummary) ?? false,
    );
  }

  Future<void> save(UserSettings settings) async {
    await _prefs.setDouble(_keyHalfLifeHours, settings.halfLifeHours);
    await _prefs.setInt(_keyBedtimeHour, settings.bedtimeHour);
    await _prefs.setInt(_keyBedtimeMinute, settings.bedtimeMinute);
    await _prefs.setBool(_keyGlp1Mode, settings.glp1Mode);
    if (settings.glp1Medication != null) {
      await _prefs.setString(_keyGlp1Medication, settings.glp1Medication!);
    } else {
      await _prefs.remove(_keyGlp1Medication);
    }
    await _prefs.setDouble(
        _keySensitivityMultiplier, settings.sensitivityMultiplier);
    await _prefs.setDouble(_keySafeThresholdMg, settings.safeThresholdMg);
    await _prefs.setString(_keyName, settings.name);
    await _prefs.setBool(_keyNotifySleepSafe, settings.notifySleepSafe);
    await _prefs.setBool(_keyNotifyDailySummary, settings.notifyDailySummary);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}
