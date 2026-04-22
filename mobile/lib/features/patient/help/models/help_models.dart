import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:alz_ai/core/error/app_failure.dart';

part 'help_models.freezed.dart';
part 'help_models.g.dart';

@freezed
abstract class ContactItem with _$ContactItem {
  const factory ContactItem({
    required String id,
    required String name,
    required String relationship,
    required String phone,
    @Default(false) @JsonKey(name: 'is_primary') bool isPrimary,
  }) = _ContactItem;

  factory ContactItem.fromJson(Map<String, dynamic> json) => _$ContactItemFromJson(json);
}

@freezed
sealed class HelpState with _$HelpState {
  const factory HelpState.loading() = HelpStateLoading;
  const factory HelpState.loaded({
    required List<ContactItem> contacts,
  }) = HelpStateLoaded;
  const factory HelpState.error({
    required AppFailure failure,
  }) = HelpStateError;
}
