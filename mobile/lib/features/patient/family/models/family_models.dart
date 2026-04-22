import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:alz_ai/core/error/app_failure.dart';

part 'family_models.freezed.dart';
part 'family_models.g.dart';

@freezed
abstract class FamilyMember with _$FamilyMember {
  const factory FamilyMember({
    required String id,
    required String name,
    required String relationship,
    @JsonKey(name: 'photo_url') required String photoUrl,
    @Default(0) @JsonKey(name: 'collection_count') int collectionCount,
  }) = _FamilyMember;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => _$FamilyMemberFromJson(json);
}

@freezed
abstract class FamilyIdentifyResponse with _$FamilyIdentifyResponse {
  const factory FamilyIdentifyResponse({
    required bool matched,
    String? name,
    String? relationship,
    String? description,
    @JsonKey(name: 'member_id') String? memberId,
  }) = _FamilyIdentifyResponse;

  factory FamilyIdentifyResponse.fromJson(Map<String, dynamic> json) => _$FamilyIdentifyResponseFromJson(json);
}

@freezed
sealed class FamilyState with _$FamilyState {
  const factory FamilyState.loading() = FamilyStateLoading;
  const factory FamilyState.loaded({
    required List<FamilyMember> members,
    FamilyIdentifyResponse? identificationResult,
  }) = FamilyStateLoaded;
  const factory FamilyState.error({
    required AppFailure failure,
  }) = FamilyStateError;
}
