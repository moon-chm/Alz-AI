import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'safety_provider.g.dart';

class SafetyState {
  final bool isOutsideSafeZone;
  final bool isInDangerZone;
  final String? lastBehaviorMessage;
  final String? homeStatus;

  SafetyState({
    this.isOutsideSafeZone = false,
    this.isInDangerZone = false,
    this.lastBehaviorMessage,
    this.homeStatus,
  });

  SafetyState copyWith({
    bool? isOutsideSafeZone,
    bool? isInDangerZone,
    String? lastBehaviorMessage,
    String? homeStatus,
  }) {
    return SafetyState(
      isOutsideSafeZone: isOutsideSafeZone ?? this.isOutsideSafeZone,
      isInDangerZone: isInDangerZone ?? this.isInDangerZone,
      lastBehaviorMessage: lastBehaviorMessage ?? this.lastBehaviorMessage,
      homeStatus: homeStatus ?? this.homeStatus,
    );
  }
}

@riverpod
class Safety extends _$Safety {
  @override
  SafetyState build() => SafetyState();

  void setGeofenceStatus({required bool isOutside, required bool isDanger}) {
    state = state.copyWith(
      isOutsideSafeZone: isOutside,
      isInDangerZone: isDanger,
    );
  }

  void setBehaviorMessage(String? message) {
    state = state.copyWith(lastBehaviorMessage: message);
  }

  void updateHomeStatus(String? status) {
    state = state.copyWith(homeStatus: status);
  }
}
