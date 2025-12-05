import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../errors/exceptions.dart';

/// Utility class for converting platform errors to AppExceptions
class ErrorHandler {
  /// Convert any error to an AppException
  static AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    // Firebase Auth errors
    if (error is firebase_auth.FirebaseAuthException) {
      return AuthException.fromFirebase(error);
    }

    // Firestore errors
    if (error is firestore.FirebaseException) {
      if (error.code == 'permission-denied') {
        return PermissionException.accessDenied();
      }
      if (error.code == 'not-found') {
        return const NotFoundException(
          message: 'The requested data was not found',
          code: 'not-found',
        );
      }
      if (error.code == 'unavailable') {
        return NetworkException.noConnection();
      }
      return StorageException.fromFirestore(error);
    }

    // Already an AppException
    if (error is AppException) {
      return error;
    }

    // Network errors (basic detection)
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return NetworkException.noConnection();
    }

    // Unknown error
    return UnknownException(originalError: error, stackTrace: stackTrace);
  }

  /// Get user-friendly message from any error
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.userMessage;
    }

    final appException = handleError(error);
    return appException.userMessage;
  }

  /// Check if an error is recoverable (user can retry)
  static bool isRecoverable(AppException exception) {
    return exception is NetworkException ||
        exception is StorageException ||
        exception is UnknownException;
  }

  /// Check if an error requires re-authentication
  static bool requiresAuth(AppException exception) {
    return exception is PermissionException &&
        exception.code == 'not-authenticated';
  }
}
