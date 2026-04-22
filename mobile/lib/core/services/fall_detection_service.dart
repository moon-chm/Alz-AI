import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:alz_ai/features/patient/background/models/background_models.dart';

class FallDetectionService {
  final _eventController = StreamController<BackgroundEvent>.broadcast();
  Stream<BackgroundEvent> get events => _eventController.stream;

  StreamSubscription? _accelerometerSub;
  DateTime? _lastAlertTime;
  DateTime? _impactDetectedTime;

  FallDetectionService() {
    _startMonitoring();
  }

  void _startMonitoring() {
    _accelerometerSub = accelerometerEvents.listen((event) {
      _processAccelerometerData(event.x, event.y, event.z);
    });
  }

  void _processAccelerometerData(double x, double y, double z) {
    // Magnitude = sqrt(x² + y² + z²)
    final magnitude = sqrt(x * x + y * y + z * z);
    final now = DateTime.now();

    // 10-second cooldown
    if (_lastAlertTime != null && now.difference(_lastAlertTime!).inSeconds < 10) return;

    // High acceleration event (> 2.5g = 24.5 m/s²)
    if (magnitude > 24.5) {
      _impactDetectedTime = now;
    }

    // Check for stillness/freefall (< 0.5g = 4.9 m/s²) after high acceleration
    if (_impactDetectedTime != null) {
      final timeSinceImpact = now.difference(_impactDetectedTime!).inMilliseconds;
      
      if (timeSinceImpact <= 600) {
        if (magnitude < 4.9 && timeSinceImpact > 50) {
          _triggerFallDetected();
        }
      } else {
        _impactDetectedTime = null; // Window closed
      }
    }
  }

  void _triggerFallDetected() {
    _lastAlertTime = DateTime.now();
    _impactDetectedTime = null;
    _eventController.add(BackgroundEvent.fallDetected(
      timestamp: DateTime.now().toIso8601String(),
    ));
  }

  void dispose() {
    _accelerometerSub?.cancel();
    _eventController.close();
  }
}
