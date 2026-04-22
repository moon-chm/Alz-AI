import 'package:alz_ai/features/auth/controllers/login_state.dart';
import 'package:alz_ai/features/auth/providers/auth_state.dart';
import 'package:alz_ai/features/auth/auth_repository.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alz_ai/core/services/background_service.dart';
import 'package:alz_ai/core/services/vitals_service.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState.idling();

  Future<void> requestOtp(String identifier, String role) async {
    state = const LoginState.requestingOtp();
    
    final result = await ref.read(authRepositoryProvider).requestOtp(
      identifier: identifier,
      role: role,
    );

    result.fold(
      (failure) => state = LoginState.failure(failure.message),
      (_) => state = const LoginState.otpSent(),
    );
  }

  Future<void> verifyOtp(String identifier, String otp, String role) async {
    state = const LoginState.verifyingOtp();
    
    final result = await ref.read(authRepositoryProvider).verifyOtp(
      identifier: identifier,
      otp: otp,
      role: role,
    );

    result.fold(
      (failure) => state = LoginState.failure(failure.message),
      (authResponse) async {
        // Ensure all storage writes are flushed before proceeding
        // Note: Repository already awaits, but we add a safety sync read if needed
        final savedId = await ref.read(storageServiceProvider).getPatientId();
        
        state = const LoginState.success();
        
        // Sequential Permission Handshake
        // 1. Notification
        await Permission.notification.request();
        
        // 2. Location (Foreground then Background as required by Android 11+)
        final locStatus = await Permission.location.request();
        bool hasLoc = locStatus.isGranted;
        if (hasLoc) {
          final backgroundStatus = await Permission.locationAlways.request();
          hasLoc = backgroundStatus.isGranted;
        }

        // 3. Health
        final vitalsService = VitalsService();
        bool hasHealth = false;
        if (await vitalsService.checkAvailability()) {
          hasHealth = await vitalsService.requestPermissions();
        }

        // Initialize background services with REAL permission status
        await BackgroundServiceInstance.initialize(
          hasHealthPermissions: hasHealth,
          hasLocationPermissions: hasLoc,
        );

        // Update the global auth state only AFTER persistence is confirmed
        ref.read(authStateProvider.notifier).setAuthenticated(
          role: authResponse.role,
          level: null,
        );
      },
    );
  }

  void reset() {
    state = const LoginState.idling();
  }
}
