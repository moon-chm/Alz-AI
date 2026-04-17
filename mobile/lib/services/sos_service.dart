import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import 'api_service.dart';

class SOSService {
  final ApiService _api;
  
  SOSService(this._api);
  
  Future<bool> triggerSOS() async {
    AppLogger.info('SOS: TRIGGERED');
    try {
      final position = await _getCurrentLocation();
      
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(
          pattern: [0, 200, 100, 200, 100, 600, 100, 600, 100, 600, 100, 200, 100, 200],
          intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
        );
      }
      
      await _api.post('patient/sos', data: {
        'lat': position?.latitude ?? 0.0,
        'lng': position?.longitude ?? 0.0,
      });
      
      return true;
    } catch (e) {
      try {
        await _api.post('patient/sos', data: {'lat': 0.0, 'lng': 0.0});
      } catch (_) {}
      return false;
    }
  }
  
  Future<Position?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      return null;
    }
  }
}
