import 'package:fpdart/fpdart.dart';
import 'package:alz_ai/core/error/app_failure.dart';
import 'package:alz_ai/core/network/dio_client.dart';
import 'package:alz_ai/features/patient/medicines/models/medicine_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medicines_repository.g.dart';

class MedicinesRepository {
  final DioClient _client;

  MedicinesRepository(this._client);

  Future<Either<AppFailure, List<MedicationItem>>> fetchTodayMedications(String patientId) async {
    final result = await _client.request<List<dynamic>>(
      (dio) => dio.get('medications', queryParameters: {'patient_id': patientId}),
    );

    return result.map((data) => data.map((json) => MedicationItem.fromJson(json)).toList());
  }

  Future<Either<AppFailure, bool>> markTaken(String medicationId, String patientId) async {
    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.post('medications/taken', data: {
        'medication_id': medicationId,
        'patient_id': patientId,
      }),
    );

    return result.map((data) => true);
  }

  Future<Either<AppFailure, String>> fetchSaathiReminder(String patientId, String medicationId) async {
    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.post('saathi/checkin/medication', data: {
        'patient_id': patientId,
        'medication_id': medicationId,
      }),
    );

    return result.map((data) => data['response'] as String);
  }

  Future<Either<AppFailure, bool>> sendMissedAlert(String patientId, String medicationId) async {
    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.post('caretaker/alert', data: {
        'patient_id': patientId,
        'alert_type': 'medication_missed',
        'medication_id': medicationId,
      }),
    );

    return result.map((data) => true);
  }
}

@riverpod
MedicinesRepository medicinesRepository(Ref ref) {
  return MedicinesRepository(ref.watch(dioClientProvider));
}
