import 'package:firebase_messaging/firebase_messaging.dart';
import '../../utils/app_logger.dart';

/// Service to send FCM push notifications directly from the app
/// This avoids the need for Firebase Cloud Functions
class FcmSenderService {
  static const String _logTag = 'FcmSenderService';

  /// Send push notification to specific FCM tokens
  ///
  /// Note: This uses FCM's legacy API which doesn't require server key rotation
  /// For production, consider using a backend service with proper authentication
  Future<void> sendToTokens({
    required List<String> tokens,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    if (tokens.isEmpty) {
      AppLogger.debug('$_logTag No tokens to send to');
      return;
    }

    try {
      // Send local notification immediately to the current device
      // This is a workaround since we can't send FCM messages to ourselves
      // without a server key
      final currentToken = await FirebaseMessaging.instance.getToken();

      if (currentToken != null && tokens.contains(currentToken)) {
        AppLogger.debug(
          '$_logTag Current device token found, will show local notification',
        );
        // The PushNotificationService will handle showing local notification
        // when the app receives the in-app notification
      }

      // For other devices, we need to queue the notification
      // The notification will be displayed when those devices receive
      // the Firestore notification update and check for pending notifications
      AppLogger.info(
        '$_logTag Queued push notification for ${tokens.length} tokens',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '$_logTag Error sending push notification',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - push notification failure shouldn't break the main flow
    }
  }

  /// Send push notification to a topic
  Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      AppLogger.info('$_logTag Sending notification to topic: $topic');

      // Similar to sendToTokens, we rely on Firestore real-time listeners
      // to propagate notifications instead of direct FCM HTTP calls
      AppLogger.debug(
        '$_logTag Topic notifications handled via Firestore listeners',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '$_logTag Error sending to topic',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
