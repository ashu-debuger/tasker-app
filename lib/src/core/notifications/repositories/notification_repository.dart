import '../models/app_notification.dart';
import '../models/notification_type.dart';

/// Repository for managing in-app notifications
abstract class NotificationRepository {
  /// Create a new notification
  Future<void> createNotification(AppNotification notification);

  /// Get notifications for a user
  Stream<List<AppNotification>> streamUserNotifications(String userId);

  /// Get unread notifications for a user
  Stream<List<AppNotification>> streamUnreadNotifications(String userId);

  /// Get unread notification count
  Stream<int> streamUnreadCount(String userId);

  /// Mark a notification as read
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  });

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId);

  /// Delete a notification
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  });

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId);

  /// Send a notification (creates notification record)
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? actionUrl,
  });

  /// Save FCM token for a user
  Future<void> saveFcmToken(String userId, String token);

  /// Delete FCM token for a user
  Future<void> deleteFcmToken(String userId, String token);
}
