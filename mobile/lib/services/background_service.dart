import 'dart:math';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'api_service.dart';
import 'ble_service.dart';
import 'health_service.dart';
import 'package:mobile/core/utils/logger.dart';

class BackgroundServiceManager {
  final BLEService _bleService;
  final HealthService _healthService;
  final ApiService _apiService;

  BackgroundServiceManager(this._bleService, this._healthService, this._apiService);

  static const HR_HIGH = 120;
  static const HR_LOW = 45;
  static const BAT_LOW = 20;
  static const WATCH_DISC_MINS = 30;

  static const FALL_ACCEL_THRESHOLD = 2.5; 
  static const FALL_STILL_THRESHOLD = 0.5; 
  static const FALL_STILL_DURATION = 60; 
  static const FALL_WINDOW_SECS = 5; 
  static const FALL_COOLDOWN_MINS = 5; 

  bool _phoneFallFlag = false;
  bool _watchFallFlag = false;
  DateTime? _phoneFallAt;
  DateTime? _watchFallAt;
  DateTime? _lastFallAlert;

  Future<void> initialize() async {
    try {
      await _bleService.initialize();

      _bleService.heartRateStream.listen((hr) {
        _checkHRThreshold(hr);
      });

      _bleService.connectionStream.listen((connected) {
        if (!connected) _startWatchDisconnectTimer();
      });

      Timer.periodic(const Duration(minutes: 5), (_) async {
        int bat = await _bleService.getBatteryLevel();
        if (bat != -1 && bat < BAT_LOW) _alertLowBattery(bat);
        _checkWatchDisconnectDuration();
      });

      accelerometerEventStream().listen((event) {
        _processAccelerometer(event.x, event.y, event.z);
      });

      Workmanager().registerPeriodicTask(
        'analytics_sync',
        'analyticsSync',
        frequency: const Duration(minutes: 30),
        constraints: Constraints(networkType: NetworkType.connected),
      );

      _scheduleCheckins();

      Workmanager().registerPeriodicTask(
        'medication_check',
        'medicationCheck',
        frequency: const Duration(minutes: 15),
      );
    } catch (e) {
      AppLogger.error('BackgroundService: Initialization failed', e);
    }
  }

  void _checkHRThreshold(int hr) {
    if (hr > HR_HIGH) {
      _createAlert('high_heart_rate', 4, 'Heart rate elevated: $hr BPM');
    }
    if (hr < HR_LOW && hr > 0) {
      _createAlert('low_heart_rate', 4, 'Heart rate very low: $hr BPM');
    }
  }

  void _processAccelerometer(double x, double y, double z) {
    double magnitude = sqrt(x * x + y * y + z * z) / 9.8; 

    if (magnitude > FALL_ACCEL_THRESHOLD) {
      _monitorStillnessAfterImpact(magnitude);
    }
  }

  void _monitorStillnessAfterImpact(double impactG) {
    int stillSeconds = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (stillSeconds >= FALL_STILL_DURATION) {
        timer.cancel();
        _phoneFallFlag = true;
        _phoneFallAt = DateTime.now();
        _checkDualConfirmation();
      }
      stillSeconds++;
    });
  }

  void _checkDualConfirmation() {
    if (_lastFallAlert != null) {
      if (DateTime.now().difference(_lastFallAlert!).inMinutes < FALL_COOLDOWN_MINS) return;
    }

    if (_phoneFallFlag && _watchFallFlag && _phoneFallAt != null && _watchFallAt != null) {
      Duration diff = _phoneFallAt!.difference(_watchFallAt!).abs();
      if (diff.inSeconds <= FALL_WINDOW_SECS) {
        _createFallAlert('high', 'dual_sensor');
        return;
      }
    }

    if (_phoneFallFlag) _createFallAlert('standard', 'phone_only');
    if (_watchFallFlag) _createFallAlert('standard', 'watch_only');

    _phoneFallFlag = false;
    _watchFallFlag = false;
    _lastFallAlert = DateTime.now();
  }

  void _createFallAlert(String confidence, String source) {
    _apiService.post('patient/sos', data: {
      'alert_type': 'fall_detected',
      'confidence': confidence,
      'source': source,
    });
  }

  void _startWatchDisconnectTimer() {}

  void _alertLowBattery(int batteryLevel) {
    _createAlert('watch_low_battery', 2, 'Watch battery at $batteryLevel%');
  }

  void _checkWatchDisconnectDuration() {
    Duration? disc = _bleService.disconnectedDuration;
    if (disc != null && disc.inMinutes >= WATCH_DISC_MINS) {
      _createAlert('watch_disconnected', 3, 'Watch disconnected for ${disc.inMinutes} minutes');
    }
  }

  void _scheduleCheckins() {
    Workmanager().registerPeriodicTask(
      'morning_checkin',
      'morningCheckin',
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntil(7, 0),
    );
    Workmanager().registerPeriodicTask(
      'night_checkin',
      'nightCheckin',
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntil(22, 0),
    );
  }

  Duration _delayUntil(int hour, int minute) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));
    return target.difference(now);
  }

  void _createAlert(String type, int severity, String message) {
    _apiService.post('patient/sos', data: {
      'alert_type': type,
      'severity': severity,
      'message': message,
    });
  }
}

final backgroundServiceProvider = Provider((ref) {
  final api = ref.watch(apiServiceProvider);
  final health = ref.watch(healthServiceProvider);
  final ble = BLEService(); // BLEService is still essentially global/singleton but could be refactored too if needed
  return BackgroundServiceManager(ble, health, api);
});
