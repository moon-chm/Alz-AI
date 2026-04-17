import 'package:health/health.dart';
import 'api_service.dart';
import 'package:mobile/core/utils/logger.dart';

class HealthService {
  final Health _health = Health();
  final ApiService _api;
  
  HealthService(this._api);
  
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.BLOOD_OXYGEN,
  ];
  
  Future<bool> requestPermissions() async {
    try {
      // Version 13.x migration: requestAuthorization now uses HealthDataAccess
      final List<HealthDataAccess> permissions = _types.map((e) => HealthDataAccess.READ).toList();
      return await _health.requestAuthorization(_types, permissions: permissions);
    } catch (e) {
      AppLogger.error('Health: Permission request failed', e);
      return false;
    }
  }
  
  Future<Map<String, dynamic>> fetchVitals() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    try {
      // In v13, getHealthDataFromTypes is the core method
      final data = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: _types,
      );
      
      final steps = data
        .where((d) => d.type == HealthDataType.STEPS)
        .fold(0.0, (sum, d) => sum + (double.tryParse(d.value.toString()) ?? 0.0));
      
      final hrData = data.where((d) => d.type == HealthDataType.HEART_RATE).toList();
      final hr = hrData.isNotEmpty 
        ? (int.tryParse(hrData.last.value.toString()) ?? 0)
        : 0;
      
      final spo2Data = data.where((d) => d.type == HealthDataType.BLOOD_OXYGEN).toList();
      final spo2 = spo2Data.isNotEmpty 
        ? (int.tryParse(spo2Data.last.value.toString()) ?? 0)
        : 0;
      
      final sleepData = data.where((d) => d.type == HealthDataType.SLEEP_ASLEEP).toList();
      final sleepMinutes = sleepData.fold(0.0, (sum, d) => 
        sum + (double.tryParse(d.value.toString()) ?? 0.0));
      final sleepHours = sleepMinutes / 60;
      
      return {
        'steps': steps.toInt(),
        'hr': hr,
        'spo2': spo2,
        'sleep': sleepHours,
      };
    } catch (e) {
      AppLogger.error('Health: Data fetch failed', e);
      return {'steps': 0, 'hr': 0, 'spo2': 0, 'sleep': 0.0};
    }
  }
  
  Future<void> pushVitalsToBackend(String patientId, Map<String, dynamic> vitals) async {
    try {
      await _api.post('alerts/vitals', data: {
        ...vitals,
        'patient_id': patientId,
        'lat': 0.0,
        'lng': 0.0,
      });
    } catch (e) {
      AppLogger.warn('Health: Backend push failed ($e)');
    }
  }
}
