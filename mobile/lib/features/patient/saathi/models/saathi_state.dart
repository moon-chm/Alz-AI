import 'package:freezed_annotation/freezed_annotation.dart';

part 'saathi_state.freezed.dart';

@freezed
class SaathiState with _$SaathiState {
  const factory SaathiState.idle({required String displayMessage}) = _Idle;
  const factory SaathiState.recording() = _Recording;
  const factory SaathiState.uploading() = _Uploading;
  const factory SaathiState.speaking({required String response}) = _Speaking;
  const factory SaathiState.error({required String fallbackMessage}) = _Error;
}
