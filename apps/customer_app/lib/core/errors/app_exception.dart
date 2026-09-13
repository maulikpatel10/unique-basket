class AppException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  const AppException({
    required this.message,
    this.errorCode,
    this.statusCode,
  });

  @override
  String toString() => 'AppException(message: $message, errorCode: $errorCode, statusCode: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Unable to connect to the server. Please check your internet connection.',
  }) : super(errorCode: 'NETWORK_ERROR');
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out. Please try again.',
  }) : super(errorCode: 'TIMEOUT_ERROR');
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Session expired. Please log in again.',
  }) : super(errorCode: 'UNAUTHORIZED', statusCode: 401);
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Something went wrong on the server. Please try again later.',
    int? statusCode,
  }) : super(errorCode: 'SERVER_ERROR', statusCode: statusCode ?? 500);
}

class BusinessException extends AppException {
  const BusinessException({
    required super.message,
    super.errorCode,
    super.statusCode,
  });
}
