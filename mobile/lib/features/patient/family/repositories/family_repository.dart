import 'package:fpdart/fpdart.dart';
import 'package:alz_ai/core/error/app_failure.dart';
import 'package:alz_ai/core/network/dio_client.dart';
import 'package:alz_ai/features/patient/family/models/family_photo.dart';
import 'package:alz_ai/features/patient/family/models/family_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import 'package:dio/dio.dart';

part 'family_repository.g.dart';

class FamilyRepository {
  final DioClient _client;

  FamilyRepository(this._client);

  Future<Either<AppFailure, List<FamilyPhoto>>> fetchPhotos(String patientId) async {
    final result = await _client.request<List<dynamic>>(
      (dio) => dio.get('caretaker/photos', queryParameters: {'patient_id': patientId}),
    );

    return result.map((data) {
      return data.map((json) {
        // Map backend keys to model keys
        final mappedJson = {
          'photoUrl': json['cloudinary_url'],
          'senderName': json['sender_name'],
          'relationship': json['relationship'] ?? 'Family Member',
          'sentAt': json['sent_at'],
          'narrationText': json['caption'],
        };
        return FamilyPhoto.fromJson(mappedJson);
      }).toList();
    });
  }

  Future<Either<AppFailure, List<FamilyMember>>> fetchMembers(String patientId) async {
    final result = await _client.request<List<dynamic>>(
      (dio) => dio.get('family/members', queryParameters: {'patient_id': patientId}),
    );

    return result.map((data) => data.map((json) => FamilyMember.fromJson(json)).toList());
  }

  Future<Either<AppFailure, FamilyIdentifyResponse>> identifyFace(String patientId, File imageFile) async {
    final formData = FormData.fromMap({
      'patient_id': patientId,
      'image': await MultipartFile.fromFile(imageFile.path),
    });

    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.post('family/identify', data: formData),
    );

    return result.map((data) => FamilyIdentifyResponse.fromJson(data));
  }
}

@riverpod
FamilyRepository familyRepository(Ref ref) {
  return FamilyRepository(ref.watch(dioClientProvider));
}
