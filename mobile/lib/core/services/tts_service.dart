import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});

class TTSService {
  final FlutterTts _tts = FlutterTts();
  final _isSpeakingController = StreamController<bool>.broadcast();

  Stream<bool> get isSpeakingStream => _isSpeakingController.stream;

  TTSService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _isSpeakingController.add(true);
    });

    _tts.setCompletionHandler(() {
      _isSpeakingController.add(false);
    });

    _tts.setErrorHandler((msg) {
      _isSpeakingController.add(false);
    });
  }

  Future<void> setLanguage(String languageCode) async {
    // Mapping: hi -> hi-IN, mr -> mr-IN, en -> en-US
    String code = 'en-US';
    if (languageCode == 'hi') code = 'hi-IN';
    if (languageCode == 'mr') code = 'mr-IN';
    
    await _tts.setLanguage(code);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeakingController.add(false);
  }

  Future<void> playAudioFromUrl(String url) async {
    // We can use audioplayers here, but the user requested it in tts_service to coordinate with TTS.
    // However, audioplayers is already imported in saathi_controller.dart. But the instructions say:
    // "File: lib/core/services/tts_service.dart: Add one method: playAudioFromUrl(String url)"
    // So let's import audioplayers here if needed or instantiate locally
    try {
      await stop(); // Cancel existing TTS
      final player = AudioPlayer();
      await player.play(UrlSource(url));
      // wait until it finishes
      await player.onPlayerComplete.first;
      await player.dispose();
    } catch (e) {
      // Complete normally without throwing
    }
  }

  void dispose() {
    _isSpeakingController.close();
  }
}
