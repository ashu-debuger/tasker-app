import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show PendingNotificationRequest, ActiveNotification;
import 'package:tasker/src/core/notifications/notification_service.dart';
import 'package:tasker/src/features/routines/domain/helpers/routine_notification_helper.dart';
import 'package:tasker/src/features/routines/domain/models/routine.dart';
import 'package:tasker/src/features/settings/data/repositories/reminder_settings_repository.dart';
import 'package:tasker/src/features/settings/domain/models/reminder_settings.dart';

// Fake NotificationService for testing
class FakeNotificationService implements NotificationService {
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<int> canceledNotifications = [];

  @override
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'time': time,
      'payload': payload,
    });
  }

  @override
  Future<void> cancelNotification(int id) async {
    canceledNotifications.add(id);
  }

  // Unimplemented methods - not needed for these tests
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {}

  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async =>
      [];

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => [];
}

class FakeReminderSettingsRepository implements ReminderSettingsRepository {
  ReminderSettings current = const ReminderSettings();

  @override
  ReminderSettings getCurrentSettings() => current;

  @override
  Stream<ReminderSettings> watchSettings() => Stream.value(current);

  @override
  Future<void> saveSettings(ReminderSettings settings) async {
    current = settings;
  }

  @override
  Future<void> resetToDefaults() async {
    current = ReminderSettings.defaults;
  }
}

void main() {
  late FakeNotificationService fakeNotificationService;
  late FakeReminderSettingsRepository fakeReminderRepository;
  late RoutineNotificationHelper helper;

  setUp(() {
    fakeNotificationService = FakeNotificationService();
    fakeReminderRepository = FakeReminderSettingsRepository();
    helper = RoutineNotificationHelper(
      fakeNotificationService,
      fakeReminderRepository,
    );
  });

  group('RoutineNotificationHelper', () {
    group('scheduleRoutineNotification', () {
      test(
        'schedules notification when reminder is enabled and routine is active',
        () async {
          // Arrange
          final routine = Routine(
            id: 'test-routine-1',
            userId: 'user-123',
            title: 'Morning Exercise',
            description: 'Daily workout',
            frequency: RoutineFrequency.daily,
            timeOfDay: '08:00',
            isActive: true,
            reminderEnabled: true,
            reminderMinutesBefore: 15,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Act
          await helper.scheduleRoutineNotification(routine);

          // Assert
          expect(fakeNotificationService.scheduledNotifications.length, 1);
          final notification =
              fakeNotificationService.scheduledNotifications.first;
          expect(notification['title'], 'Routine Reminder: Morning Exercise');
          expect(notification['body'], 'Daily workout');
          expect(
            (notification['time'] as TimeOfDay).hour,
            7,
          ); // 08:00 - 15 min = 07:45
          expect((notification['time'] as TimeOfDay).minute, 45);
          expect(notification['payload'], 'routine:test-routine-1');
        },
      );

      test('does not schedule when reminder is disabled', () async {
        // Arrange
        final routine = Routine(
          id: 'test-routine-2',
          userId: 'user-123',
          title: 'Evening Walk',
          frequency: RoutineFrequency.daily,
          timeOfDay: '18:00',
          isActive: true,
          reminderEnabled: false, // Disabled
          reminderMinutesBefore: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await helper.scheduleRoutineNotification(routine);

        // Assert
        expect(fakeNotificationService.scheduledNotifications.length, 0);
      });

      test('does not schedule when routine is not active', () async {
        // Arrange
        final routine = Routine(
          id: 'test-routine-3',
          userId: 'user-123',
          title: 'Meditation',
          frequency: RoutineFrequency.daily,
          timeOfDay: '06:00',
          isActive: false, // Not active
          reminderEnabled: true,
          reminderMinutesBefore: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await helper.scheduleRoutineNotification(routine);

        // Assert
        expect(fakeNotificationService.scheduledNotifications.length, 0);
      });

      test('does not schedule when timeOfDay is null', () async {
        // Arrange
        final routine = Routine(
          id: 'test-routine-4',
          userId: 'user-123',
          title: 'Flexible Task',
          frequency: RoutineFrequency.daily,
          timeOfDay: null, // No time set
          isActive: true,
          reminderEnabled: true,
          reminderMinutesBefore: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await helper.scheduleRoutineNotification(routine);

        // Assert
        expect(fakeNotificationService.scheduledNotifications.length, 0);
      });

      test(
        'handles hour underflow correctly (reminder time crosses midnight)',
        () async {
          // Arrange
          final routine = Routine(
            id: 'test-routine-5',
            userId: 'user-123',
            title: 'Early Morning Routine',
            frequency: RoutineFrequency.daily,
            timeOfDay: '00:10', // 12:10 AM
            isActive: true,
            reminderEnabled: true,
            reminderMinutesBefore:
                30, // Should wrap to 23:40 (11:40 PM previous day)
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Act
          await helper.scheduleRoutineNotification(routine);

          // Assert
          expect(fakeNotificationService.scheduledNotifications.length, 1);
          final notification =
              fakeNotificationService.scheduledNotifications.first;
          expect(
            (notification['time'] as TimeOfDay).hour,
            23,
          ); // Wraps to previous day
          expect((notification['time'] as TimeOfDay).minute, 40);
        },
      );

      test('handles minute underflow within same hour', () async {
        // Arrange
        final routine = Routine(
          id: 'test-routine-6',
          userId: 'user-123',
          title: 'Lunch Break',
          frequency: RoutineFrequency.daily,
          timeOfDay: '12:05',
          isActive: true,
          reminderEnabled: true,
          reminderMinutesBefore: 10, // Should result in 11:55
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await helper.scheduleRoutineNotification(routine);

        // Assert
        expect(fakeNotificationService.scheduledNotifications.length, 1);
        final notification =
            fakeNotificationService.scheduledNotifications.first;
        expect((notification['time'] as TimeOfDay).hour, 11);
        expect((notification['time'] as TimeOfDay).minute, 55);
      });

      test('generates consistent notification ID for same routine', () async {
        // Arrange
        final routine = Routine(
          id: 'consistent-id',
          userId: 'user-123',
          title: 'Test Routine',
          frequency: RoutineFrequency.daily,
          timeOfDay: '10:00',
          isActive: true,
          reminderEnabled: true,
          reminderMinutesBefore: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await helper.scheduleRoutineNotification(routine);
        final firstId =
            fakeNotificationService.scheduledNotifications.first['id'];

        fakeNotificationService.scheduledNotifications.clear();

        await helper.scheduleRoutineNotification(routine);
        final secondId =
            fakeNotificationService.scheduledNotifications.first['id'];

        // Assert - Should be same ID both times
        expect(firstId, secondId);
      });

      test('generates positive notification IDs', () async {
        // Arrange
        final routine = Routine(
          id: 'negative-hash-test',
          userId: 'user-123',
          title: 'Test Routine',
          frequency: RoutineFrequency.daily,
          timeOfDay: '14:00',
          isActive: true,
          reminderEnabled: true,
          reminderMinutesBefore: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await helper.scheduleRoutineNotification(routine);

        // Assert
        final notificationId =
            fakeNotificationService.scheduledNotifications.first['id'] as int;
        expect(notificationId, greaterThan(0)); // Must be positive
      });
    });

    group('cancelRoutineNotification', () {
      test('cancels notification by routine ID', () async {
        // Arrange
        const routineId = 'cancel-test-1';

        // Act
        await helper.cancelRoutineNotification(routineId);

        // Assert
        expect(fakeNotificationService.canceledNotifications.length, 1);
      });

      test('generates same ID for cancel as schedule', () async {
        // Arrange
        const routineId = 'consistency-test';
        final routine = Routine(
          id: routineId,
          userId: 'user-123',
          title: 'Test',
          frequency: RoutineFrequency.daily,
          timeOfDay: '09:00',
          isActive: true,
          reminderEnabled: true,
          reminderMinutesBefore: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await helper.scheduleRoutineNotification(routine);
        final scheduleId =
            fakeNotificationService.scheduledNotifications.first['id'];

        await helper.cancelRoutineNotification(routineId);
        final cancelId = fakeNotificationService.canceledNotifications.first;

        // Assert
        expect(scheduleId, equals(cancelId));
      });
    });

    group('rescheduleRoutineNotification', () {
      test('cancels old notification and schedules new one', () async {
        // Arrange
        final routine = Routine(
          id: 'reschedule-test',
          userId: 'user-123',
          title: 'Updated Routine',
          frequency: RoutineFrequency.daily,
          timeOfDay: '15:00',
          isActive: true,
          reminderEnabled: true,
          reminderMinutesBefore: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await helper.rescheduleRoutineNotification(routine);

        // Assert - verify cancel called before schedule
        expect(fakeNotificationService.canceledNotifications.length, 1);
        expect(fakeNotificationService.scheduledNotifications.length, 1);

        // Verify same ID for both operations
        final cancelId = fakeNotificationService.canceledNotifications.first;
        final scheduleId =
            fakeNotificationService.scheduledNotifications.first['id'];
        expect(cancelId, scheduleId);
      });

      test('cancels notification even if rescheduling fails', () async {
        // Arrange
        final routine = Routine(
          id: 'fail-test',
          userId: 'user-123',
          title: 'Failing Routine',
          frequency: RoutineFrequency.daily,
          timeOfDay: null, // Invalid - will not schedule
          isActive: true,
          reminderEnabled: true,
          reminderMinutesBefore: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await helper.rescheduleRoutineNotification(routine);

        // Assert - cancel should be called even though schedule won't be
        expect(fakeNotificationService.canceledNotifications.length, 1);
        expect(fakeNotificationService.scheduledNotifications.length, 0);
      });
    });
  });
}
