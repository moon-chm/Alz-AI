import 'package:alz_ai/features/auth/controllers/login_state.dart';
import 'package:alz_ai/features/auth/providers/auth_state.dart';
import 'package:alz_ai/features/auth/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alz_ai/core/services/background_service.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState.idling();

  Future<void> requestOtp(String phone, String role) async {
    state = const LoginState.requestingOtp();
    
    final result = await ref.read(authRepositoryProvider).requestOtp(
      phone: phone,
      role: role,
    );

    result.fold(
      (failure) => state = LoginState.failure(failure.message),
      (_) => state = const LoginState.otpSent(),
    );
  }

  Future<void> verifyOtp(String phone, String otp, String role) async {
    state = const LoginState.verifyingOtp();
    
    final result = await ref.read(authRepositoryProvider).verifyOtp(
      phone: phone,
      otp: otp,
      role: role,
    );

    result.fold(
      (failure) => state = LoginState.failure(failure.message),
      (authResponse) {
        state = const LoginState.success();
        
        // Request Notification Permission (Controlled moment post-OTP)
        // We do not block navigation if denied, but we call it here to trigger the system dialog
        Permission.notification.request().then((_) {
           // Initialize background services after permission choice
           BackgroundServiceInstance.initialize();
        });

        // Update the global auth state
        ref.read(authStateProvider.notifier).setAuthenticated(
          role: authResponse.role,
          level: null, // Level can be updated after fetching detailed profile
        );
      },
    );
  }

  void reset() {
    state = const LoginState.idling();
  }
}
