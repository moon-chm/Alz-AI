import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:alz_ai/features/patient/background/models/background_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceService {
  static const String _latKey = 'geofence_lat';
  static const String _lngKey = 'geofence_lng';
  static const String _radiusKey = 'geofence_radius';
  
  final _eventController = StreamController<BackgroundEvent>.broadcast();
  Stream<BackgroundEvent> get events => _eventController.stream;

  Timer? _pollingTimer;
  Timer? _boundaryTimer;
  bool _isBreached = false;

  GeofenceService() {
    _fetchBoundaries();
    _startPolling();
    _boundaryTimer = Timer.periodic(const Duration(hours: 6), (_) => _fetchBoundaries());
  }

  Future<void> _fetchBoundaries() async {
    // This logic would normally hit GET /api/caretaker/geofence
    // For now we assume a mechanism to hit the API or use a repo
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    final interval = _isBreached ? const Duration(seconds: 60) : const Duration(minutes: 3);
    _pollingTimer = Timer.periodic(interval, (_) => _checkGeofence());
  }

  Future<void> _checkGeofence() async {
    final prefs = await SharedPreferences.getInstance();
    final centerLat = prefs.getDouble(_latKey);
    final centerLng = prefs.getDouble(_lngKey);
    final radius = prefs.getDouble(_radiusKey);

    if (centerLat == null || centerLng == null || radius == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        centerLat,
        centerLng,
      );

      if (distance > radius && !_isBreached) {
        _isBreached = true;
        _eventController.add(BackgroundEvent.geofenceBreached(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now().toIso8601String(),
        ));
        _startPolling(); // Speed up polling
      } else if (distance <= radius && _isBreached) {
        _isBreached = false;
        _eventController.add(BackgroundEvent.geofenceRestored(
          timestamp: DateTime.now().toIso8601String(),
        ));
        _startPolling(); // Back to normal polling
      }
    } catch (e) {
      // Ignore GPS errors
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 + 
          cos(lat1 * p) * cos(lat2 * p) * 
          (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km to meters
  }

  void dispose() {
    _pollingTimer?.cancel();
    _eventController.close();
  }
}
