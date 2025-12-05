import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../models/notification_type.dart';
import 'notification_repository.dart';
import '../../utils/app_logger.dart';

/// Firebase implementation of NotificationRepository
class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;
  static const _logTag = '[Notifications:Repo]';

  FirebaseNotificationRepository(this._firestore);

  /// Get notifications collection for a user
  CollectionReference _userNotificationsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  @override
  Future<void> createNotification(AppNotification notification) async {
    appLogger.d('$_logTag createNotification userId=${notification.userId}');
    try {
      await _userNotificationsCollection(
        notification.userId,
      ).doc(notification.id).set(notification.toFirestore());
      appLogger.i('$_logTag createNotification success id=${notification.id}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag createNotification failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<AppNotification>> streamUserNotifications(String userId) {
    try {
      appLogger.d('$_logTag streamUserNotifications subscribed userId=$userId');
      return _userNotificationsCollection(
        userId,
      ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
        final notifications = snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList();
        appLogger.d(
          '$_logTag streamUserNotifications snapshot=${notifications.length}',
        );
        return notifications;
      });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamUserNotifications failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<AppNotification>> streamUnreadNotifications(String userId) {
    try {
      appLogger.d(
        '$_logTag streamUnreadNotifications subscribed userId=$userId',
      );
      return _userNotificationsCollection(userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final notifications = snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc))
                .toList();
            appLogger.d(
              '$_logTag streamUnreadNotifications snapshot=${notifications.length}',
            );
            return notifications;
          });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamUnreadNotifications failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<int> streamUnreadCount(String userId) {
    try {
      appLogger.d('$_logTag streamUnreadCount subscribed userId=$userId');
      return _userNotificationsCollection(
        userId,
      ).where('isRead', isEqualTo: false).snapshots().map((snapshot) {
        final count = snapshot.docs.length;
        appLogger.d('$_logTag streamUnreadCount count=$count');
        return count;
      });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamUnreadCount failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    appLogger.d('$_logTag markAsRead id=$notificationId');
    try {
      // We need the userId to access the notification
      // This is a limitation - we could query all users, but that's inefficient
      // Better approach: pass userId as parameter
      throw UnimplementedError(
        'markAsRead requires userId parameter - use notification document reference',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag markAsRead failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Mark a specific notification as read (with userId)
  Future<void> markNotificationAsRead({
    required String userId,
    required String notificationId,
  }) async {
    appLogger.d('$_logTag markNotificationAsRead id=$notificationId');
    try {
      await _userNotificationsCollection(
        userId,
      ).doc(notificationId).update({'isRead': true});
      appLogger.i('$_logTag markNotificationAsRead success id=$notificationId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag markNotificationAsRead failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    appLogger.d('$_logTag markAllAsRead userId=$userId');
    try {
      final batch = _firestore.batch();
      final unreadDocs = await _userNotificationsCollection(
        userId,
      ).where('isRead', isEqualTo: false).get();

      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      appLogger.i(
        '$_logTag markAllAsRead success count=${unreadDocs.docs.length}',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag markAllAsRead failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    throw UnimplementedError('deleteNotification requires userId parameter');
  }

  /// Delete a specific notification (with userId)
  Future<void> deleteUserNotification({
    required String userId,
    required String notificationId,
  }) async {
    appLogger.w('$_logTag deleteUserNotification id=$notificationId');
    try {
      await _userNotificationsCollection(userId).doc(notificationId).delete();
      appLogger.i('$_logTag deleteUserNotification success id=$notificationId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteUserNotification failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    appLogger.w('$_logTag deleteAllNotifications userId=$userId');
    try {
      final batch = _firestore.batch();
      final allDocs = await _userNotificationsCollection(userId).get();

      for (final doc in allDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      appLogger.i(
        '$_logTag deleteAllNotifications success count=${allDocs.docs.length}',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteAllNotifications failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) async {
    appLogger.d('$_logTag sendNotification userId=$userId type=$type');
    try {
      final notification = AppNotification(
        id: _firestore.collection('users').doc().id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data ?? {},
        createdAt: DateTime.now(),
        isRead: false,
        actionUrl: actionUrl,
      );

      await createNotification(notification);
      appLogger.i('$_logTag sendNotification success id=${notification.id}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag sendNotification failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
