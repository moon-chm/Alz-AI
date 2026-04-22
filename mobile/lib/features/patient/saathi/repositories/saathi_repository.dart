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
    final result = await _dio.request<Map<String, dynamic>>(
      (dio) => dio.get('saathi/greeting', queryParameters: {
        'patient_id': patientId,
      }),
    );

    return result.map((data) => data['greeting'] as String);
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
      (dio) => dio.post('saathi/talk', data: formData),
    );

    return result.map((data) => data['response'] as String);
  }
}

@Riverpod(keepAlive: true)
SaathiRepository saathiRepository(Ref ref) {
  return SaathiRepository(ref.watch(dioClientProvider));
}
