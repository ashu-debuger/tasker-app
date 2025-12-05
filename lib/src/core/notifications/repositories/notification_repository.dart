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
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

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
}
