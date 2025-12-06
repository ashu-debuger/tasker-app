import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/app_logger.dart';

/// Simple FCM service - handles push notifications when app is closed/background/foreground
class SimpleFcmService {
  static final SimpleFcmService _instance = SimpleFcmService._();
  factory SimpleFcmService() => _instance;
  SimpleFcmService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String? _token;

  /// Initialize FCM
  Future<void> initialize() async {
    try {
      appLogger.i('[FCM] Initializing...');

      // Request permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        appLogger.w('[FCM] Permission denied');
        return;
      }

      // Get token
      _token = await _fcm.getToken();
      if (_token != null) {
        appLogger.i('[FCM] Token: $_token');
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _token = newToken;
        appLogger.i('[FCM] Token refreshed: $newToken');
      });

      // Create the notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'tasker_notifications', // id
        'Tasker Notifications', // title
        description:
            'This channel is used for important notifications.', // description
        importance: Importance.high,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      appLogger.i('[FCM] Initialized successfully');
    } catch (e, stack) {
      appLogger.e('[FCM] Initialization failed', error: e, stackTrace: stack);
    }
  }

  /// Get current FCM token
  String? get token => _token;

  /// Save token to Firestore for a user
  Future<void> saveTokenForUser(String userId) async {
    if (_token == null) {
      appLogger.w('[FCM] No token to save');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(_token)
          .set({
            'token': _token,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUsed': FieldValue.serverTimestamp(),
          });

      appLogger.i('[FCM] Token saved for user: $userId');
    } catch (e) {
      appLogger.e('[FCM] Failed to save token', error: e);
    }
  }
}
