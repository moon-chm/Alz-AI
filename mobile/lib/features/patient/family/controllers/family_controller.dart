import 'dart:io';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/features/patient/family/models/family_models.dart';
import 'package:alz_ai/features/patient/family/repositories/family_repository.dart';
import 'package:alz_ai/core/services/tts_service.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image_picker/image_picker.dart';

part 'family_controller.g.dart';

@riverpod
class FamilyController extends _$FamilyController {
  final _picker = ImagePicker();

  @override
  FamilyState build() {
    fetchFamily();
    return const FamilyState.loading();
  }

  Future<void> fetchFamily() async {
    final storage = ref.read(storageServiceProvider);
    final patientId = await storage.getPatientId();
    if (patientId == null) return;

    final result = await ref.read(familyRepositoryProvider).fetchMembers(patientId);
    result.fold(
      (l) => state = FamilyState.error(failure: l),
      (list) => state = FamilyState.loaded(members: list),
    );
  }

  Future<void> identifyPerson() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final storage = ref.read(storageServiceProvider);
    final patientId = await storage.getPatientId();
    if (patientId == null) return;

    final result = await ref.read(familyRepositoryProvider).identifyFace(patientId, File(image.path));
    
    result.fold(
      (l) => null,
      (response) {
        final currentState = state;
        if (currentState is FamilyStateLoaded) {
          state = currentState.copyWith(identificationResult: response);
        }
        _narrateIdentification(response);
      },
    );
  }

  Future<void> _narrateIdentification(FamilyIdentifyResponse response) async {
    final lang = ref.read(languageProvider);
    final tts = ref.read(ttsServiceProvider);
    await tts.setLanguage(lang);

    if (response.matched && response.description != null) {
      await tts.speak(response.description!);
    } else {
      final fallbacks = {
        'hi': 'इन्हें पहचान नहीं पाया। अपने फैमिली मेंबर्स को कॉल करें।',
        'mr': 'ओळखले नाही। फॅमिली ला कॉल करा।',
        'en': 'I could not recognize this person. Would you like to call your family?',
      };
      await tts.speak(fallbacks[lang] ?? fallbacks['en']!);
    }
  }

  void clearIdentification() {
    final currentState = state;
    if (currentState is FamilyStateLoaded) {
      state = currentState.copyWith(identificationResult: null);
    }
  }
}
