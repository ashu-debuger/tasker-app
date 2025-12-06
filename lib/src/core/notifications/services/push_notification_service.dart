import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../utils/app_logger.dart';

/// Service for handling push notifications via Firebase Cloud Messaging
class PushNotificationService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  static const _logTag = '[PushNotifications]';

  PushNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  /// Initialize push notifications
  Future<void> initialize() async {
    appLogger.i('$_logTag Initializing push notifications');

    // Request permission for iOS
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    appLogger.i('$_logTag Permission status: ${settings.authorizationStatus}');

    // Initialize local notifications for Android foreground
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'tasker_channel',
      'Tasker Notifications',
      description: 'Notifications for Tasker app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    appLogger.i('$_logTag Notification channel created');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Get initial message if app was opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessageTap(initialMessage);
    }

    appLogger.i('$_logTag Initialization complete');
  }

  /// Get the FCM token for this device
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      appLogger.i('$_logTag FCM Token: $token');
      return token;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Failed to get FCM token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      appLogger.i('$_logTag Subscribed to topic: $topic');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Failed to subscribe to topic: $topic',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      appLogger.i('$_logTag Unsubscribed from topic: $topic');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Failed to unsubscribe from topic: $topic',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle foreground messages by showing local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    appLogger.d('$_logTag Foreground message: ${message.messageId}');

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _showLocalNotification(
        id: message.messageId.hashCode,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        payload: message.data.toString(),
        imageUrl: android?.imageUrl,
      );
    }
  }

  /// Handle notification tap from background
  void _handleBackgroundMessageTap(RemoteMessage message) {
    appLogger.d('$_logTag Background message tapped: ${message.messageId}');
    // Handle navigation based on message data
    _handleNotificationAction(message.data);
  }

  /// Handle notification tap from local notification
  void _onNotificationTapped(NotificationResponse response) {
    appLogger.d('$_logTag Local notification tapped: ${response.payload}');
    // Handle navigation based on payload
    if (response.payload != null) {
      // Parse and handle action
    }
  }

  /// Handle notification action (navigation)
  void _handleNotificationAction(Map<String, dynamic> data) {
    appLogger.d('$_logTag Handling notification action: $data');
    // This will be handled by the app's navigation system
    // For now, just log the action
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'tasker_channel',
        'Tasker Notifications',
        channelDescription: 'Notifications for Tasker app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      appLogger.d('$_logTag Local notification shown: $title');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Failed to show local notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete the FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      appLogger.i('$_logTag FCM token deleted');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Failed to delete FCM token',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Show a notification immediately (called when new notification arrives via Firestore)
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    await _showLocalNotification(
      id: id.hashCode,
      title: title,
      body: body,
      payload: data != null ? jsonEncode(data) : null,
      imageUrl: imageUrl,
    );
  }
}
