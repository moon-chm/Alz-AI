import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'language_provider.g.dart';

@Riverpod(keepAlive: true)
class Language extends _$Language {
  @override
  String build() {
    _init();
    return 'en';
  }

  Future<void> _init() async {
    final storage = ref.watch(storageServiceProvider);
    final lang = await storage.getLanguage();
    state = lang ?? 'en';
  }

  Future<void> setLanguage(String newLang) async {
    state = newLang;
    // Persist if needed in future
  }
}
