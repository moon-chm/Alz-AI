import 'api_service.dart';
import 'package:mobile/models/photo.dart';

class PhotoService {
  final ApiService _api;
  
  PhotoService(this._api);
  
  Future<List<FamilyPhoto>> fetchFamilyPhotos(String patientId, {int page = 1}) async {
    try {
      final response = await _api.get('/patient/photos', params: {
        'page': page,
        'limit': 12,
        'patient_id': patientId,
      });
      final List<dynamic> data = response.data is Map ? (response.data['photos'] ?? []) : response.data;
      return data.map((p) => FamilyPhoto.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> markPhotoViewed(String photoId) async {
    try {
      await _api.post('patient/photos/$photoId/viewed');
    } catch (e) {
      // Ignore
    }
  }
}
