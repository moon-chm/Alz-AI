import 'api_service.dart';
import 'package:mobile/models/medication.dart';

class MedicationService {
  final ApiService _api;
  
  MedicationService(this._api);
  
  Future<List<Medication>> getTodaysMedications(String patientId) async {
    final response = await _api.get('/caretaker/medications');
    final List<dynamic> data = response.data;
    return data.map((m) => Medication.fromJson(m)).toList();
  }
  
  Future<bool> confirmMedicationTaken(String medicationId) async {
    final response = await _api.post('patient/medication/confirm', data: {
      'medication_id': medicationId,
    });
    return response.statusCode == 200;
  }
  
  Future<List<Map<String, dynamic>>> getComplianceGrid(String patientId) async {
    final response = await _api.get('/analytics/medication/$patientId');
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  List<Medication> getMedicationsDueNow(List<Medication> medications) {
    final now = DateTime.now();
    return medications.where((med) {
      if (!med.isActive) return false;
      return med.scheduledTimes.any((timeStr) {
        final parts = timeStr.split(':');
        if (parts.length < 2) return false;
        final scheduledHour = int.parse(parts[0]);
        final scheduledMin = int.parse(parts[1]);
        final diff = (now.hour * 60 + now.minute) - (scheduledHour * 60 + scheduledMin);
        return diff.abs() <= 30;
      });
    }).toList();
  }
}
