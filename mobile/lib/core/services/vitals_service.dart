import 'package:health/health.dart';
import 'package:alz_ai/features/patient/vitals/models/vitals_models.dart';
import 'package:flutter/foundation.dart';

class VitalsService {
  final Health _health = Health();

  static final List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  ];

  Future<bool> checkAvailability() async {
    // Check if Health Connect is installed/supported
    final available = await _health.isHealthConnectAvailable();
    if (!available) {
      // Prompt installation if missing (for pre-Android 14)
      await _health.installHealthConnect();
    }
    return available;
  }

  Future<bool> hasPermissions() async {
    return await _health.hasPermissions(_types) ?? false;
  }

  Future<bool> requestPermissions() async {
    final granted = await _health.requestAuthorization(_types);
    return granted;
  }

  Future<VitalsReading?> readCurrentVitals() async {
    try {
      // Check permissions first to avoid native overhead if not authorized
      final hasPerms = await _health.hasPermissions(_types) ?? false;
      if (!hasPerms) return null;

      final now = DateTime.now();
      // Read heart rate from last 2 minutes to ensure we get a recent reading
      final hrStart = now.subtract(const Duration(minutes: 2));
      // Steps for today
      final midnight = DateTime(now.year, now.month, now.day);
      // Sleep for last 24h
      final dayAgo = now.subtract(const Duration(hours: 24));

      // Unified Fetch
      final data = await _health.getHealthDataFromTypes(
        startTime: dayAgo,
        endTime: now,
        types: _types,
      );

      if (data.isEmpty) return null;

      // 1. Sort by date descending to get most recent first
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));

      // 2. Filter and pick latest for each
      int heartRate = 0;
      int spo2 = 0;
      int steps = 0;
      int sleepMinutes = 0;
      double? hrv;

      for (var point in data) {
        final val = point.value;
        if (point.type == HealthDataType.HEART_RATE && heartRate == 0) {
          heartRate = (val as NumericHealthValue).numericValue.toInt();
        } else if (point.type == HealthDataType.BLOOD_OXYGEN && spo2 == 0) {
          spo2 = ((val as NumericHealthValue).numericValue * 100).toInt();
        } else if (point.type == HealthDataType.HEART_RATE_VARIABILITY_RMSSD && hrv == null) {
          hrv = (val as NumericHealthValue).numericValue.toDouble();
        }
      }

      // Special handling for Steps and Sleep to be more accurate
      steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;
      
      // Calculate sleep minutes from sessions in the last 24h
      final sleepData = data.where((e) => e.type == HealthDataType.SLEEP_SESSION).toList();
      double totalSleepMinutes = 0;
      for (var s in sleepData) {
        totalSleepMinutes += s.dateTo.difference(s.dateFrom).inMinutes;
      }
      sleepMinutes = totalSleepMinutes.toInt();

      return VitalsReading(
        heartRate: heartRate,
        spo2: spo2,
        steps: steps,
        sleepMinutes: sleepMinutes,
        hrv: hrv,
        recordedAt: now,
      );
    } catch (e) {
      debugPrint("VitalsService Error: $e");
      return null;
    }
  }
}
