import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

@freezed
abstract class AuthTokenResponse with _$AuthTokenResponse {
  const factory AuthTokenResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'user_id') required String userId,
    required String role,
    @JsonKey(name: 'patient_id') String? patientId,
  }) = _AuthTokenResponse;

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) => 
      _$AuthTokenResponseFromJson(json);
}

@freezed
abstract class PatientResponse with _$PatientResponse {
  const factory PatientResponse({
    required String id,
    @JsonKey(name: 'patient_unique_id') required String patientUniqueId,
    @JsonKey(name: 'full_name') required String fullName,
    required String language,
    required int level,
  }) = _PatientResponse;

  factory PatientResponse.fromJson(Map<String, dynamic> json) => 
      _$PatientResponseFromJson(json);
}
