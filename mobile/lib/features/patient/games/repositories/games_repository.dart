import 'package:alz_ai/core/network/dio_client.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'games_repository.g.dart';

class GamesRepository {
  final DioClient _client;
  final StorageService _storage;

  GamesRepository(this._client, this._storage);

  Future<void> recordMetric({
    required String metricType,
    required int value,
  }) async {
    print('GAMES_REPO: Recording metric $metricType = $value');
    final patientId = await _storage.getPatientId();
    print('GAMES_REPO: Patient ID = $patientId');
    
    if (patientId == null) {
      print('GAMES_REPO: ERROR - patientId is null');
      return;
    }

    final result = await _client.request(
      (dio) => dio.post(
        '/analytics/record',
        queryParameters: {
          'patient_id': patientId,
          'metric_type': metricType,
          'value': value,
        },
      ),
    );

    result.fold(
      (failure) => print('GAMES_REPO: ERROR - ${failure.message}'),
      (success) => print('GAMES_REPO: SUCCESS - Metric recorded'),
    );
  }
}

@riverpod
GamesRepository gamesRepository(Ref ref) {
  return GamesRepository(
    ref.watch(dioClientProvider),
    ref.watch(storageServiceProvider),
  );
}
