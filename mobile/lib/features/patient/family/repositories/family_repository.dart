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
    // Mocking the photo feed as requested by the user
    await Future.delayed(const Duration(seconds: 1));
    
    final mockPhotos = [
      FamilyPhoto(
        photoUrl: 'https://res.cloudinary.com/demo/image/upload/v1652345678/sample_family_1.jpg',
        senderName: 'Rohan',
        relationship: 'Son',
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
        narrationText: 'Baba, look at this photo of us from the last picnic. We had so much fun!',
      ),
      FamilyPhoto(
        photoUrl: 'https://res.cloudinary.com/demo/image/upload/v1652345679/sample_family_2.jpg',
        senderName: 'Priya',
        relationship: 'Granddaughter',
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
        narrationText: 'Aazoba, see my new drawing! I made this for you.',
      ),
      FamilyPhoto(
        photoUrl: 'https://res.cloudinary.com/demo/image/upload/v1652345680/sample_family_3.jpg',
        senderName: 'Anjali',
        relationship: 'Daughter-in-law',
        sentAt: DateTime.now().subtract(const Duration(days: 3)),
        narrationText: 'Making your favorite Modaks today, Baba. See you in the evening!',
      ),
    ];

    return right(mockPhotos);
  }

  Future<Either<AppFailure, List<FamilyMember>>> fetchMembers(String patientId) async {
    final result = await _client.request<List<dynamic>>(
      (dio) => dio.get('/family/members', queryParameters: {'patient_id': patientId}),
    );

    return result.map((data) => data.map((json) => FamilyMember.fromJson(json)).toList());
  }

  Future<Either<AppFailure, FamilyIdentifyResponse>> identifyFace(String patientId, File imageFile) async {
    final formData = FormData.fromMap({
      'patient_id': patientId,
      'image': await MultipartFile.fromFile(imageFile.path),
    });

    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.post('/family/identify', data: formData),
    );

    return result.map((data) => FamilyIdentifyResponse.fromJson(data));
  }
}

@riverpod
FamilyRepository familyRepository(Ref ref) {
  return FamilyRepository(ref.watch(dioClientProvider));
}
