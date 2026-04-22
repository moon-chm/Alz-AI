import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'level_provider.g.dart';

@Riverpod(keepAlive: true)
class PatientLevel extends _$PatientLevel {
  @override
  int build() {
    _init();
    return 1;
  }

  Future<void> _init() async {
    final storage = ref.watch(storageServiceProvider);
    final level = await storage.getLevel();
    state = level ?? 1;
  }
}

@Riverpod(keepAlive: true)
Future<String> patientName(Ref ref) async {
  final storage = ref.watch(storageServiceProvider);
  return await storage.getFullName() ?? 'Patient';
}
