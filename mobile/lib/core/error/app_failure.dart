import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

@freezed
class AppFailure with _$AppFailure {
  const AppFailure._();

  const factory AppFailure.networkFailure() = NetworkFailure;
  
  const factory AppFailure.serverFailure({
    required int? statusCode,
    required String message,
  }) = ServerFailure;
  
  const factory AppFailure.authFailure() = AuthFailure;
  
  const factory AppFailure.timeoutFailure() = TimeoutFailure;
  
  const factory AppFailure.unknownFailure([String? msg]) = UnknownFailure;

  String get message => when(
        networkFailure: () => 'Network connection error',
        serverFailure: (_, msg) => msg,
        authFailure: () => 'Authentication failed',
        timeoutFailure: () => 'Connection timed out',
        unknownFailure: (msg) => msg ?? 'An unknown error occurred',
      );
}
