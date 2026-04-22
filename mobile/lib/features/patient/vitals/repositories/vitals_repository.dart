import 'package:fpdart/fpdart.dart';
import 'package:alz_ai/core/error/app_failure.dart';
import 'package:alz_ai/core/network/dio_client.dart';
import 'package:alz_ai/features/patient/vitals/models/vitals_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vitals_repository.g.dart';

class VitalsRepository {
  final DioClient _client;

  VitalsRepository(this._client);

  /// Synchronize vitals to the backend.
  /// Maps to POST /api/caretaker/vitals
  Future<Either<AppFailure, bool>> syncVitals(String patientId, VitalsReading reading) async {
    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.post('caretaker/vitals', data: {
        'patient_id': patientId,
        ...reading.toJson(),
      }),
    );

    return result.map((data) => true);
  }

  /// Fetch latest vitals from the backend.
  /// Maps to GET /api/caretaker/vitals
  Future<Either<AppFailure, VitalsReading>> fetchLatestVitals(String patientId) async {
    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.get('caretaker/vitals', queryParameters: {'patient_id': patientId}),
    );

    return result.map((data) => VitalsReading.fromJson(data));
  }
}

@riverpod
VitalsRepository vitalsRepository(Ref ref) {
  return VitalsRepository(ref.watch(dioClientProvider));
}
