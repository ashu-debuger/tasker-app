import '../../domain/models/app_user.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Stream of current authenticated user
  /// Emits null when user is not authenticated
  Stream<AppUser?> get authStateChanges;

  /// Get currently authenticated user
  /// Returns null if no user is authenticated
  AppUser? get currentUser;

  /// Sign in with email and password
  /// Returns the authenticated user
  /// Throws [AuthException] on failure
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  /// Creates a new user account and signs in
  /// Returns the newly created user
  /// Throws [AuthException] on failure
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out the current user
  /// Throws [AuthException] on failure
  Future<void> signOut();

  /// Reset password for the given email
  /// Sends a password reset email
  /// Throws [AuthException] on failure
  Future<void> resetPassword({required String email});

  /// Update user profile information
  /// Throws [AuthException] on failure
  Future<void> updateProfile({String? displayName, String? photoUrl});

  /// Delete current user account
  /// Throws [AuthException] on failure
  Future<void> deleteAccount();
}
