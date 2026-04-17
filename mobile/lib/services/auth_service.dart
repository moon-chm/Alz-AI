import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../providers/core_providers.dart';
import '../models/user_role.dart';
import 'dart:convert';
import 'package:mobile/core/utils/logger.dart';

class AuthService {
  final FlutterSecureStorage _storage;
  final ApiService _api;
  
  AuthService(this._api, this._storage);
  
  /// Requests a 6-digit OTP for the given identifier and role.
  /// Endpoint: POST /auth/request-otp
  Future<void> requestOTP(String identifier, UserRole role) async {
    await _api.post('auth/request-otp', data: {
      'role': role.name,
      'identifier': identifier,
    });
    AppLogger.info('AuthService: OTP requested for ${role.name}: $identifier');
  }

  /// Verifies the OTP and logs the user in.
  /// Endpoint: POST /auth/login/otp
  Future<Map<String, dynamic>> login(String identifier, String otp, UserRole role) async {
    final response = await _api.post('auth/login/otp', data: {
      'role': role.name,
      'identifier': identifier,
      'otp': otp,
    });
    
    final token = response.data['access_token'];
    final patientId = response.data['patient_id'];
    final isMock = response.data['is_mock'] == true;
    
    if (patientId == null || patientId.isEmpty) {
      throw Exception('Patient ID missing from backend response');
    }
    
    if (isMock) {
      AppLogger.warn('AuthService: LOGGING IN USING FALLBACK DEV MOCK');
    }
    
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_identifier', value: identifier);
    await _storage.write(key: 'user_role', value: role.name);
    await _storage.write(key: 'patient_id', value: patientId);
    
    AppLogger.info('AuthService: Login success for ${role.name}: $identifier (patient_id: $patientId)');
    return response.data;
  }
  
  Future<void> logout() async {
    await _storage.deleteAll();
    AppLogger.info('AuthService: User logged out');
  }
  
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return false;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );
      final exp = payload['exp'] as int;
      return exp > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (e) {
      return false;
    }
  }
  
  Future<String?> getIdentifier() async {
    return _storage.read(key: 'user_identifier');
  }

  Future<String?> getRole() async {
    return _storage.read(key: 'user_role');
  }

  Future<String?> getPatientId() async {
    return _storage.read(key: 'patient_id');
  }
}

// Riverpod Provider
final authServiceProvider = Provider((ref) {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageProvider);
  return AuthService(api, storage);
});
