import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:alz_ai/core/error/app_failure.dart';
import 'package:alz_ai/core/network/dio_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saathi_repository.g.dart';

class SaathiRepository {
  final DioClient _dio;

  SaathiRepository(this._dio);

  Future<Either<AppFailure, String>> fetchGreeting(String patientId, String language) async {
    // Mocking the greeting as requested by the user
    await Future.delayed(const Duration(seconds: 1));
    
    final greetings = {
      'en': 'Hello! How are you feeling today?',
      'hi': 'नमस्ते! आज आप कैसा महसूस कर रहे हैं?',
      'mr': 'नमस्कार! आज तुम्हाला कसे वाटत आहे?',
    };

    return right(greetings[language] ?? greetings['en']!);
  }

  Future<Either<AppFailure, String>> sendVoiceMessage(String audioPath, String patientId) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      return left(const AppFailure.unknownFailure('Audio file not found'));
    }

    final formData = FormData.fromMap({
      'patient_id': patientId,
      'audio': await MultipartFile.fromFile(audioPath, filename: 'voice.m4a'),
    });

    final result = await _dio.request<Map<String, dynamic>>(
      (dio) => dio.post('/saathi/talk', data: formData),
    );

    return result.map((data) => data['response'] as String);
  }
}

@Riverpod(keepAlive: true)
SaathiRepository saathiRepository(Ref ref) {
  return SaathiRepository(ref.watch(dioClientProvider));
}
