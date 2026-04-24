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
import 'package:audioplayers/audioplayers.dart';

part 'saathi_controller.g.dart';

@riverpod
class Saathi extends _$Saathi {
  late final AudioPlayer _audioPlayer;

  @override
  SaathiState build() {
    _audioPlayer = AudioPlayer();
    _init();
    
    // Smooth State Reset on Audio Completion
    _audioPlayer.onPlayerComplete.listen((_) {
      state.maybeMap(
        speaking: (speakingState) {
          state = SaathiState.idle(displayMessage: speakingState.response);
        },
        orElse: () {},
      );
    });

    // Cleanup player on dispose
    ref.onDispose(() => _audioPlayer.dispose());
    
    return const SaathiState.idle(displayMessage: '...');
  }

  Future<void> _init() async {
    final lang = ref.watch(languageProvider);
    final storage = ref.watch(storageServiceProvider);
    final patientId = await storage.getPatientId() ?? '';
    final level = ref.watch(patientLevelProvider);

    if (patientId.isEmpty) {
      final fallbacks = {
        'hi': 'नमस्ते! मैं आपकी सारथी हूँ।',
        'mr': 'नमस्ते! मी तुमची सारथी आहे।',
        'en': 'Hello! I am your Saathi.',
      };
      state = SaathiState.idle(displayMessage: fallbacks[lang] ?? fallbacks['en']!);
      return;
    }

    final result = await ref.read(saathiRepositoryProvider).fetchGreeting(patientId, lang);
    
    result.fold(
      (l) => _handleError(lang),
      (greetingData) async {
        final greeting = greetingData.text;
        final voiceSampleUrl = greetingData.voiceSampleUrl;
        
        state = SaathiState.idle(displayMessage: greeting);
        
        if (level == 3) {
          final tts = ref.read(ttsServiceProvider);
          await tts.setLanguage(lang);

          if (voiceSampleUrl != null && voiceSampleUrl.isNotEmpty) {
            await tts.playAudioFromUrl(voiceSampleUrl);
            await tts.speak(greeting);
          } else {
            await tts.speak(greeting);
          }
        }
      },
    );
  }

  Future<void> startRecording() async {
    try {
      await _audioPlayer.stop();
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
      (data) async {
        final response = data['response'] as String? ?? '';
        final audioUrl = data['audio_url'] as String?;

        // Cache response string (keep last 5)
        final cache = prefs.getStringList('saathi_cache') ?? [];
        if (!cache.contains(response)) {
          cache.insert(0, response);
          if (cache.length > 5) cache.removeLast();
          await prefs.setStringList('saathi_cache', cache);
        }

        state = SaathiState.speaking(response: response);
        
        if (audioUrl != null && audioUrl.isNotEmpty) {
          try {
            await _audioPlayer.play(UrlSource(audioUrl));
          } catch (e) {
            // Fallback to TTS if streaming fails
            final lang = ref.read(languageProvider);
            final tts = ref.read(ttsServiceProvider);
            await tts.setLanguage(lang);
            await tts.speak(response);
          }
        } else {
          final lang = ref.read(languageProvider);
          final tts = ref.read(ttsServiceProvider);
          await tts.setLanguage(lang);
          await tts.speak(response);
        }
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
