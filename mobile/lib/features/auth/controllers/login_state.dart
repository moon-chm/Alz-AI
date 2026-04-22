import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const factory LoginState.idling() = _Idling;
  const factory LoginState.requestingOtp() = _RequestingOtp;
  const factory LoginState.otpSent() = _OtpSent;
  const factory LoginState.verifyingOtp() = _VerifyingOtp;
  const factory LoginState.success() = _Success;
  const factory LoginState.failure(String message) = _Failure;
}
