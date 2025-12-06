import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/notifications/models/app_notification.dart';
import '../../../../core/notifications/repositories/notification_repository.dart';
import '../../../../core/providers/providers.dart';

part 'notification_notifier.g.dart';

@riverpod
class NotificationList extends _$NotificationList {
  late final NotificationRepository _repository;

  @override
  Stream<List<AppNotification>> build() {
    _repository = ref.watch(notificationRepositoryProvider);
    final user = ref.watch(authStateChangesProvider).value;

    if (user == null) {
      return Stream.value([]);
    }

    return _repository.streamUserNotifications(user.uid);
  }

  Future<void> markAsRead(String notificationId) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    await _repository.markAsRead(
      userId: user.uid,
      notificationId: notificationId,
    );
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user != null) {
      await _repository.markAllAsRead(user.uid);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    await _repository.deleteNotification(
      userId: user.uid,
      notificationId: notificationId,
    );
  }

  Future<void> deleteAllNotifications() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user != null) {
      await _repository.deleteAllNotifications(user.uid);
    }
  }
}

@riverpod
Stream<int> unreadNotificationCount(Ref ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final user = ref.watch(authStateChangesProvider).value;

  if (user == null) {
    return Stream.value(0);
  }

  return repository.streamUnreadCount(user.uid);
}
