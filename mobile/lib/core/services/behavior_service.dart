import 'package:alz_ai/core/network/dio_client.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/features/patient/background/models/background_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'behavior_service.g.dart';

class BehaviorService {
  final DioClient _client;
  final StorageService _storage;

  BehaviorService(this._client, this._storage);

  Future<BackgroundEvent?> checkBehavior() async {
    final patientId = await _storage.getPatientId();
    if (patientId == null) return null;

    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.get('caretaker/behavior', queryParameters: {'patient_id': patientId}),
    );

    return result.match(
      (failure) => null,
      (data) {
        final deviationDetected = data['deviation_detected'] as bool? ?? false;
        if (deviationDetected) {
          final message = data['deviation_message'] as String? ?? 'A slight change in behavior was noted.';
          return BackgroundEvent.behaviorDeviation(
            message: message,
            timestamp: DateTime.now().toIso8601String(),
          );
        }
        return null;
      },
    );
  }
}

@riverpod
BehaviorService behaviorService(Ref ref) {
  return BehaviorService(
    ref.watch(dioClientProvider),
    ref.watch(storageServiceProvider),
  );
}
