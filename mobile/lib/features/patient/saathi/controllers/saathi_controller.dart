import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alz_ai/core/services/audio_recorder_service.dart';
import 'package:alz_ai/core/services/tts_service.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/features/patient/saathi/models/saathi_state.dart';
import 'package:alz_ai/features/patient/saathi/repositories/saathi_repository.dart';
import 'package:alz_ai/core/providers/level_provider.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saathi_controller.g.dart';

@riverpod
class Saathi extends _$Saathi {
  @override
  SaathiState build() {
    _init();
    return const SaathiState.idle(displayMessage: '...');
  }

  Future<void> _init() async {
    final lang = ref.watch(languageProvider);
    final storage = ref.watch(storageServiceProvider);
    final patientId = await storage.getPatientId() ?? '';
    final level = ref.watch(patientLevelProvider);

    final result = await ref.read(saathiRepositoryProvider).fetchGreeting(patientId, lang);
    
    result.fold(
      (l) => _handleError(lang),
      (greeting) {
        state = SaathiState.idle(displayMessage: greeting);
        if (level == 3) {
          final tts = ref.read(ttsServiceProvider);
          tts.setLanguage(lang);
          tts.speak(greeting);
        }
      },
    );
  }

  Future<void> startRecording() async {
    try {
      await ref.read(ttsServiceProvider).stop();
      await ref.read(audioRecorderServiceProvider).startRecording();
      state = const SaathiState.recording();
    } catch (e) {
      final lang = ref.read(languageProvider);
      _handleError(lang);
    }
  }

  Future<void> stopAndUpload() async {
    state = const SaathiState.uploading();
    final path = await ref.read(audioRecorderServiceProvider).stopRecording();
    
    if (path == null) {
      final lang = ref.read(languageProvider);
      _handleError(lang);
      return;
    }

    final storage = ref.read(storageServiceProvider);
    final patientId = await storage.getPatientId() ?? '';
    final result = await ref.read(saathiRepositoryProvider).sendVoiceMessage(path, patientId);

    final prefs = await SharedPreferences.getInstance();

    result.fold(
      (l) => _handleError(ref.read(languageProvider)),
      (response) async {
        // Cache response string (keep last 5)
        final cache = prefs.getStringList('saathi_cache') ?? [];
        if (!cache.contains(response)) {
          cache.insert(0, response);
          if (cache.length > 5) cache.removeLast();
          await prefs.setStringList('saathi_cache', cache);
        }

        state = SaathiState.speaking(response: response);
        final lang = ref.read(languageProvider);
        final tts = ref.read(ttsServiceProvider);
        await tts.setLanguage(lang);
        await tts.speak(response);
        
        Future.delayed(const Duration(seconds: 2), () {
          state = SaathiState.idle(displayMessage: response);
        });
      },
    );
  }

  void _handleError(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getStringList('saathi_cache') ?? [];
    
    if (cache.isNotEmpty) {
      // Use most recent cache
      final response = cache.first;
      state = SaathiState.speaking(response: response);
      final tts = ref.read(ttsServiceProvider);
      await tts.setLanguage(lang);
      await tts.speak(response);
      
      Future.delayed(const Duration(seconds: 2), () {
        state = SaathiState.idle(displayMessage: response);
      });
      return;
    }

    final fallbacks = {
      'hi': 'थोड़ा रुको, मैं सुन रही हूँ।',
      'mr': 'थांबा, मी ऐकते।',
      'en': 'Give me a moment, I am listening.',
    };
    
    state = SaathiState.error(fallbackMessage: fallbacks[lang] ?? fallbacks['en']!);
    
    Future.delayed(const Duration(seconds: 3), () {
      _init();
    });
  }
}
