import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

/// FCM Notification Service - Complete push notification implementation
/// Works in: Foreground, Background, and Terminated states
/// NO Cloud Functions required!
class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._();

  static const String _logTag = '[FCM]';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM and local notifications
  Future<void> initialize() async {
    appLogger.i('$_logTag Initializing FCM Notification Service...');

    try {
      // 1. Request notification permissions
      final settings = await _requestPermissions();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        appLogger.w('$_logTag Notification permission denied');
        return;
      }

      // 2. Initialize local notifications (for foreground)
      await _initializeLocalNotifications();

      // 3. Get FCM token
      await _getFcmToken();

      // 4. Setup message handlers
      _setupMessageHandlers();

      // 5. Listen for token refresh
      _setupTokenRefreshListener();

      appLogger.i('$_logTag Initialization complete ✅');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Request notification permissions (iOS & Android 13+)
  Future<NotificationSettings> _requestPermissions() async {
    appLogger.d('$_logTag Requesting notification permissions...');

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    appLogger.i('$_logTag Permission status: ${settings.authorizationStatus}');
    return settings;
  }

  /// Initialize flutter_local_notifications
  Future<void> _initializeLocalNotifications() async {
    appLogger.d('$_logTag Initializing local notifications...');

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    await _createAndroidNotificationChannel();

    appLogger.i('$_logTag Local notifications initialized');
  }

  /// Create Android notification channel (required for Android 8.0+)
  Future<void> _createAndroidNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'tasker_high_importance', // Channel ID
      'Tasker Notifications', // Channel name
      description: 'Important notifications from Tasker app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    appLogger.d('$_logTag Android notification channel created');
  }

  /// Get FCM device token
  Future<String?> _getFcmToken() async {
    try {
      _fcmToken = await _fcm.getToken();

      if (_fcmToken != null) {
        appLogger.i('$_logTag ═══════════════════════════════════════');
        appLogger.i('$_logTag FCM DEVICE TOKEN:');
        appLogger.i('$_logTag $_fcmToken');
        appLogger.i('$_logTag ═══════════════════════════════════════');

        // TODO: Send this token to your backend server
        // await _sendTokenToServer(_fcmToken!);
      } else {
        appLogger.w('$_logTag Failed to get FCM token');
      }

      return _fcmToken;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Error getting FCM token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    appLogger.d('$_logTag Setting up message handlers...');

    // 1. FOREGROUND: Handle messages when app is open
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 2. BACKGROUND: Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 3. TERMINATED: Handle notification tap when app was killed
    _checkForInitialMessage();

    appLogger.d('$_logTag Message handlers configured');
  }

  /// Handle messages when app is in FOREGROUND
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    appLogger.i('$_logTag 🔔 Foreground message received');
    appLogger.d('$_logTag Message ID: ${message.messageId}');
    appLogger.d('$_logTag From: ${message.from}');

    if (message.notification != null) {
      appLogger.d('$_logTag Title: ${message.notification!.title}');
      appLogger.d('$_logTag Body: ${message.notification!.body}');
    }

    if (message.data.isNotEmpty) {
      appLogger.d('$_logTag Data: ${message.data}');
    }

    // Show local notification (because FCM doesn't show notification in foreground)
    await _showLocalNotification(message);
  }

  /// Show local notification using flutter_local_notifications
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      appLogger.w(
        '$_logTag No notification payload, skipping local notification',
      );
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'tasker_high_importance',
        'Tasker Notifications',
        channelDescription: 'Important notifications from Tasker app',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      appLogger.i('$_logTag Local notification shown');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Error showing local notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle notification tap (from background state)
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    appLogger.i('$_logTag 👆 Notification tapped (from background)');
    appLogger.d('$_logTag Data: ${message.data}');

    // Navigate to specific screen based on notification data
    await _navigateToScreen(message.data);
  }

  /// Check for initial message (when app was terminated)
  Future<void> _checkForInitialMessage() async {
    final initialMessage = await _fcm.getInitialMessage();

    if (initialMessage != null) {
      appLogger.i(
        '$_logTag 🚀 App opened from terminated state via notification',
      );
      appLogger.d('$_logTag Data: ${initialMessage.data}');

      // Navigate to specific screen
      await _navigateToScreen(initialMessage.data);
    }
  }

  /// Handle local notification tap (foreground notifications)
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    appLogger.i('$_logTag 👆 Local notification tapped');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        appLogger.d('$_logTag Payload: $data');
        await _navigateToScreen(data);
      } catch (e) {
        appLogger.e('$_logTag Error parsing notification payload', error: e);
      }
    }
  }

  /// Navigate to specific screen based on notification data
  Future<void> _navigateToScreen(Map<String, dynamic> data) async {
    appLogger.d('$_logTag Navigating based on data: $data');

    final type = data['type'] as String?;
    final screen = data['screen'] as String?;

    // TODO: Implement your navigation logic here
    // Example:
    // if (type == 'invitation') {
    //   navigatorKey.currentState?.pushNamed('/invitations');
    // } else if (type == 'task') {
    //   final taskId = data['taskId'];
    //   navigatorKey.currentState?.pushNamed('/task/$taskId');
    // }

    appLogger.d('$_logTag Navigation type: $type, screen: $screen');
  }

  /// Listen for FCM token refresh
  void _setupTokenRefreshListener() {
    _fcm.onTokenRefresh.listen((newToken) {
      appLogger.i('$_logTag 🔄 FCM token refreshed');
      appLogger.i('$_logTag New token: $newToken');
      _fcmToken = newToken;

      // TODO: Send new token to your backend
      // await _sendTokenToServer(newToken);
    });
  }

  /// Send FCM token to your backend (optional)
  Future<void> _sendTokenToServer(String token) async {
    // TODO: Implement your API call to save token
    // Example:
    // try {
    //   final response = await http.post(
    //     Uri.parse('https://your-api.com/fcm-token'),
    //     headers: {'Content-Type': 'application/json'},
    //     body: jsonEncode({'token': token, 'userId': currentUserId}),
    //   );
    //   if (response.statusCode == 200) {
    //     appLogger.i('$_logTag Token saved to server');
    //   }
    // } catch (e) {
    //   appLogger.e('$_logTag Error saving token to server', error: e);
    // }
  }

  /// Delete FCM token (call on logout)
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      _fcmToken = null;
      appLogger.i('$_logTag FCM token deleted');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Error deleting token',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Subscribe to topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      appLogger.i('$_logTag Subscribed to topic: $topic');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Error subscribing to topic',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      appLogger.i('$_logTag Unsubscribed from topic: $topic');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Error unsubscribing from topic',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND NOTIFICATIONS WITHOUT CLOUD FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Send FCM notification using Firebase Legacy API (Server Key)
  /// This is a CLIENT-SIDE implementation (NOT recommended for production)
  /// Use this only for testing! In production, send from your backend.
  static Future<bool> sendNotificationViaLegacyApi({
    required String serverKey,
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      appLogger.d('$_logTag Sending notification via Legacy API...');

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': deviceToken,
          'notification': {'title': title, 'body': body, 'sound': 'default'},
          'data': data ?? {},
          'priority': 'high',
          'content_available': true,
        }),
      );

      if (response.statusCode == 200) {
        appLogger.i('$_logTag Notification sent successfully ✅');
        appLogger.d('$_logTag Response: ${response.body}');
        return true;
      } else {
        appLogger.e('$_logTag Failed to send notification');
        appLogger.e('$_logTag Status: ${response.statusCode}');
        appLogger.e('$_logTag Response: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Error sending notification',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get Firebase Server Key from Firebase Console
  /// Steps:
  /// 1. Go to Firebase Console → Project Settings → Cloud Messaging
  /// 2. Find "Server key" under "Project credentials"
  /// 3. Copy the key (starts with "AAAA...")
  ///
  /// ⚠️ WARNING: Never expose server key in production apps!
  /// Use backend API to send notifications instead.
}
