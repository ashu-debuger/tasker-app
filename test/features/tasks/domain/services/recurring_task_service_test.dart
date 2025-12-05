import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tasker/src/core/encryption/encryption_service.dart';
import 'package:tasker/src/features/tasks/data/repositories/firebase_task_repository.dart';
import 'package:tasker/src/features/tasks/domain/models/task.dart';
import 'package:tasker/src/features/tasks/domain/services/recurring_task_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late EncryptionService encryptionService;
  late FirebaseTaskRepository repository;
  late RecurringTaskService service;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    FlutterSecureStorage.setMockInitialValues({});
    encryptionService = EncryptionService();
    await encryptionService.initialize();
    repository = FirebaseTaskRepository(fakeFirestore, encryptionService);
    service = RecurringTaskService(repository);
  });

  group('RecurringTaskService', () {
    group('Task Model - Recurrence Pattern', () {
      test('isRecurring returns true for task with recurrence pattern', () {
        final task = Task(
          id: 'task-1',
          projectId: 'project-1',
          title: 'Daily Standup',
          recurrencePattern: RecurrencePattern.daily,
          dueDate: DateTime(2025, 11, 13, 9, 0),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        expect(task.isRecurring, true);
        expect(task.isRecurringInstance, false);
      });

      test('isRecurring returns false for non-recurring task', () {
        final task = Task(
          id: 'task-2',
          projectId: 'project-1',
          title: 'One-time Task',
          recurrencePattern: RecurrencePattern.none,
          assignees: const [],
          createdAt: DateTime.now(),
        );

        expect(task.isRecurring, false);
      });

      test('isRecurringInstance returns true for instance with parent ID', () {
        final task = Task(
          id: 'task-3',
          projectId: 'project-1',
          title: 'Daily Standup Instance',
          parentRecurringTaskId: 'task-1',
          assignees: const [],
          createdAt: DateTime.now(),
        );

        expect(task.isRecurringInstance, true);
        expect(task.isRecurring, false);
      });
    });

    group('getNextOccurrence', () {
      test('calculates daily recurrence correctly', () {
        final task = Task(
          id: 'task-1',
          projectId: 'project-1',
          title: 'Daily Task',
          recurrencePattern: RecurrencePattern.daily,
          recurrenceInterval: 1,
          dueDate: DateTime(2025, 11, 13, 10, 0),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final nextDate = task.getNextOccurrence();
        expect(nextDate, isNotNull);
        expect(nextDate!.year, 2025);
        expect(nextDate.month, 11);
        expect(nextDate.day, 14);
      });

      test('calculates daily recurrence with interval correctly', () {
        final task = Task(
          id: 'task-2',
          projectId: 'project-1',
          title: 'Every 3 Days',
          recurrencePattern: RecurrencePattern.daily,
          recurrenceInterval: 3,
          dueDate: DateTime(2025, 11, 13),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final nextDate = task.getNextOccurrence();
        expect(nextDate, isNotNull);
        expect(nextDate!.day, 16); // 13 + 3 days
      });

      test('calculates weekly recurrence correctly', () {
        final task = Task(
          id: 'task-3',
          projectId: 'project-1',
          title: 'Weekly Task',
          recurrencePattern: RecurrencePattern.weekly,
          recurrenceInterval: 1,
          dueDate: DateTime(2025, 11, 13),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final nextDate = task.getNextOccurrence();
        expect(nextDate, isNotNull);
        expect(nextDate!.day, 20); // 13 + 7 days
      });

      test('calculates bi-weekly recurrence correctly', () {
        final task = Task(
          id: 'task-4',
          projectId: 'project-1',
          title: 'Bi-Weekly Task',
          recurrencePattern: RecurrencePattern.weekly,
          recurrenceInterval: 2,
          dueDate: DateTime(2025, 11, 13),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final nextDate = task.getNextOccurrence();
        expect(nextDate, isNotNull);
        expect(nextDate!.day, 27); // 13 + 14 days
      });

      test('calculates monthly recurrence correctly', () {
        final task = Task(
          id: 'task-5',
          projectId: 'project-1',
          title: 'Monthly Task',
          recurrencePattern: RecurrencePattern.monthly,
          recurrenceInterval: 1,
          dueDate: DateTime(2025, 11, 15),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final nextDate = task.getNextOccurrence();
        expect(nextDate, isNotNull);
        expect(nextDate!.year, 2025);
        expect(nextDate.month, 12);
        expect(nextDate.day, 15);
      });

      test('handles month overflow correctly', () {
        final task = Task(
          id: 'task-6',
          projectId: 'project-1',
          title: 'Monthly Task',
          recurrencePattern: RecurrencePattern.monthly,
          recurrenceInterval: 1,
          dueDate: DateTime(2025, 12, 15),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final nextDate = task.getNextOccurrence();
        expect(nextDate, isNotNull);
        expect(nextDate!.year, 2026);
        expect(nextDate.month, 1);
        expect(nextDate.day, 15);
      });

      test('respects recurrence end date', () {
        final task = Task(
          id: 'task-7',
          projectId: 'project-1',
          title: 'Limited Recurrence',
          recurrencePattern: RecurrencePattern.daily,
          dueDate: DateTime(2025, 11, 13),
          recurrenceEndDate: DateTime(2025, 11, 13), // Ends today
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final nextDate = task.getNextOccurrence();
        expect(nextDate, isNull); // Should not recur
      });

      test('returns null for non-recurring task', () {
        final task = Task(
          id: 'task-8',
          projectId: 'project-1',
          title: 'No Recurrence',
          recurrencePattern: RecurrencePattern.none,
          dueDate: DateTime(2025, 11, 13),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final nextDate = task.getNextOccurrence();
        expect(nextDate, isNull);
      });
    });

    group('createNextInstance', () {
      test('creates instance from recurring task', () async {
        // Arrange
        final recurringTask = Task(
          id: 'recurring-1',
          projectId: 'project-1',
          title: 'Daily Report',
          description: 'Submit daily report',
          recurrencePattern: RecurrencePattern.daily,
          dueDate: DateTime(2025, 11, 13),
          assignees: const ['user-1'],
          createdAt: DateTime.now(),
        );

        await repository.createTask(recurringTask);

        // Act
        final instance = await service.createNextInstance(recurringTask);

        // Assert
        expect(instance, isNotNull);
        expect(instance!.title, 'Daily Report');
        expect(instance.description, 'Submit daily report');
        expect(instance.parentRecurringTaskId, 'recurring-1');
        expect(instance.recurrencePattern, RecurrencePattern.none);
        expect(instance.dueDate!.day, 14); // Next day
      });

      test('returns null when recurrence has ended', () async {
        // Arrange
        final recurringTask = Task(
          id: 'recurring-2',
          projectId: 'project-1',
          title: 'Limited Task',
          recurrencePattern: RecurrencePattern.daily,
          dueDate: DateTime(2025, 11, 13),
          recurrenceEndDate: DateTime(2025, 11, 13), // Ends today
          assignees: const [],
          createdAt: DateTime.now(),
        );

        // Act
        final instance = await service.createNextInstance(recurringTask);

        // Assert
        expect(instance, isNull);
      });

      test('returns null for non-recurring task', () async {
        // Arrange
        final task = Task(
          id: 'task-1',
          projectId: 'project-1',
          title: 'One-time Task',
          recurrencePattern: RecurrencePattern.none,
          assignees: const [],
          createdAt: DateTime.now(),
        );

        // Act
        final instance = await service.createNextInstance(task);

        // Assert
        expect(instance, isNull);
      });
    });

    group('getUpcomingRecurrences', () {
      test('returns upcoming dates for daily recurrence', () {
        final task = Task(
          id: 'task-1',
          projectId: 'project-1',
          title: 'Daily Task',
          recurrencePattern: RecurrencePattern.daily,
          dueDate: DateTime(2025, 11, 13),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final upcoming = service.getUpcomingRecurrences(task, count: 5);

        expect(upcoming.length, 5);
        expect(upcoming[0].day, 14); // Nov 14
        expect(upcoming[1].day, 15); // Nov 15
        expect(upcoming[2].day, 16); // Nov 16
        expect(upcoming[3].day, 17); // Nov 17
        expect(upcoming[4].day, 18); // Nov 18
      });

      test('stops at recurrence end date', () {
        final task = Task(
          id: 'task-2',
          projectId: 'project-1',
          title: 'Limited Task',
          recurrencePattern: RecurrencePattern.daily,
          dueDate: DateTime(2025, 11, 13),
          recurrenceEndDate: DateTime(2025, 11, 15),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final upcoming = service.getUpcomingRecurrences(task, count: 10);

        expect(upcoming.length, 2); // Only 14th and 15th
        expect(upcoming[0].day, 14);
        expect(upcoming[1].day, 15);
      });

      test('returns empty list for non-recurring task', () {
        final task = Task(
          id: 'task-3',
          projectId: 'project-1',
          title: 'One-time Task',
          recurrencePattern: RecurrencePattern.none,
          assignees: const [],
          createdAt: DateTime.now(),
        );

        final upcoming = service.getUpcomingRecurrences(task);
        expect(upcoming, isEmpty);
      });
    });

    group('generatePendingInstances', () {
      test('generates instances for recurring task with no existing instances', () async {
        // Arrange
        final recurringTask = Task(
          id: 'recurring-1',
          projectId: 'project-1',
          title: 'Weekly Meeting',
          recurrencePattern: RecurrencePattern.weekly,
          dueDate: DateTime(2025, 11, 13),
          assignees: const ['user-1'],
          createdAt: DateTime.now(),
        );

        await repository.createTask(recurringTask);

        // Act
        final instances = await service.generatePendingInstances(
          'project-1',
          lookaheadDays: 21, // 3 weeks
        );

        // Assert
        expect(instances.length, 3); // 3 weekly instances
        expect(instances[0].parentRecurringTaskId, 'recurring-1');
        expect(instances[1].parentRecurringTaskId, 'recurring-1');
        expect(instances[2].parentRecurringTaskId, 'recurring-1');
      });

      test('does not create duplicate instances', () async {
        // Arrange
        final recurringTask = Task(
          id: 'recurring-2',
          projectId: 'project-1',
          title: 'Daily Standup',
          recurrencePattern: RecurrencePattern.daily,
          dueDate: DateTime(2025, 11, 13),
          assignees: const [],
          createdAt: DateTime.now(),
        );

        await repository.createTask(recurringTask);

        // Create first instance manually
        final firstInstance = Task(
          id: 'instance-1',
          projectId: 'project-1',
          title: 'Daily Standup',
          dueDate: DateTime(2025, 11, 14),
          parentRecurringTaskId: 'recurring-2',
          assignees: const [],
          createdAt: DateTime.now(),
        );
        await repository.createTask(firstInstance);

        // Act
        final instances = await service.generatePendingInstances(
          'project-1',
          lookaheadDays: 3,
        );

        // Assert - Should not recreate the existing 14th instance and no duplicates
        final dueDays = instances
            .map((instance) => instance.dueDate?.day)
            .whereType<int>()
            .toList();

        expect(dueDays, isNot(contains(14)));
        expect(dueDays.length, dueDays.toSet().length); // unique dates
        expect(dueDays.every((day) => day > 14), true);
      });
    });
  });
}
