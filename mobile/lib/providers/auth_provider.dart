import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:mobile/core/utils/exceptions.dart';
import '../models/user_role.dart';

class AuthState {
  final bool isAuthenticated;
  final String? identifier;
  final String? patientId;
  final UserRole? role;
  final bool isLoading;
  final SaathiException? lastError;
  
  const AuthState({
    this.isAuthenticated = false,
    this.identifier,
    this.patientId,
    this.role,
    this.isLoading = false,
    this.lastError,
  });
  
  AuthState copyWith({
    bool? isAuthenticated, 
    String? identifier, 
    String? patientId,
    UserRole? role,
    bool? isLoading, 
    SaathiException? lastError, 
    bool clearError = false
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      identifier: identifier ?? this.identifier,
      patientId: patientId ?? this.patientId,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(const AuthState());
  
  Future<void> initialize() async {
    try {
      final authenticated = await _authService.isAuthenticated().timeout(const Duration(seconds: 2));
      final identifier = await _authService.getIdentifier().timeout(const Duration(seconds: 2));
      final roleStr = await _authService.getRole().timeout(const Duration(seconds: 2));
      final patientId = await _authService.getPatientId().timeout(const Duration(seconds: 2));
      
      UserRole? role;
      if (roleStr != null) {
        role = UserRole.values.firstWhere((r) => r.name == roleStr, orElse: () => UserRole.patient);
      }
      
      state = state.copyWith(
        isAuthenticated: authenticated, 
        identifier: identifier,
        patientId: patientId,
        role: role,
      );
    } catch (e) {
      AppLogger.warn('AuthNotifier: initialization failed: $e');
    }
  }

  Future<void> requestOTP(String identifier, UserRole role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.requestOTP(identifier, role);
      state = state.copyWith(isLoading: false, identifier: identifier, role: role);
    } catch (e) {
      AppLogger.error('AuthNotifier: OTP request failed', e);
      state = state.copyWith(
        isLoading: false,
        lastError: e is SaathiException ? e : UnknownException('Failed to send OTP'),
      );
      rethrow;
    }
  }
  
  Future<void> login(String identifier, String otp, UserRole role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.login(identifier, otp, role);
      final patientId = await _authService.getPatientId();
      
      state = state.copyWith(
        isAuthenticated: true, 
        identifier: identifier, 
        patientId: patientId,
        role: role,
        isLoading: false
      );
    } catch (e) {
      AppLogger.error('AuthNotifier: Login failed', e);
      state = state.copyWith(
        isLoading: false, 
        lastError: e is SaathiException ? e : UnknownException('Invalid OTP'),
      );
      rethrow;
    }
  }
  
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
