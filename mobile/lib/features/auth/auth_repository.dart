import 'package:alz_ai/core/error/app_failure.dart';
import 'package:alz_ai/core/network/dio_client.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/shared/models/auth_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final DioClient _client;
  final StorageService _storage;

  AuthRepository(this._client, this._storage);

  Future<Either<AppFailure, Unit>> requestOtp({
    required String identifier,
    required String role,
  }) async {
    final result = await _client.request(
      (dio) => dio.post('auth/request-otp', data: {
        'identifier': identifier,
        'role': role,
      }),
    );
    
    return result.map((_) => unit);
  }

  Future<Either<AppFailure, AuthTokenResponse>> verifyOtp({
    required String identifier,
    required String otp,
    required String role,
  }) async {
    final result = await _client.request<Map<String, dynamic>>(
      (dio) => dio.post('auth/login/otp', data: {
        'identifier': identifier,
        'otp': otp,
        'role': role,
      }),
    );

    return result.match(
      (failure) => left(failure),
      (data) async {
        try {
          final authData = AuthTokenResponse.fromJson(data['data']);
          
          await _storage.saveTokens(
            accessToken: authData.accessToken,
            refreshToken: authData.refreshToken,
          );
          
          await _storage.saveAuthData(
            userId: authData.userId,
            role: authData.role,
            patientId: authData.patientId,
          );
          
          return right(authData);
        } catch (e) {
          return left(AppFailure.unknownFailure('Failed to parse auth response: $e'));
        }
      },
    );
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(storageServiceProvider),
  );
}
