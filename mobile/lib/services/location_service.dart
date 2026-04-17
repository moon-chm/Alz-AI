import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/utils/logger.dart';

class LocationService {
  LocationService();

  StreamSubscription<Position>? _positionSubscription;
  final _positionController = StreamController<Position>.broadcast();
  
  Stream<Position> get positions => _positionController.stream;
  Position? _lastKnownPosition;
  Position? get lastKnownPosition => _lastKnownPosition;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await _handlePermissions();
    if (!hasPermission) {
      AppLogger.warn('Location: Tracking failed due to lack of permissions');
      return;
    }

    AppLogger.info('Location: Starting high-accuracy real-time tracking');

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
          (position) {
            _lastKnownPosition = position;
            _positionController.add(position);
            AppLogger.debug('Location Update: ${position.latitude}, ${position.longitude}');
          },
          onError: (error) {
            AppLogger.error('Location Error: $error');
            stopTracking();
          },
          cancelOnError: false,
        );

    _isTracking = true;
  }

  Future<bool> _handlePermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warn('Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.warn('Location permissions are denied');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      AppLogger.error('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  void stopTracking() {
    AppLogger.info('Location: Stopping real-time tracking');
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }

  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
