import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'core_providers.dart';

// Controller to manage tracking state and manual overrides
class LocationController extends StateNotifier<bool> {
  final LocationService _service;

  LocationController(this._service) : super(_service.isTracking);

  void startTracking() {
    _service.startTracking();
    state = true;
  }

  void stopTracking() {
    _service.stopTracking();
    state = false;
  }

  bool get isTracking => _service.isTracking;
}

final locationControllerProvider = StateNotifierProvider<LocationController, bool>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationController(service);
});

// StreamProvider for continuous position updates
final locationPositionStreamProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);

  // Automatically start tracking when provider is watched
  if (!service.isTracking) {
    service.startTracking();
  }

  // Stop tracking when provider is disposed
  ref.onDispose(() {
    service.stopTracking();
  });

  return service.positions;
});
