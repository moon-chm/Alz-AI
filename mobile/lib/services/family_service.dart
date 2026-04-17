import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import 'api_service.dart';
import 'package:mobile/models/family_member.dart';

class FamilyService {
  final ApiService _api;
  
  FamilyService(this._api);
  
  Future<List<FamilyMember>> getFamilyMembers(String patientId) async {
    try {
      final response = await _api.get('/patient/family', params: {'patient_id': patientId});
      final List<dynamic> data = response.data;
      return data.map((f) => FamilyMember.fromJson(f)).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<FamilyMember?> recognizeFace(File imageFile, String patientId) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: 'face.jpg'),
        'patient_id': patientId,
      });
      final response = await _api.uploadFile('/media/face/recognize', formData, timeoutSeconds: 15);
      if (response.data['matched'] == true) {
        // Build mock returned info based on expected match structure
        return FamilyMember(
           id: "temp_id",
           name: response.data['family_member'] ?? 'Family',
           relationship: "Recognized",
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final familyServiceProvider = Provider((ref) {
  final api = ref.watch(apiServiceProvider);
  return FamilyService(api);
});
