import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:alz_ai/features/patient/vitals/models/vitals_models.dart';
import 'package:alz_ai/features/patient/vitals/repositories/vitals_repository.dart';
import 'package:alz_ai/core/services/vitals_service.dart';
import 'package:alz_ai/core/storage/storage_service.dart';

part 'vitals_controller.g.dart';

@riverpod
class VitalsController extends _$VitalsController {
  final VitalsService _vitalsService = VitalsService();

  @override
  FutureOr<VitalsReading?> build() async {
    return _fetchLatest();
  }

  Future<VitalsReading?> _fetchLatest() async {
    final storage = ref.read(storageServiceProvider);
    final patientId = await storage.getPatientId();
    if (patientId == null) return null;

    final result = await ref.read(vitalsRepositoryProvider).fetchLatestVitals(patientId);
    return result.fold(
      (l) => null,
      (r) => r,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLatest());
  }

  Future<bool> requestPermissions() async {
    final granted = await _vitalsService.requestPermissions();
    await refresh();
    return granted;
  }

  Future<bool> checkAvailability() async {
    return await _vitalsService.checkAvailability();
  }
}
