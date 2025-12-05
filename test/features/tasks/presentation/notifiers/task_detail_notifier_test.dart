import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasker/src/core/encryption/encryption_service.dart';
import 'package:tasker/src/core/notifications/notification_service.dart';
import 'package:tasker/src/core/providers/providers.dart';
import 'package:tasker/src/features/settings/data/repositories/reminder_settings_repository.dart';
import 'package:tasker/src/features/settings/domain/models/reminder_settings.dart';
import 'package:tasker/src/features/tasks/data/repositories/firebase_task_repository.dart';
import 'package:tasker/src/features/tasks/domain/helpers/task_reminder_helper.dart';
import 'package:tasker/src/features/tasks/domain/models/subtask.dart';
import 'package:tasker/src/features/tasks/domain/models/task.dart';
import 'package:tasker/src/features/tasks/presentation/notifiers/task_detail_notifier.dart'
    show taskDetailProvider;

void main() {
  final fakeReminderRepo = _FakeReminderSettingsRepository();
  final fakeNotificationService = _FakeNotificationService();
  final fakeReminderHelper = TaskReminderHelper(
    fakeNotificationService,
    fakeReminderRepo,
  );

  late FakeFirebaseFirestore fakeFirestore;
  late EncryptionService encryptionService;
  late ProviderContainer container;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    FlutterSecureStorage.setMockInitialValues({});
    encryptionService = EncryptionService();
    await encryptionService.initialize();
    container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(fakeFirestore),
        taskRepositoryProvider.overrideWith(
          (ref) => FirebaseTaskRepository(
            ref.watch(firestoreProvider),
            encryptionService,
          ),
        ),
        reminderSettingsRepositoryProvider.overrideWithValue(fakeReminderRepo),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
        taskReminderHelperProvider.overrideWithValue(fakeReminderHelper),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TaskDetailNotifier', () {
    test('createSubtask adds a new subtask', () async {
      // Arrange
      final task = Task(
        id: 'task1',
        projectId: 'project1',
        title: 'Test Task',
        assignees: const ['user1'],
        createdAt: DateTime.now(),
      );

      await fakeFirestore.collection('tasks').doc('task1').set(task.toFirestore());

      // Listen to keep provider alive and wait for task to load
      final subscription = container.listen(
        taskDetailProvider('task1'),
        (previous, next) {},
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(taskDetailProvider('task1').notifier);

      // Act
      await notifier.createSubtask(
        id: 'subtask1',
        title: 'New Subtask',
      );

      // Assert
      final doc = await fakeFirestore.collection('subtasks').doc('subtask1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['title'], equals('New Subtask'));

      subscription.close();
    });

    test('updateSubtask modifies subtask', () async {
      // Arrange
      final task = Task(
        id: 'task1',
        projectId: 'project1',
        title: 'Test Task',
        assignees: const ['user1'],
        createdAt: DateTime.now(),
      );

      await fakeFirestore.collection('tasks').doc('task1').set(task.toFirestore());

      final subtask = Subtask(
        id: 'subtask1',
        taskId: 'task1',
        title: 'Original Title',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await fakeFirestore
          .collection('subtasks')
          .doc('subtask1')
          .set(subtask.toFirestore());

      final notifier = container.read(taskDetailProvider('task1').notifier);

      // Act
      final updatedSubtask = subtask.copyWith(title: 'Updated Title');
      await notifier.updateSubtask(updatedSubtask);

      // Assert
      final doc = await fakeFirestore.collection('subtasks').doc('subtask1').get();
      expect(doc.data()!['title'], equals('Updated Title'));
    });

    test('deleteSubtask removes subtask', () async {
      // Arrange
      final task = Task(
        id: 'task1',
        projectId: 'project1',
        title: 'Test Task',
        assignees: const ['user1'],
        createdAt: DateTime.now(),
      );

      await fakeFirestore.collection('tasks').doc('task1').set(task.toFirestore());

      final subtask = Subtask(
        id: 'subtask1',
        taskId: 'task1',
        title: 'To Delete',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await fakeFirestore
          .collection('subtasks')
          .doc('subtask1')
          .set(subtask.toFirestore());

      final notifier = container.read(taskDetailProvider('task1').notifier);

      // Act
      await notifier.deleteSubtask('subtask1');

      // Assert
      final doc = await fakeFirestore.collection('subtasks').doc('subtask1').get();
      expect(doc.exists, isFalse);
    });

    test('toggleSubtaskCompletion changes completion status', () async {
      // Arrange
      final task = Task(
        id: 'task1',
        projectId: 'project1',
        title: 'Test Task',
        assignees: const ['user1'],
        createdAt: DateTime.now(),
      );

      await fakeFirestore.collection('tasks').doc('task1').set(task.toFirestore());

      final subtask = Subtask(
        id: 'subtask1',
        taskId: 'task1',
        title: 'Toggle Me',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await fakeFirestore
          .collection('subtasks')
          .doc('subtask1')
          .set(subtask.toFirestore());

      final notifier = container.read(taskDetailProvider('task1').notifier);

      // Act
      await notifier.toggleSubtaskCompletion('subtask1');

      // Assert
      final doc = await fakeFirestore.collection('subtasks').doc('subtask1').get();
      expect(doc.data()!['isCompleted'], isTrue);
    });

    test('updateTask modifies the task', () async {
      // Arrange
      final task = Task(
        id: 'task1',
        projectId: 'project1',
        title: 'Original Title',
        assignees: const ['user1'],
        createdAt: DateTime.now(),
      );

      await fakeFirestore.collection('tasks').doc('task1').set(task.toFirestore());

      final notifier = container.read(taskDetailProvider('task1').notifier);

      // Act
      final updatedTask = task.copyWith(title: 'Updated Title');
      await notifier.updateTask(updatedTask);

      // Assert
      final doc = await fakeFirestore.collection('tasks').doc('task1').get();
      expect(doc.data()!['title'], equals('Updated Title'));
    });

    test('updateTaskStatus changes task status', () async {
      // Arrange
      final task = Task(
        id: 'task1',
        projectId: 'project1',
        title: 'Test Task',
        status: TaskStatus.pending,
        assignees: const ['user1'],
        createdAt: DateTime.now(),
      );

      await fakeFirestore.collection('tasks').doc('task1').set(task.toFirestore());

      // Listen to keep provider alive and wait for task to load
      final subscription = container.listen(
        taskDetailProvider('task1'),
        (previous, next) {},
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(taskDetailProvider('task1').notifier);

      // Act
      await notifier.updateTaskStatus(TaskStatus.inProgress);

      // Assert
      final doc = await fakeFirestore.collection('tasks').doc('task1').get();
      expect(doc.data()!['status'], equals('inProgress'));

      subscription.close();
    });
  });
}

class _FakeNotificationService implements NotificationService {
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
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async =>
      const [];

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => const [];
}

class _FakeReminderSettingsRepository implements ReminderSettingsRepository {
  ReminderSettings _settings = ReminderSettings.defaults;
  final _controller = StreamController<ReminderSettings>.broadcast();

  _FakeReminderSettingsRepository() {
    _controller.add(_settings);
  }

  @override
  ReminderSettings getCurrentSettings() => _settings;

  @override
  Stream<ReminderSettings> watchSettings() => _controller.stream;

  @override
  Future<void> saveSettings(ReminderSettings settings) async {
    _settings = settings;
    _controller.add(_settings);
  }

  @override
  Future<void> resetToDefaults() async {
    _settings = ReminderSettings.defaults;
    _controller.add(_settings);
  }
}

