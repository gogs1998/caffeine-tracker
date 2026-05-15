import 'dart:io';
import 'package:health/health.dart';

/// Repository that wraps the [Health] plugin for reading heart rate data.
class HealthRepository {
  final Health _health = Health();

  static const _types = [HealthDataType.HEART_RATE];
  static const _permissions = [HealthDataAccess.READ];

  /// Returns true if the health platform is available on this device.
  Future<bool> isAvailable() async {
    try {
      return _health.isDataTypeAvailable(HealthDataType.HEART_RATE);
    } catch (_) {
      return false;
    }
  }

  /// Requests read permissions for heart rate data.
  /// Returns true if permissions were granted.
  Future<bool> requestPermissions() async {
    try {
      await _health.configure(useHealthConnectIfAvailable: Platform.isAndroid);
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Returns the average heart rate (bpm) over the last 30 minutes,
  /// or null if no data is available.
  Future<double?> getRecentHeartRate() async {
    try {
      await _health.configure(useHealthConnectIfAvailable: Platform.isAndroid);
      final now = DateTime.now();
      final start = now.subtract(const Duration(minutes: 30));

      final dataPoints = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: _types,
      );

      if (dataPoints.isEmpty) return null;

      // Extract numeric bpm values.
      final bpmValues = dataPoints
          .map((dp) => dp.value)
          .whereType<NumericHealthValue>()
          .map((v) => v.numericValue.toDouble())
          .where((v) => v > 0)
          .toList();

      if (bpmValues.isEmpty) return null;

      final avg = bpmValues.reduce((a, b) => a + b) / bpmValues.length;
      return avg;
    } catch (_) {
      return null;
    }
  }
}
