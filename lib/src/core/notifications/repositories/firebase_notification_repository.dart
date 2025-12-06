import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../models/notification_type.dart';
import 'notification_repository.dart';
import '../../utils/app_logger.dart';
import '../../services/notification_api_service.dart';

/// Firebase implementation of NotificationRepository
class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;
  final NotificationApiService? _apiService;
  static const _logTag = '[Notifications:Repo]';

  FirebaseNotificationRepository(
    this._firestore, {
    NotificationApiService? apiService,
  }) : _apiService = apiService;

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
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    appLogger.d('$_logTag markAsRead id=$notificationId');
    try {
      await _userNotificationsCollection(
        userId,
      ).doc(notificationId).update({'isRead': true});
      appLogger.i('$_logTag markAsRead success id=$notificationId');
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
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    appLogger.w('$_logTag deleteNotification id=$notificationId');
    try {
      await _userNotificationsCollection(userId).doc(notificationId).delete();
      appLogger.i('$_logTag deleteNotification success id=$notificationId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteNotification failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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

      // Also send push notification
      await _sendPushNotification(
        userId: userId,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data,
      );

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

  /// Send push notification via backend API
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    if (_apiService == null) {
      appLogger.d('$_logTag Push notification API not configured, skipping');
      return;
    }

    try {
      appLogger.i('$_logTag Sending push notification via API to $userId');

      // Prepare data with image URL if provided
      final notificationData = <String, dynamic>{
        if (data != null) ...data,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      // Send via backend API
      final success = await _apiService!.sendToUser(
        userId: userId,
        title: title,
        body: body,
        data: notificationData.isNotEmpty ? notificationData : null,
      );

      if (success) {
        appLogger.i('$_logTag Push notification sent successfully');
      } else {
        appLogger.w('$_logTag Push notification failed');
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag _sendPushNotification failed',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - notification was already created in Firestore
      // Push notification is best-effort
    }
  }

  /// Save FCM token for a user
  Future<void> saveFcmToken(String userId, String token) async {
    appLogger.d('$_logTag saveFcmToken userId=$userId');
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUsed': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      appLogger.i('$_logTag saveFcmToken success');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag saveFcmToken failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete FCM token for a user
  Future<void> deleteFcmToken(String userId, String token) async {
    appLogger.d('$_logTag deleteFcmToken userId=$userId');
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .delete();
      appLogger.i('$_logTag deleteFcmToken success');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteFcmToken failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
