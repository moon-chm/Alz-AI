import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alz_ai/features/patient/background/models/background_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceService {
  static const String _geofenceCoordsKey = 'geofence_coords';
  
  final Dio? _dio;
  final _eventController = StreamController<BackgroundEvent>.broadcast();
  Stream<BackgroundEvent> get events => _eventController.stream;

  Timer? _pollingTimer;
  Timer? _boundaryTimer;
  bool _isBreached = false;

  GeofenceService([this._dio]) {
    _fetchBoundaries();
    _startPolling();
    _boundaryTimer = Timer.periodic(const Duration(hours: 6), (_) => _fetchBoundaries());
  }

  Future<void> _fetchBoundaries() async {
    if (_dio == null) return;
    
    try {
      final response = await _dio!.get('patient/geofence');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> coords = response.data['coordinates'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_geofenceCoordsKey, jsonEncode(coords));
      }
    } catch (e) {
      // Use cached boundaries if fetch fails
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Higher safety check frequency when breached or nearby, 
    // but default for Alzheimer's is to keep it consistent
    final interval = _isBreached ? const Duration(seconds: 60) : const Duration(minutes: 3);
    _pollingTimer = Timer.periodic(interval, (_) => _checkGeofence());
  }

  Future<void> _checkGeofence() async {
    final prefs = await SharedPreferences.getInstance();
    final coordsRaw = prefs.getString(_geofenceCoordsKey);
    if (coordsRaw == null) return;

    try {
      final List<dynamic> polygon = jsonDecode(coordsRaw);
      if (polygon.length < 3) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final isSafe = _isPointInPolygon(
        position.latitude,
        position.longitude,
        polygon,
      );

      if (!isSafe && !_isBreached) {
        _isBreached = true;
        _eventController.add(BackgroundEvent.geofenceBreached(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now().toIso8601String(),
        ));
        _startPolling(); // Faster checks when outside
      } else if (isSafe && _isBreached) {
        _isBreached = false;
        _eventController.add(BackgroundEvent.geofenceRestored(
          timestamp: DateTime.now().toIso8601String(),
        ));
        _startPolling(); // Normal checks when back inside
      }
    } catch (e) {
      // Ignore GPS errors
    }
  }

  bool _isPointInPolygon(double lat, double lng, List<dynamic> polygon) {
    bool isInside = false;
    final int n = polygon.length;
    var p1 = polygon[0];
    
    for (int i = 1; i <= n; i++) {
      var p2 = polygon[i % n];
      if (lng > min(p1['lng'], p2['lng'])) {
        if (lng <= max(p1['lng'], p2['lng'])) {
          if (lat <= max(p1['lat'], p2['lat'])) {
            if (p1['lng'] != p2['lng']) {
              double xInters = (lng - p1['lng']) * (p2['lat'] - p1['lat']) / (p2['lng'] - p1['lng']) + p1['lat'];
              if (p1['lat'] == p2['lat'] || lat <= xInters) {
                isInside = !isInside;
              }
            }
          }
        }
      }
      p1 = p2;
    }
    return isInside;
  }

  void dispose() {
    _pollingTimer?.cancel();
    _boundaryTimer?.cancel();
    _eventController.close();
  }
}
