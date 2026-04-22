import 'package:freezed_annotation/freezed_annotation.dart';

part 'background_models.freezed.dart';
part 'background_models.g.dart';

@freezed
sealed class BackgroundEvent with _$BackgroundEvent {
  const factory BackgroundEvent.geofenceBreached({
    required double latitude,
    required double longitude,
    required String timestamp,
  }) = GeofenceBreached;

  const factory BackgroundEvent.geofenceRestored({
    required String timestamp,
  }) = GeofenceRestored;

  const factory BackgroundEvent.fallDetected({
    required String timestamp,
  }) = FallDetected;

  const factory BackgroundEvent.behaviorDeviation({
    required String message,
    required String timestamp,
  }) = BehaviorDeviation;

  const factory BackgroundEvent.connectivityRestored() = ConnectivityRestored;

  factory BackgroundEvent.fromJson(Map<String, dynamic> json) => 
      _$BackgroundEventFromJson(json);
}
