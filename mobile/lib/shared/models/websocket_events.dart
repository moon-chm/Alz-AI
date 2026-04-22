import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_events.freezed.dart';
part 'websocket_events.g.dart';

@Freezed(unionKey: 'event_type')
abstract class WebSocketEvent with _$WebSocketEvent {
  const factory WebSocketEvent.moodUpdated({
    @JsonKey(name: 'patient_id') required String patientId,
    required String mood,
    required String timestamp,
  }) = MoodUpdated;

  const factory WebSocketEvent.vitalsUpdated({
    @JsonKey(name: 'patient_id') required String patientId,
    required Map<String, dynamic> vitals,
    required String timestamp,
  }) = VitalsUpdated;

  const factory WebSocketEvent.locationUpdated({
    @JsonKey(name: 'patient_id') required String patientId,
    required double latitude,
    required double longitude,
    required String timestamp,
  }) = LocationUpdated;

  const factory WebSocketEvent.medicationCleared({
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'medication_id') required String medicationId,
    required String timestamp,
  }) = MedicationCleared;

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) => 
      _$WebSocketEventFromJson(json);
}
