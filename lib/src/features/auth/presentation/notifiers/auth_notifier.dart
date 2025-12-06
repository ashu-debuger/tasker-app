import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/simple_fcm_service.dart';

part 'auth_notifier.g.dart';

/// Authentication state notifier
/// Manages user authentication state using StreamNotifier
@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final AuthRepository _authRepository;

  @override
  Stream<AppUser?> build() {
    _authRepository = ref.read(authRepositoryProvider);
    // Return the auth state stream from repository
    return _authRepository.authStateChanges;
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        AppLogger.info('Attempting sign in for: $email');
        final user = await _authRepository.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        AppLogger.logSignIn('email');
        AppLogger.info('Sign in successful for: $email');

        // Save FCM token after successful sign in
        try {
          final fcmService = SimpleFcmService();
          await fcmService.saveTokenForUser(user.id);
          AppLogger.info('FCM token saved for user: ${user.id}');

          // Start notification listener
          final notificationListener = ref.read(
            notificationListenerServiceProvider,
          );
          await notificationListener.startListening(user.id);
          AppLogger.info('Notification listener started for user: ${user.id}');
        } catch (e) {
          AppLogger.error('Failed to setup notifications', error: e);
          // Don't fail the sign in if setup fails
        }

        return user;
      } catch (e, stackTrace) {
        final error = ErrorHandler.handleError(e, stackTrace);
        AppLogger.error('Sign in failed', error: error, stackTrace: stackTrace);
        throw error;
      }
    });
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        AppLogger.info('Attempting sign up for: $email');
        final user = await _authRepository.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        );
        AppLogger.logSignIn('email_signup');
        AppLogger.info('Sign up successful for: $email');

        // Save FCM token after successful sign up
        try {
          final fcmService = SimpleFcmService();
          await fcmService.saveTokenForUser(user.id);
          AppLogger.info('FCM token saved for user: ${user.id}');

          // Start notification listener
          final notificationListener = ref.read(
            notificationListenerServiceProvider,
          );
          await notificationListener.startListening(user.id);
          AppLogger.info('Notification listener started for user: ${user.id}');
        } catch (e) {
          AppLogger.error('Failed to setup notifications', error: e);
          // Don't fail the sign up if setup fails
        }

        return user;
      } catch (e, stackTrace) {
        final error = ErrorHandler.handleError(e, stackTrace);
        AppLogger.error('Sign up failed', error: error, stackTrace: stackTrace);
        throw error;
      }
    });
  }

  /// Sign out the current user
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        AppLogger.info('User signing out');

        // Stop listener and delete FCM token before signing out
        try {
          final currentUser = _authRepository.currentUser;
          if (currentUser != null) {
            final pushService = ref.read(pushNotificationServiceProvider);
            final notificationRepo = ref.read(notificationRepositoryProvider);
            final notificationListener = ref.read(
              notificationListenerServiceProvider,
            );

            // Stop listening for notifications
            await notificationListener.stopListening();
            AppLogger.info('Notification listener stopped');

            final token = await pushService.getToken();
            if (token != null) {
              await notificationRepo.deleteFcmToken(currentUser.id, token);
              AppLogger.info('FCM token deleted for user: ${currentUser.id}');
            }
          }
        } catch (e) {
          AppLogger.error('Failed to cleanup push notifications', error: e);
          // Don't fail the sign out if cleanup fails
        }

        await _authRepository.signOut();
        AppLogger.logSignOut();
        AppLogger.info('Sign out successful');
        return null;
      } catch (e, stackTrace) {
        final error = ErrorHandler.handleError(e, stackTrace);
        AppLogger.error(
          'Sign out failed',
          error: error,
          stackTrace: stackTrace,
        );
        throw error;
      }
    });
  }

  /// Reset password for the given email
  Future<void> resetPassword({required String email}) async {
    await _authRepository.resetPassword(email: email);
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return _authRepository.currentUser;
    });
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.deleteAccount();
      return null;
    });
  }
}
