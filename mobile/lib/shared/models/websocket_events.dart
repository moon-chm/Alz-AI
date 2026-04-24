import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_events.freezed.dart';
part 'websocket_events.g.dart';

@Freezed(unionKey: 'event_type', fallbackUnion: 'unknown')
abstract class WebSocketEvent with _$WebSocketEvent {
  @FreezedUnionValue('mood_updated')
  const factory WebSocketEvent.moodUpdated({
    @JsonKey(name: 'patient_id') required String patientId,
    required String mood,
    required String timestamp,
  }) = MoodUpdated;

  @FreezedUnionValue('vitals_updated')
  const factory WebSocketEvent.vitalsUpdated({
    @JsonKey(name: 'patient_id') required String patientId,
    required Map<String, dynamic> vitals,
    required String timestamp,
  }) = VitalsUpdated;

  @FreezedUnionValue('location_updated')
  const factory WebSocketEvent.locationUpdated({
    @JsonKey(name: 'patient_id') required String patientId,
    required double latitude,
    required double longitude,
    required String timestamp,
  }) = LocationUpdated;

  @FreezedUnionValue('medication_cleared')
  const factory WebSocketEvent.medicationCleared({
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'medication_id') required String medicationId,
    required String timestamp,
  }) = MedicationCleared;

  @FreezedUnionValue('alert_created')
  const factory WebSocketEvent.alertCreated({
    @JsonKey(name: 'patient_id') required String patientId,
    required String severity,
    required String title,
    required String message,
  }) = AlertCreated;

  const factory WebSocketEvent.unknown() = UnknownEvent;

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) => 
      _$WebSocketEventFromJson(json);
}
