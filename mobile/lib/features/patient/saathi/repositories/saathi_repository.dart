import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:alz_ai/core/error/app_failure.dart';
import 'package:alz_ai/core/network/dio_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saathi_repository.g.dart';

class SaathiGreeting {
  final String text;
  final String? voiceSampleUrl;

  SaathiGreeting({required this.text, this.voiceSampleUrl});

  factory SaathiGreeting.fromJson(Map<String, dynamic> json) {
    return SaathiGreeting(
      text: json['greeting'] as String? ?? json['response'] as String? ?? 'Hello!',
      voiceSampleUrl: json['voice_sample_url'] as String?,
    );
  }
}

class SaathiRepository {
  final DioClient _dio;

  SaathiRepository(this._dio);

  Future<Either<AppFailure, SaathiGreeting>> fetchGreeting(String patientId, String language) async {
    final result = await _dio.request<Map<String, dynamic>>(
      (dio) => dio.get('saathi/greeting', queryParameters: {
        'patient_id': patientId,
      }),
    );

    return result.map((data) => SaathiGreeting.fromJson(data));
  }

  Future<Either<AppFailure, Map<String, dynamic>>> sendVoiceMessage(String audioPath, String patientId) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      return left(const AppFailure.unknownFailure('Audio file not found'));
    }

    final formData = FormData.fromMap({
      'patient_id': patientId,
      'audio': await MultipartFile.fromFile(audioPath, filename: 'voice.m4a'),
    });

    final result = await _dio.request<Map<String, dynamic>>(
      (dio) => dio.post('saathi/talk', data: formData),
    );

    return result;
  }
}

@Riverpod(keepAlive: true)
SaathiRepository saathiRepository(Ref ref) {
  return SaathiRepository(ref.watch(dioClientProvider));
}
