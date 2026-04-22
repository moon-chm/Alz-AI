import 'package:freezed_annotation/freezed_annotation.dart';

part 'vitals_models.freezed.dart';
part 'vitals_models.g.dart';

@freezed
abstract class VitalsReading with _$VitalsReading {
  const factory VitalsReading({
    @JsonKey(name: 'hr') required int heartRate,
    @JsonKey(name: 'spo2') required int spo2,
    @JsonKey(name: 'steps') required int steps,
    @JsonKey(name: 'sleep', toJson: _minutesToHours, fromJson: _hoursToMinutes) required int sleepMinutes,
    @JsonKey(name: 'hrv') double? hrv,
    @JsonKey(name: 'recorded_at') required DateTime recordedAt,
  }) = _VitalsReading;

  factory VitalsReading.fromJson(Map<String, dynamic> json) => _$VitalsReadingFromJson(json);
}

double _minutesToHours(int mins) => mins / 60.0;
int _hoursToMinutes(dynamic hours) => (hours is num ? (hours * 60).toInt() : 0);
