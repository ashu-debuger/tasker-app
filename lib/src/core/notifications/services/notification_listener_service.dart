import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_logger.dart';
import '../models/app_notification.dart';
import 'push_notification_service.dart';

/// Service that listens to Firestore notifications and shows push notifications
/// This replaces the need for Firebase Cloud Functions
class NotificationListenerService {
  static const String _logTag = 'NotificationListener';

  final FirebaseFirestore _firestore;
  final PushNotificationService _pushService;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  String? _currentUserId;
  final Set<String> _shownNotificationIds = {};
  DateTime? _listenerStartTime;

  NotificationListenerService({
    required FirebaseFirestore firestore,
    required PushNotificationService pushService,
  }) : _firestore = firestore,
       _pushService = pushService;

  /// Start listening to notifications for a user
  Future<void> startListening(String userId) async {
    if (_currentUserId == userId && _notificationSubscription != null) {
      AppLogger.debug('$_logTag Already listening for user: $userId');
      return;
    }

    // Stop previous subscription if any
    await stopListening();

    AppLogger.info('$_logTag Starting notification listener for user: $userId');
    _currentUserId = userId;
    _listenerStartTime = DateTime.now();
    _shownNotificationIds.clear();

    // Listen to all unread notifications
    // We'll filter out old ones in the handler
    _notificationSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            AppLogger.debug(
              '$_logTag Snapshot received: ${snapshot.docChanges.length} changes',
            );

            for (final change in snapshot.docChanges) {
              AppLogger.debug(
                '$_logTag Change type: ${change.type}, doc: ${change.doc.id}',
              );

              if (change.type == DocumentChangeType.added) {
                _handleNewNotification(change.doc);
              }
            }
          },
          onError: (error, stackTrace) {
            AppLogger.error(
              '$_logTag Error listening to notifications',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );

    AppLogger.info('$_logTag Notification listener active and waiting...');
  }

  /// Handle new notification by showing local push notification
  void _handleNewNotification(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      // Skip if we've already shown this notification
      if (_shownNotificationIds.contains(doc.id)) {
        AppLogger.debug(
          '$_logTag Skipping already shown notification: ${doc.id}',
        );
        return;
      }

      final notification = AppNotification.fromJson({'id': doc.id, ...data});

      // Only show notifications created after the listener started
      // This prevents showing old notifications when user logs in
      if (_listenerStartTime != null &&
          notification.createdAt.isBefore(_listenerStartTime!)) {
        AppLogger.debug(
          '$_logTag Skipping old notification: ${notification.title} '
          '(created: ${notification.createdAt}, listener started: $_listenerStartTime)',
        );
        _shownNotificationIds.add(
          doc.id,
        ); // Mark as shown to avoid checking again
        return;
      }

      AppLogger.info(
        '$_logTag New notification received: ${notification.title}',
      );

      // Mark as shown before displaying to avoid race conditions
      _shownNotificationIds.add(doc.id);

      // Show local push notification
      _pushService.showNotification(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        imageUrl: notification.imageUrl,
        data: notification.data,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '$_logTag Error handling new notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Stop listening to notifications
  Future<void> stopListening() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
    _listenerStartTime = null;
    _shownNotificationIds.clear();
    AppLogger.info('$_logTag Stopped notification listener');
  }

  /// Dispose resources
  void dispose() {
    stopListening();
  }
}
