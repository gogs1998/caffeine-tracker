import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caffeine_tracker/data/models/user_settings.dart';
import 'package:caffeine_tracker/data/repositories/settings_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<SettingsRepository> makeRepo() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository(prefs);
  }

  group('SettingsRepository defaults', () {
    test('loads default settings when prefs are empty', () async {
      final repo = await makeRepo();
      final settings = repo.load();
      expect(settings.halfLifeHours, 5.0);
      expect(settings.bedtimeHour, 23);
      expect(settings.bedtimeMinute, 0);
      expect(settings.glp1Mode, false);
      expect(settings.glp1Medication, isNull);
      expect(settings.sensitivityMultiplier, 1.0);
      expect(settings.safeThresholdMg, 50.0);
    });
  });

  group('SettingsRepository save/load round-trip', () {
    test('saves and reloads custom settings', () async {
      final repo = await makeRepo();
      const custom = UserSettings(
        halfLifeHours: 6.5,
        bedtimeHour: 22,
        bedtimeMinute: 30,
        glp1Mode: true,
        glp1Medication: 'Mounjaro',
        sensitivityMultiplier: 1.5,
        safeThresholdMg: 30.0,
      );
      await repo.save(custom);
      final loaded = repo.load();
      expect(loaded, custom);
    });

    test('saves glp1Mode=false with null medication', () async {
      final repo = await makeRepo();
      const s = UserSettings(glp1Mode: false);
      await repo.save(s);
      final loaded = repo.load();
      expect(loaded.glp1Mode, false);
      expect(loaded.glp1Medication, isNull);
    });

    test('overwriting settings replaces old values', () async {
      final repo = await makeRepo();
      await repo.save(const UserSettings(halfLifeHours: 4.0));
      await repo.save(const UserSettings(halfLifeHours: 7.0));
      expect(repo.load().halfLifeHours, 7.0);
    });
  });

  group('GLP-1 multiplier constants', () {
    test('Mounjaro multiplier is 1.5', () {
      expect(glp1Multipliers['Mounjaro'], 1.5);
    });
    test('Ozempic multiplier is 1.4', () {
      expect(glp1Multipliers['Ozempic'], 1.4);
    });
    test('Wegovy multiplier is 1.4', () {
      expect(glp1Multipliers['Wegovy'], 1.4);
    });
    test('Zepbound multiplier is 1.5', () {
      expect(glp1Multipliers['Zepbound'], 1.5);
    });
  });

  group('clear', () {
    test('clear resets to defaults', () async {
      final repo = await makeRepo();
      await repo.save(const UserSettings(halfLifeHours: 9.0, bedtimeHour: 21));
      await repo.clear();
      final loaded = repo.load();
      expect(loaded.halfLifeHours, 5.0);
      expect(loaded.bedtimeHour, 23);
    });
  });
}
