import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level function to handle background FCM messages
/// This MUST be a top-level function (not a class method)
/// Required for FCM to work when app is TERMINATED (fully closed)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();

  print('[FCM] ═══════════════════════════════════════');
  print('[FCM] Background message received (APP TERMINATED)');
  print('[FCM] Message ID: ${message.messageId}');
  print('[FCM] From: ${message.from}');

  if (message.notification != null) {
    print('[FCM] Title: ${message.notification!.title}');
    print('[FCM] Body: ${message.notification!.body}');
  }

  if (message.data.isNotEmpty) {
    print('[FCM] Data: ${message.data}');
  }

  print('[FCM] ═══════════════════════════════════════');

  // ✅ FCM automatically displays the notification if message contains 'notification' key
  // ✅ Android/iOS system handles showing the notification in the tray
  // ✅ No need to manually show notification here
  // ✅ Notification tap will launch the app
}
