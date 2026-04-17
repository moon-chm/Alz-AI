import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../providers/core_providers.dart';
import 'package:mobile/models/saathi_response.dart';
import 'package:mobile/core/utils/logger.dart';

const Map<String, int> _offlineClipCounts = {
  'greetings': 10,
  'reassurance': 10,
  'medication_reminders': 10,
  'family_references': 10,
  'comfort_phrases': 10,
};

class SaathiService {
  final ApiService _api;
  final _random = Random();
  
  SaathiService(this._api);
  
  Future<SAATHIResponse> talk(String audioFilePath, String patientId, {CancelToken? cancelToken}) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioFilePath, filename: 'audio.m4a'),
        'patient_id': patientId,
      });
      
      final response = await _api.saathiRequest('/saathi/talk', formData, cancelToken: cancelToken);
      return SAATHIResponse.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.warn('SaathiService: talk request failed/cancelled. Error type: ${e.type}');
      if (e.type == DioExceptionType.cancel) rethrow;
      
      return _getOfflineFallback('reassurance');
    }
  }
  
  SAATHIResponse _getOfflineFallback(String category) {
    final count = _offlineClipCounts[category] ?? 10;
    final clipIndex = _random.nextInt(count) + 1;
    final assetPath = 'assets/audio/saathi_offline/$category/clip_$clipIndex.mp3';
    return SAATHIResponse(
      text: 'SAATHI: (Pre-recorded message)', 
      audioUrl: assetPath, 
      mood: 'neutral',
    );
  }
  
  Future<SAATHIResponse> triggerMorningCheckin(String patientId) async {
    try {
      final response = await _api.post(
        '/saathi/checkin/morning',
        data: {'patient_id': patientId},
      );
      return SAATHIResponse.fromJson(response.data);
    } catch (_) {
      return _getOfflineFallback('greetings');
    }
  }
  
  Future<SAATHIResponse> triggerMedicationCheckin(String patientId) async {
    try {
      final response = await _api.post(
        '/saathi/checkin/medication',
        data: {'patient_id': patientId},
      );
      return SAATHIResponse.fromJson(response.data);
    } catch (_) {
      return _getOfflineFallback('medication_reminders');
    }
  }
  
  Future<SAATHIResponse> triggerNightCheckin(String patientId) async {
    try {
      final response = await _api.post(
        '/saathi/checkin/night',
        data: {'patient_id': patientId},
      );
      return SAATHIResponse.fromJson(response.data);
    } catch (_) {
      return _getOfflineFallback('comfort_phrases');
    }
  }
}

// Riverpod Provider
final saathiServiceProvider = Provider((ref) {
  final api = ref.watch(apiServiceProvider);
  return SaathiService(api);
});
