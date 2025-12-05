/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Get a user-friendly error message
  String get userMessage => message;

  @override
  String toString() {
    if (code != null) {
      return 'AppException [$code]: $message';
    }
    return 'AppException: $message';
  }
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.fromFirebase(dynamic error) {
    final errorCode = _extractErrorCode(error);
    final message = _getAuthErrorMessage(errorCode);

    return AuthException(
      message: message,
      code: errorCode,
      originalError: error,
    );
  }

  static String _extractErrorCode(dynamic error) {
    if (error == null) return 'unknown';

    final errorString = error.toString();
    if (errorString.contains('[')) {
      final start = errorString.indexOf('[') + 1;
      final end = errorString.indexOf(']');
      if (end > start) {
        return errorString.substring(start, end);
      }
    }
    return 'unknown';
  }

  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.noConnection() {
    return const NetworkException(
      message: 'No internet connection. Please check your network settings.',
      code: 'no-connection',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(
      message: 'Request timed out. Please try again.',
      code: 'timeout',
    );
  }

  factory NetworkException.serverError() {
    return const NetworkException(
      message: 'Server error. Please try again later.',
      code: 'server-error',
    );
  }
}

/// Data validation exceptions
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.invalidInput(String field) {
    return ValidationException(
      message: 'Invalid value for $field',
      code: 'invalid-input',
    );
  }

  factory ValidationException.requiredField(String field) {
    return ValidationException(
      message: '$field is required',
      code: 'required-field',
    );
  }
}

/// Permission/authorization exceptions
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory PermissionException.accessDenied() {
    return const PermissionException(
      message: 'You do not have permission to perform this action.',
      code: 'access-denied',
    );
  }

  factory PermissionException.notAuthenticated() {
    return const PermissionException(
      message: 'Please sign in to continue.',
      code: 'not-authenticated',
    );
  }
}

/// Not found exceptions
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NotFoundException.resource(String resourceType) {
    return NotFoundException(
      message: '$resourceType not found',
      code: 'not-found',
    );
  }
}

/// Generic server/storage exceptions
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory StorageException.fromFirestore(dynamic error) {
    return StorageException(
      message: 'Database error: ${error.toString()}',
      code: 'firestore-error',
      originalError: error,
    );
  }
}

/// Unknown/unexpected exceptions
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'unknown',
    super.originalError,
    super.stackTrace,
  });
}
