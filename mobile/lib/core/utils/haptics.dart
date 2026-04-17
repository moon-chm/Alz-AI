import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

// Every interaction has appropriate haptic feedback
class AppHaptics {
  // Light tap — navigation, card press
  static light() => HapticFeedback.lightImpact();

  // Medium — button press, toggle
  static medium() => HapticFeedback.mediumImpact();

  // Heavy — medication confirm, important action
  static heavy() => HapticFeedback.heavyImpact();

  // SOS hold — continuous vibration pattern
  static sosHold() => Vibration.vibrate(
        pattern: [0, 200, 100, 200, 100, 200],
        repeat: 0, // repeat indefinitely until cancelled
      );

  static cancel() => Vibration.cancel();

  // Success — medication taken, face recognized
  static success() => Vibration.vibrate(
        pattern: [0, 100, 50, 100],
      );
}
