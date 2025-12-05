import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/app_user.dart';
import '../../../../core/errors/auth_exception.dart';
import '../../../../core/utils/app_logger.dart';
import 'auth_repository.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  static const _logTag = '[AuthRepository]';

  FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      appLogger.d(
        '$_logTag authStateChanged userId=${firebaseUser?.uid ?? 'null'}',
      );
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToAppUser(firebaseUser);
    });
  }

  @override
  AppUser? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUserToAppUserSync(firebaseUser);
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final maskedEmail = maskEmail(email);
    appLogger.i('$_logTag Sign in attempt for $maskedEmail');
    try {
      final credential = await logTimedAsync(
        '$_logTag Firebase signIn for $maskedEmail',
        () => _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

      if (credential.user == null) {
        appLogger.e('$_logTag Sign in failed - no user returned');
        throw const AuthException('Sign in failed - no user returned');
      }

      appLogger.i(
        '$_logTag Sign in success userId=${credential.user!.uid}',
      );
      return _mapFirebaseUserToAppUser(credential.user!);
    } on FirebaseAuthException catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Sign in Firebase exception for $maskedEmail code=${e.code}',
        error: e,
        stackTrace: stackTrace,
      );
      throw _handleFirebaseAuthException(e);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Sign in unexpected error for $maskedEmail',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final maskedEmail = maskEmail(email);
    appLogger.i(
      '$_logTag Sign up attempt for $maskedEmail displayName=${displayName?.trim() ?? ''}',
    );
    try {
      final credential = await logTimedAsync(
        '$_logTag Firebase signUp for $maskedEmail',
        () => _firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

      if (credential.user == null) {
        appLogger.e('$_logTag Sign up failed - no user returned');
        throw const AuthException('Sign up failed - no user returned');
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName.trim());
        await credential.user!.reload();
      }

      final user = _firebaseAuth.currentUser!;
      final appUser = _mapFirebaseUserToAppUserSync(user);

      // Create user document in Firestore
      await _createUserDocument(appUser);

      appLogger.i(
        '$_logTag Sign up success userId=${appUser.id}',
      );

      return appUser;
    } on FirebaseAuthException catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Sign up Firebase exception for $maskedEmail code=${e.code}',
        error: e,
        stackTrace: stackTrace,
      );
      throw _handleFirebaseAuthException(e);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Sign up unexpected error for $maskedEmail',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    appLogger.i('$_logTag Sign out requested');
    try {
      await logTimedAsync(
        '$_logTag Firebase signOut',
        () => _firebaseAuth.signOut(),
      );
      appLogger.i('$_logTag Sign out success');
    } on FirebaseAuthException catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Sign out Firebase exception code=${e.code}',
        error: e,
        stackTrace: stackTrace,
      );
      throw _handleFirebaseAuthException(e);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Sign out unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    final maskedEmail = maskEmail(email);
    appLogger.i('$_logTag Password reset requested for $maskedEmail');
    try {
      await logTimedAsync(
        '$_logTag Firebase sendPasswordResetEmail for $maskedEmail',
        () => _firebaseAuth.sendPasswordResetEmail(email: email.trim()),
      );
      appLogger.i('$_logTag Password reset email sent to $maskedEmail');
    } on FirebaseAuthException catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Password reset Firebase exception for $maskedEmail code=${e.code}',
        error: e,
        stackTrace: stackTrace,
      );
      throw _handleFirebaseAuthException(e);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Password reset unexpected error for $maskedEmail',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user is currently signed in');
      }

      appLogger.i(
        '$_logTag Update profile for userId=${user.uid} displayNameChanged=${displayName != null} photoChanged=${photoUrl != null}',
      );

      if (displayName != null) {
        await user.updateDisplayName(displayName.trim());
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl.trim());
      }

      await user.reload();

      // Update Firestore document
      final appUser = _mapFirebaseUserToAppUserSync(_firebaseAuth.currentUser!);
      await _updateUserDocument(appUser);
      appLogger.i('$_logTag Profile update success for userId=${user.uid}');
    } on FirebaseAuthException catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Profile update Firebase exception userId=${_firebaseAuth.currentUser?.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      throw _handleFirebaseAuthException(e);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Profile update unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException('Profile update failed: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user is currently signed in');
      }

      appLogger.w('$_logTag Delete account requested for userId=${user.uid}');

      // Delete user document from Firestore
      await logTimedAsync(
        '$_logTag Firestore delete user doc ${user.uid}',
        () => _firestore.collection('users').doc(user.uid).delete(),
      );

      // Delete Firebase Auth account
      await logTimedAsync(
        '$_logTag Firebase delete user ${user.uid}',
        () => user.delete(),
      );
      appLogger.i('$_logTag Account deletion success for userId=${user.uid}');
    } on FirebaseAuthException catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Account deletion Firebase exception code=${e.code}',
        error: e,
        stackTrace: stackTrace,
      );
      throw _handleFirebaseAuthException(e);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Account deletion unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException('Account deletion failed: ${e.toString()}');
    }
  }

  /// Maps Firebase User to AppUser (async - fetches from Firestore if needed)
  Future<AppUser> _mapFirebaseUserToAppUser(User firebaseUser) async {
    try {
      // Try to get user data from Firestore first
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        appLogger.d(
          '$_logTag Loaded user profile from Firestore userId=${firebaseUser.uid}',
        );
        return AppUser.fromFirestore(userDoc.data()!);
      }

      appLogger.w(
        '$_logTag User profile missing in Firestore, falling back to auth userId=${firebaseUser.uid}',
      );
      // If not in Firestore, create from Firebase User
      return _mapFirebaseUserToAppUserSync(firebaseUser);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Failed to load user profile from Firestore userId=${firebaseUser.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to sync mapping if Firestore fetch fails
      return _mapFirebaseUserToAppUserSync(firebaseUser);
    }
  }

  /// Maps Firebase User to AppUser (sync - from auth user only)
  AppUser _mapFirebaseUserToAppUserSync(User firebaseUser) {
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a new user document in Firestore
  Future<void> _createUserDocument(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toFirestore());
      appLogger.i('$_logTag Created user document userId=${user.id}');
    } catch (e, stackTrace) {
      // Log error but don't throw - auth succeeded even if Firestore write failed
      appLogger.w(
        '$_logTag Failed to create user document in Firestore userId=${user.id}',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Updates an existing user document in Firestore
  Future<void> _updateUserDocument(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());
      appLogger.d('$_logTag Updated user document userId=${user.id}');
    } catch (e, stackTrace) {
      // Log error but don't throw
      appLogger.w(
        '$_logTag Failed to update user document in Firestore userId=${user.id}',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handles Firebase Auth exceptions and converts them to custom exceptions
  AuthException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const InvalidEmailException();
      case 'weak-password':
        return const WeakPasswordException();
      case 'email-already-in-use':
        return const EmailAlreadyInUseException();
      case 'user-not-found':
        return const UserNotFoundException();
      case 'wrong-password':
        return const WrongPasswordException();
      case 'user-disabled':
        return const UserDisabledException();
      case 'too-many-requests':
        return const TooManyRequestsException();
      case 'network-request-failed':
        return const NetworkException();
      default:
        return AuthException(
          e.message ?? 'Authentication failed',
          code: e.code,
        );
    }
  }
}
