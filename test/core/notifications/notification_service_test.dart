import 'package:flutter_test/flutter_test.dart';
import 'package:tasker/src/core/notifications/notification_service.dart';

void main() {
  group('NotificationService', () {
    test('singleton instance returns same object', () {
      final instance1 = NotificationService();
      final instance2 = NotificationService();

      expect(instance1, same(instance2));
    });

    test('TimeOfDay validates hour and minute', () {
      const time1 = TimeOfDay(hour: 0, minute: 0);
      expect(time1.hour, 0);
      expect(time1.minute, 0);

      const time2 = TimeOfDay(hour: 23, minute: 59);
      expect(time2.hour, 23);
      expect(time2.minute, 59);
    });

    test('TimeOfDay stores time correctly', () {
      const morningTime = TimeOfDay(hour: 9, minute: 30);
      expect(morningTime.hour, 9);
      expect(morningTime.minute, 30);

      const eveningTime = TimeOfDay(hour: 18, minute: 45);
      expect(eveningTime.hour, 18);
      expect(eveningTime.minute, 45);
    });

    test('NotificationService instance is created', () {
      final service = NotificationService();
      expect(service, isNotNull);
      expect(service, isA<NotificationService>());
    });

    test('NotificationService exposes required methods', () {
      final service = NotificationService();
      
      // Verify all public methods exist
      expect(service.initialize, isA<Function>());
      expect(service.requestPermissions, isA<Function>());
      expect(service.areNotificationsEnabled, isA<Function>());
      expect(service.showNotification, isA<Function>());
      expect(service.scheduleNotification, isA<Function>());
      expect(service.scheduleDailyNotification, isA<Function>());
      expect(service.cancelNotification, isA<Function>());
      expect(service.cancelAllNotifications, isA<Function>());
      expect(service.getPendingNotifications, isA<Function>());
      expect(service.getActiveNotifications, isA<Function>());
    });

    // Note: Platform-specific initialization and actual notification scheduling
    // cannot be tested in unit tests. These require integration tests or
    // widget tests with proper platform channels mocked.
  });
}
