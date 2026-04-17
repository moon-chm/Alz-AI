sealed class SaathiException implements Exception {
  final String message;
  SaathiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends SaathiException {
  NetworkException([String message = 'Connection lost. Please check your internet.']) : super(message);
}

class AuthException extends SaathiException {
  AuthException([String message = 'Session expired. Please log in again.']) : super(message);
}

class TimeoutException extends SaathiException {
  TimeoutException([String message = 'AI response delayed. Still thinking...']) : super(message);
}

class ServerException extends SaathiException {
  ServerException([String message = 'Server error. Please try again later.']) : super(message);
}

class UnknownException extends SaathiException {
  UnknownException([String message = 'Something went wrong.']) : super(message);
}
