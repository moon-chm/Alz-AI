import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:alz_ai/core/error/app_failure.dart';

part 'medicine_models.freezed.dart';
part 'medicine_models.g.dart';

@freezed
abstract class MedicationItem with _$MedicationItem {
  const factory MedicationItem({
    required String id,
    required String name,
    @JsonKey(name: 'photo_url') required String photoUrl,
    required String time,
    @JsonKey(name: 'dose_instructions') required String doseInstructions,
    @Default('upcoming') String status,
  }) = _MedicationItem;

  factory MedicationItem.fromJson(Map<String, dynamic> json) => _$MedicationItemFromJson(json);
}

@freezed
sealed class MedicinesState with _$MedicinesState {
  const factory MedicinesState.loading() = MedicinesStateLoading;
  const factory MedicinesState.loaded({
    required List<MedicationItem> medications,
  }) = MedicinesStateLoaded;
  const factory MedicinesState.alertActive({
    required MedicationItem medication,
    @Default(false) bool isConfirmVisible,
    @Default(false) bool secondReminderSent,
  }) = MedicinesStateAlertActive;
  const factory MedicinesState.error({
    required AppFailure failure,
  }) = MedicinesStateError;
}
