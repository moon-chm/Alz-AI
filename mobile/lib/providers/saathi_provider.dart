import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/saathi_service.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import 'core_providers.dart';
import 'package:mobile/models/saathi_response.dart';
import 'package:mobile/core/utils/exceptions.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:just_audio/just_audio.dart' show PlayerState, ProcessingState;

@immutable
class SAATHIState {
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final SaathiException? lastError;
  final SAATHIResponse? lastResponse;
  final List<Map<String, String>> messages;
  final String mood;
  
  const SAATHIState({
    this.isListening = false,
    this.isSpeaking = false,
    this.isProcessing = false,
    this.lastError,
    this.lastResponse,
    this.messages = const [],
    this.mood = 'neutral',
  });
  
  SAATHIState copyWith({
    bool? isListening,
    bool? isSpeaking,
    bool? isProcessing,
    SaathiException? lastError,
    SAATHIResponse? lastResponse,
    List<Map<String, String>>? messages,
    String? mood,
    bool clearError = false,
  }) {
    return SAATHIState(
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isProcessing: isProcessing ?? this.isProcessing,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastResponse: lastResponse ?? this.lastResponse,
      messages: messages ?? this.messages,
      mood: mood ?? this.mood,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SAATHIState &&
      other.isListening == isListening &&
      other.isSpeaking == isSpeaking &&
      other.isProcessing == isProcessing &&
      other.lastError == lastError &&
      other.lastResponse == lastResponse &&
      listEquals(other.messages, messages) &&
      other.mood == mood;
  }

  @override
  int get hashCode {
    return Object.hash(
      isListening,
      isSpeaking,
      isProcessing,
      lastError,
      lastResponse,
      Object.hashAll(messages),
      mood,
    );
  }
}

class SAATHINotifier extends StateNotifier<SAATHIState> {
  final SaathiService _saathiService;
  final AudioService _audioService;
  String? _patientId;
  CancelToken? _currentRequest;
  
  SAATHINotifier(this._saathiService, this._audioService) : super(const SAATHIState()) {
    _setupAudioListener();
  }

  void _setupAudioListener() {
    _audioService.playerStateStream.listen((playerState) {
       // Only trigger update if state transition is relevant
       if (playerState.processingState == ProcessingState.completed && state.isSpeaking) {
          AppLogger.info('SAATHI: Audio playback completed');
          state = state.copyWith(isSpeaking: false);
       }
    });
  }
  
  void setPatientId(String id) => _patientId = id;
  
  Future<void> startListening() async {
    if (state.isListening) return;
    
    // Cancel any pending AI request if user starts talking again
    _currentRequest?.cancel('User started new recording');
    
    try {
      await _audioService.stopPlayback();
      await _audioService.startRecording();
      state = state.copyWith(isListening: true, isSpeaking: false, clearError: true);
    } catch (e) {
      AppLogger.error('SAATHI: Failed to start recording', e);
      state = state.copyWith(lastError: NetworkException('Microphone access denied'));
    }
  }
  
  Future<void> stopListeningAndSend() async {
    if (!state.isListening) return;
    
    final updatedMessages = List<Map<String, String>>.from(state.messages);
    updatedMessages.add({'role': 'user', 'text': '🎤 (Voice Message)'});
    
    state = state.copyWith(
      isListening: false, 
      isProcessing: true,
      messages: updatedMessages,
    );
    
    _currentRequest = CancelToken();
    
    try {
      final filePath = await _audioService.stopRecording();
      final response = await _saathiService.talk(
        filePath, 
        _patientId ?? '',
        cancelToken: _currentRequest,
      );
      
      final finalMessages = List<Map<String, String>>.from(state.messages);
      finalMessages.add({'role': 'assistant', 'text': response.text});

      state = state.copyWith(
        isProcessing: false,
        isSpeaking: true,
        lastResponse: response,
        messages: finalMessages,
        mood: response.mood,
      );
      
      await _audioService.playAudio(response.audioUrl);
      await _audioService.deleteAudioFile(filePath);
      
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.info('SAATHI: Request cancelled by user action');
        return;
      }
      
      final saathiErr = e.error is SaathiException 
          ? e.error as SaathiException 
          : UnknownException();
          
      state = state.copyWith(
        isProcessing: false,
        lastError: saathiErr,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        lastError: UnknownException(),
      );
    } finally {
      _currentRequest = null;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final saathiProvider = StateNotifierProvider<SAATHINotifier, SAATHIState>((ref) {
  final service = ref.watch(saathiServiceProvider);
  final audio = ref.watch(audioServiceProvider);
  return SAATHINotifier(service, audio);
});
