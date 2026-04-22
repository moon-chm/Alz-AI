import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.unknown() = _Unknown;
  const factory AuthState.authenticated({
    required String role,
    int? level,
  }) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
}

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  FutureOr<AuthState> build() async {
    final storage = ref.read(storageServiceProvider);
    final token = await storage.getAccessToken();
    
    if (token == null) {
      return const AuthState.unauthenticated();
    }
    
    final role = await storage.getRole();
    final level = await storage.getLevel();
    
    if (role == null) {
      return const AuthState.unauthenticated();
    }
    
    return AuthState.authenticated(role: role, level: level);
  }

  void logout() {
    // 1. Stop background services immediately
    FlutterBackgroundService().invoke('stopService');
    
    // 2. Clear secure storage
    ref.read(storageServiceProvider).clearAll();
    
    // 3. Update state
    state = const AsyncData(AuthState.unauthenticated());
  }

  void setAuthenticated({required String role, int? level}) {
    state = AsyncData(AuthState.authenticated(role: role, level: level));
  }
}
