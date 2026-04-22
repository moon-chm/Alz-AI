import 'package:fpdart/fpdart.dart';
import 'package:alz_ai/core/error/app_failure.dart';
import 'package:alz_ai/core/network/dio_client.dart';
import 'package:alz_ai/features/patient/help/models/help_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'help_repository.g.dart';

class HelpRepository {
  final DioClient _client;

  HelpRepository(this._client);

  Future<Either<AppFailure, List<ContactItem>>> fetchContacts(String patientId) async {
    final result = await _client.request<List<dynamic>>(
      (dio) => dio.get('/caretaker/contacts', queryParameters: {'patient_id': patientId}),
    );

    return result.map((data) => data.map((json) => ContactItem.fromJson(json)).toList());
  }

  Future<Either<AppFailure, bool>> triggerSOS(String patientId, double? lat, double? lng) async {
    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.post('/help/sos', data: {
        'patient_id': patientId,
        'latitude': lat,
        'longitude': lng,
      }),
    );

    return result.map((data) => true);
  }
}

@riverpod
HelpRepository helpRepository(Ref ref) {
  return HelpRepository(ref.watch(dioClientProvider));
}
