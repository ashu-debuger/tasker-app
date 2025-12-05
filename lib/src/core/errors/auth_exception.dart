/// Base exception class for authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when email is invalid
class InvalidEmailException extends AuthException {
  const InvalidEmailException()
    : super('The email address is invalid', code: 'invalid-email');
}

/// Exception thrown when password is too weak
class WeakPasswordException extends AuthException {
  const WeakPasswordException()
    : super('The password is too weak', code: 'weak-password');
}

/// Exception thrown when email is already in use
class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
    : super(
        'An account already exists with this email',
        code: 'email-already-in-use',
      );
}

/// Exception thrown when user is not found
class UserNotFoundException extends AuthException {
  const UserNotFoundException()
    : super('No user found with this email', code: 'user-not-found');
}

/// Exception thrown when password is wrong
class WrongPasswordException extends AuthException {
  const WrongPasswordException()
    : super('Incorrect password', code: 'wrong-password');
}

/// Exception thrown when user is disabled
class UserDisabledException extends AuthException {
  const UserDisabledException()
    : super('This account has been disabled', code: 'user-disabled');
}

/// Exception thrown when too many requests are made
class TooManyRequestsException extends AuthException {
  const TooManyRequestsException()
    : super(
        'Too many requests. Please try again later',
        code: 'too-many-requests',
      );
}

/// Exception thrown when network error occurs
class NetworkException extends AuthException {
  const NetworkException()
    : super(
        'Network error. Please check your connection',
        code: 'network-error',
      );
}
