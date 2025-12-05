import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logger/logger.dart';
import 'package:tasker/src/core/utils/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  static const _logTag = '[NotificationService]';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      appLogger.d('$_logTag initialize skipped (already initialized)');
      return;
    }

    appLogger.i('$_logTag Initialization requested');

    try {
      tz.initializeTimeZones();
      // Set local timezone - critical for scheduled notifications
      final locationName = await _getLocalTimezoneName();
      tz.setLocalLocation(tz.getLocation(locationName));
      appLogger.d('$_logTag Timezones initialized location=$locationName');

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await logTimedAsync(
        '$_logTag Plugin initialization',
        () => _notifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        ),
      );

      _isInitialized = true;
      appLogger.i('$_logTag Initialization complete');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag Initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can be extended to navigate to specific screens
    // For now, just log the action
    appLogger.i(
      '$_logTag Notification tapped id=${response.id} payload=${response.payload}',
    );
  }

  /// Request notification permissions (required for iOS and Android 13+)
  Future<bool> requestPermissions() async {
    bool granted = false;

    // Request Android permissions (Android 13+)
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      granted =
          await logTimedAsync(
            '$_logTag Request Android notification permission',
            () => androidImplementation.requestNotificationsPermission(),
          ) ??
          false;
      appLogger.d('$_logTag Android notification permission granted=$granted');
    }

    // Request iOS permissions
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImplementation != null) {
      granted =
          await logTimedAsync(
            '$_logTag Request iOS notification permission',
            () => iosImplementation.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ),
          ) ??
          false;
      appLogger.d('$_logTag iOS notification permission granted=$granted');
    }

    appLogger.i('$_logTag requestPermissions result=$granted');
    return granted;
  }

  /// Get the local timezone name for the device
  Future<String> _getLocalTimezoneName() async {
    // For Android/iOS, try to detect system timezone
    // Fallback to UTC if detection fails
    try {
      // Get current timezone offset
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final offsetHours = offset.inHours;
      
      // Common timezone mappings based on offset
      if (offsetHours == 0) return 'UTC';
      if (offsetHours == 5 && offset.inMinutes == 330) return 'Asia/Kolkata'; // India
      if (offsetHours == 8) return 'Asia/Singapore';
      if (offsetHours == -5) return 'America/New_York';
      if (offsetHours == -8) return 'America/Los_Angeles';
      
      // Default fallback
      return 'UTC';
    } catch (e) {
      appLogger.w('$_logTag Failed to detect timezone, using UTC', error: e);
      return 'UTC';
    }
  }

  Future<bool> _ensureExactAlarmPermission() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation == null) {
      appLogger.d('$_logTag Exact alarm check skipped (no Android impl)');
      return true;
    }

    final canSchedule =
        await androidImplementation.canScheduleExactNotifications() ?? true;
    if (canSchedule) {
      appLogger.d('$_logTag Exact alarm permission already granted');
      return true;
    }

    final granted =
        await androidImplementation.requestExactAlarmsPermission() ?? false;
    appLogger.i('$_logTag Exact alarm permission result=$granted');
    return granted;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final enabled =
          await androidImplementation.areNotificationsEnabled() ?? false;
      appLogger.d('$_logTag Android notifications enabled=$enabled');
      return enabled;
    }

    // For iOS, we assume enabled if permission was granted
    appLogger.d('$_logTag areNotificationsEnabled fallback=true');
    return true;
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tasker_channel',
      'Tasker Notifications',
      channelDescription: 'Notifications for tasks and routines',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    appLogger.i(
      '$_logTag showNotification id=$id title=$title payloadPresent=${payload != null}',
    );
    try {
      await logTimedAsync(
        '$_logTag showNotification id=$id',
        () => _notifications.show(id, title, body, details, payload: payload),
      );
      appLogger.i('$_logTag showNotification success id=$id');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag showNotification failed id=$id',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Schedule a notification for a specific date and time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final notificationsGranted = await requestPermissions();
    if (!notificationsGranted) {
      throw const NotificationsDeniedException();
    }

    final exactGranted = await _ensureExactAlarmPermission();
    if (!exactGranted) {
      throw const ExactAlarmPermissionException();
    }

    const androidDetails = AndroidNotificationDetails(
      'tasker_channel',
      'Tasker Notifications',
      channelDescription: 'Notifications for tasks and routines',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    final trigger = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    
    if (trigger.isBefore(now)) {
      appLogger.w(
        '$_logTag scheduleNotification skipped - trigger in past id=$id trigger=$trigger now=$now',
      );
      return;
    }
    
    appLogger.i(
      '$_logTag scheduleNotification id=$id trigger=$trigger now=$now payloadPresent=${payload != null}',
    );
    try {
      await logTimedAsync(
        '$_logTag zonedSchedule id=$id',
        () => _notifications.zonedSchedule(
          id,
          title,
          body,
          trigger,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        ),
      );
      appLogger.i('$_logTag scheduleNotification success id=$id');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag scheduleNotification failed id=$id',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Schedule a daily notification at a specific time
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    final notificationsGranted = await requestPermissions();
    if (!notificationsGranted) {
      throw const NotificationsDeniedException();
    }

    final exactGranted = await _ensureExactAlarmPermission();
    if (!exactGranted) {
      throw const ExactAlarmPermissionException();
    }

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the scheduled time is in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'tasker_channel',
      'Tasker Notifications',
      channelDescription: 'Notifications for tasks and routines',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    final trigger = tz.TZDateTime.from(scheduledDate, tz.local);
    appLogger.i(
      '$_logTag scheduleDailyNotification id=$id trigger=$trigger payloadPresent=${payload != null}',
    );
    try {
      await logTimedAsync(
        '$_logTag zonedSchedule daily id=$id',
        () => _notifications.zonedSchedule(
          id,
          title,
          body,
          trigger,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        ),
      );
      appLogger.i('$_logTag scheduleDailyNotification success id=$id');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag scheduleDailyNotification failed id=$id',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    appLogger.w('$_logTag cancelNotification id=$id');
    await logTimedAsync(
      '$_logTag cancelNotification id=$id',
      () => _notifications.cancel(id),
      level: Level.debug,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    appLogger.w('$_logTag cancelAllNotifications');
    await logTimedAsync(
      '$_logTag cancelAllNotifications',
      () => _notifications.cancelAll(),
      level: Level.debug,
    );
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await logTimedAsync(
      '$_logTag pendingNotificationRequests',
      () => _notifications.pendingNotificationRequests(),
      level: Level.debug,
    );
    appLogger.d('$_logTag pendingNotificationRequests count=${pending.length}');
    return pending;
  }

  /// Get all active notifications (shown but not dismissed)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final active = await logTimedAsync(
        '$_logTag getActiveNotifications',
        () => androidImplementation.getActiveNotifications(),
        level: Level.debug,
      );
      appLogger.d('$_logTag getActiveNotifications count=${active.length}');
      return active;
    }
    return [];
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});
}

class NotificationPermissionException implements Exception {
  final String message;

  const NotificationPermissionException(this.message);

  @override
  String toString() => message;
}

class NotificationsDeniedException extends NotificationPermissionException {
  const NotificationsDeniedException()
    : super(
        'Notifications are disabled. Enable Tasker notifications to use reminders.',
      );
}

class ExactAlarmPermissionException extends NotificationPermissionException {
  const ExactAlarmPermissionException()
    : super(
        'Exact alarms are blocked. Allow Tasker to schedule exact alarms in system settings to enable reminders.',
      );
}
