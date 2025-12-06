import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/app_logger.dart';

/// Top-level function to handle background FCM messages
/// This is called when app is closed or in background
@pragma('vm:entry-point')
Future<void> simpleBackgroundHandler(RemoteMessage message) async {
  appLogger.i('[FCM Background] Message received');
  appLogger.i('[FCM Background] Title: ${message.notification?.title}');
  appLogger.i('[FCM Background] Body: ${message.notification?.body}');
  appLogger.i('[FCM Background] Data: ${message.data}');

  // Android automatically shows notification when app is closed/background
  // No need to do anything here - just log for debugging
}
