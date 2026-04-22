/// Thrown by data-layer code; caught and converted to Failures in repositories.

class ServerException implements Exception {
  final String message;
  final int?    statusCode;
  const ServerException(this.message, {this.statusCode});
  @override String toString() => 'ServerException($statusCode): $message';
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override String toString() => 'AuthException: $message';
}

class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;
}