/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends ApiException {
  NetworkException() : super('Network error. Please check your internet connection.');
}

/// Authentication exceptions
class UnauthorizedException extends ApiException {
  UnauthorizedException([String? message]) 
      : super(message ?? 'Authentication failed. Please log in again.', 401);
}

/// Server error exceptions
class ServerException extends ApiException {
  ServerException([String? message]) 
      : super(message ?? 'Server error. Please try again later.', 500);
}

/// Not found exceptions
class NotFoundException extends ApiException {
  NotFoundException([String? message]) 
      : super(message ?? 'Resource not found.', 404);
}

