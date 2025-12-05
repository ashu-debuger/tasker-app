import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasker/src/features/tasks/data/repositories/firebase_task_repository.dart';
import 'package:tasker/src/features/tasks/domain/models/subtask.dart';
import 'package:tasker/src/features/tasks/domain/models/task.dart';
import 'package:tasker/src/core/encryption/encryption_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late EncryptionService encryptionService;
  late FirebaseTaskRepository repository;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    FlutterSecureStorage.setMockInitialValues({});
    encryptionService = EncryptionService();
    await encryptionService.initialize();
    repository = FirebaseTaskRepository(fakeFirestore, encryptionService);
  });

  group('FirebaseTaskRepository - Task Operations', () {
    group('getTaskById', () {
      test('returns task when it exists', () async {
        // Arrange
        const taskId = 'task-1';
        final task = Task(
          id: taskId,
          projectId: 'project-1',
          title: 'Test Task',
          description: 'A test task',
          status: TaskStatus.pending,
          assignees: ['user-1'],
          createdAt: DateTime(2025, 1, 1),
          dueDate: DateTime(2025, 1, 15),
        );

        await fakeFirestore.collection('tasks').doc(taskId).set(task.toFirestore());

        // Act
        final result = await repository.getTaskById(taskId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, taskId);
        expect(result.title, 'Test Task');
        expect(result.description, 'A test task');
        expect(result.status, TaskStatus.pending);
        expect(result.projectId, 'project-1');
      });

      test('returns null when task does not exist', () async {
        // Act
        final result = await repository.getTaskById('non-existent');

        // Assert
        expect(result, isNull);
      });
    });

    group('streamTasksForProject', () {
      test('streams tasks for specific project', () async {
        // Arrange
        const projectId = 'project-1';

        final task1 = Task(
          id: 'task-1',
          projectId: projectId,
          title: 'Task 1',
          description: 'First task',
          status: TaskStatus.pending,
          assignees: ['user-1'],
          createdAt: DateTime(2025, 1, 1),
        );

        final task2 = Task(
          id: 'task-2',
          projectId: projectId,
          title: 'Task 2',
          description: 'Second task',
          status: TaskStatus.inProgress,
          assignees: ['user-2'],
          createdAt: DateTime(2025, 1, 2),
        );

        final task3 = Task(
          id: 'task-3',
          projectId: 'project-2', // Different project
          title: 'Task 3',
          description: 'Third task',
          status: TaskStatus.completed,
          assignees: ['user-1'],
          createdAt: DateTime(2025, 1, 3),
        );

        await fakeFirestore.collection('tasks').doc('task-1').set(task1.toFirestore());
        await fakeFirestore.collection('tasks').doc('task-2').set(task2.toFirestore());
        await fakeFirestore.collection('tasks').doc('task-3').set(task3.toFirestore());

        // Act
        final stream = repository.streamTasksForProject(projectId);

        // Assert
        await expectLater(
          stream.first,
          completion(isA<List<Task>>()
              .having((list) => list.length, 'length', 2)
              .having((list) => list[0].id, 'first task', 'task-2') // Ordered by createdAt desc
              .having((list) => list[1].id, 'second task', 'task-1')),
        );
      });

      test('returns empty list when project has no tasks', () async {
        // Act
        final stream = repository.streamTasksForProject('empty-project');

        // Assert
        await expectLater(
          stream.first,
          completion(isEmpty),
        );
      });
    });

    group('createTask', () {
      test('successfully creates a task', () async {
        // Arrange
        final task = Task(
          id: 'new-task',
          projectId: 'project-1',
          title: 'New Task',
          description: 'A newly created task',
          status: TaskStatus.pending,
          assignees: ['user-1'],
          createdAt: DateTime(2025, 1, 1),
        );

        // Act
        await repository.createTask(task);

        // Assert
        final doc = await fakeFirestore.collection('tasks').doc('new-task').get();
        expect(doc.exists, true);

        final data = doc.data()!;
        expect(data['projectId'], 'project-1');
        expect(data['title'], 'New Task');
        expect(data['description'], 'A newly created task');
        expect(data['status'], 'pending');
      });
    });

    group('updateTask', () {
      test('successfully updates a task', () async {
        // Arrange
        final task = Task(
          id: 'task-1',
          projectId: 'project-1',
          title: 'Original Title',
          description: 'Original description',
          status: TaskStatus.pending,
          assignees: ['user-1'],
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore.collection('tasks').doc('task-1').set(task.toFirestore());

        final updatedTask = task.copyWith(
          title: 'Updated Title',
          status: TaskStatus.inProgress,
        );

        // Act
        await repository.updateTask(updatedTask);

        // Assert
        final doc = await fakeFirestore.collection('tasks').doc('task-1').get();
        final data = doc.data()!;

        expect(data['title'], 'Updated Title');
        expect(data['status'], 'inProgress');
        expect(data['updatedAt'], isNotNull);
      });
    });

    group('deleteTask', () {
      test('successfully deletes a task', () async {
        // Arrange
        final task = Task(
          id: 'task-to-delete',
          projectId: 'project-1',
          title: 'Delete Me',
          description: 'This will be deleted',
          status: TaskStatus.pending,
          assignees: ['user-1'],
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore.collection('tasks').doc('task-to-delete').set(task.toFirestore());

        // Verify it exists
        var doc = await fakeFirestore.collection('tasks').doc('task-to-delete').get();
        expect(doc.exists, true);

        // Act
        await repository.deleteTask('task-to-delete');

        // Assert
        doc = await fakeFirestore.collection('tasks').doc('task-to-delete').get();
        expect(doc.exists, false);
      });

      test('deletes task and all its subtasks', () async {
        // Arrange
        final task = Task(
          id: 'task-1',
          projectId: 'project-1',
          title: 'Task with Subtasks',
          description: 'Has subtasks',
          status: TaskStatus.pending,
          assignees: ['user-1'],
          createdAt: DateTime(2025, 1, 1),
        );

        final subtask1 = Subtask(
          id: 'subtask-1',
          taskId: 'task-1',
          title: 'Subtask 1',
          isCompleted: false,
          createdAt: DateTime(2025, 1, 1),
        );

        final subtask2 = Subtask(
          id: 'subtask-2',
          taskId: 'task-1',
          title: 'Subtask 2',
          isCompleted: false,
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore.collection('tasks').doc('task-1').set(task.toFirestore());
        await fakeFirestore.collection('subtasks').doc('subtask-1').set(subtask1.toFirestore());
        await fakeFirestore.collection('subtasks').doc('subtask-2').set(subtask2.toFirestore());

        // Act
        await repository.deleteTask('task-1');

        // Assert - task should be deleted
        final taskDoc = await fakeFirestore.collection('tasks').doc('task-1').get();
        expect(taskDoc.exists, false);

        // Assert - subtasks should be deleted
        final subtask1Doc = await fakeFirestore.collection('subtasks').doc('subtask-1').get();
        final subtask2Doc = await fakeFirestore.collection('subtasks').doc('subtask-2').get();
        expect(subtask1Doc.exists, false);
        expect(subtask2Doc.exists, false);
      });
    });
  });

  group('FirebaseTaskRepository - Subtask Operations', () {
    group('getSubtaskById', () {
      test('returns subtask when it exists', () async {
        // Arrange
        const subtaskId = 'subtask-1';
        final subtask = Subtask(
          id: subtaskId,
          taskId: 'task-1',
          title: 'Test Subtask',
          isCompleted: false,
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore.collection('subtasks').doc(subtaskId).set(subtask.toFirestore());

        // Act
        final result = await repository.getSubtaskById(subtaskId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, subtaskId);
        expect(result.title, 'Test Subtask');
        expect(result.taskId, 'task-1');
        expect(result.isCompleted, false);
      });

      test('returns null when subtask does not exist', () async {
        // Act
        final result = await repository.getSubtaskById('non-existent');

        // Assert
        expect(result, isNull);
      });
    });

    group('streamSubtasksForTask', () {
      test('streams subtasks for specific task', () async {
        // Arrange
        const taskId = 'task-1';

        final subtask1 = Subtask(
          id: 'subtask-1',
          taskId: taskId,
          title: 'Subtask 1',
          isCompleted: false,
          createdAt: DateTime(2025, 1, 1),
        );

        final subtask2 = Subtask(
          id: 'subtask-2',
          taskId: taskId,
          title: 'Subtask 2',
          isCompleted: true,
          createdAt: DateTime(2025, 1, 2),
        );

        final subtask3 = Subtask(
          id: 'subtask-3',
          taskId: 'task-2', // Different task
          title: 'Subtask 3',
          isCompleted: false,
          createdAt: DateTime(2025, 1, 3),
        );

        await fakeFirestore.collection('subtasks').doc('subtask-1').set(subtask1.toFirestore());
        await fakeFirestore.collection('subtasks').doc('subtask-2').set(subtask2.toFirestore());
        await fakeFirestore.collection('subtasks').doc('subtask-3').set(subtask3.toFirestore());

        // Act
        final stream = repository.streamSubtasksForTask(taskId);

        // Assert
        await expectLater(
          stream.first,
          completion(isA<List<Subtask>>()
              .having((list) => list.length, 'length', 2)
              .having((list) => list[0].id, 'first subtask', 'subtask-1') // Ordered by createdAt asc
              .having((list) => list[1].id, 'second subtask', 'subtask-2')),
        );
      });

      test('returns empty list when task has no subtasks', () async {
        // Act
        final stream = repository.streamSubtasksForTask('empty-task');

        // Assert
        await expectLater(
          stream.first,
          completion(isEmpty),
        );
      });
    });

    group('createSubtask', () {
      test('successfully creates a subtask', () async {
        // Arrange
        final subtask = Subtask(
          id: 'new-subtask',
          taskId: 'task-1',
          title: 'New Subtask',
          isCompleted: false,
          createdAt: DateTime(2025, 1, 1),
        );

        // Act
        await repository.createSubtask(subtask);

        // Assert
        final doc = await fakeFirestore.collection('subtasks').doc('new-subtask').get();
        expect(doc.exists, true);

        final data = doc.data()!;
        expect(data['taskId'], 'task-1');
        expect(data['title'], 'New Subtask');
        expect(data['isCompleted'], false);
      });
    });

    group('updateSubtask', () {
      test('successfully updates a subtask', () async {
        // Arrange
        final subtask = Subtask(
          id: 'subtask-1',
          taskId: 'task-1',
          title: 'Original Title',
          isCompleted: false,
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore.collection('subtasks').doc('subtask-1').set(subtask.toFirestore());

        final updatedSubtask = subtask.copyWith(
          title: 'Updated Title',
          isCompleted: true,
        );

        // Act
        await repository.updateSubtask(updatedSubtask);

        // Assert
        final doc = await fakeFirestore.collection('subtasks').doc('subtask-1').get();
        final data = doc.data()!;

        expect(data['title'], 'Updated Title');
        expect(data['isCompleted'], true);
        expect(data['updatedAt'], isNotNull);
      });
    });

    group('deleteSubtask', () {
      test('successfully deletes a subtask', () async {
        // Arrange
        final subtask = Subtask(
          id: 'subtask-to-delete',
          taskId: 'task-1',
          title: 'Delete Me',
          isCompleted: false,
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore.collection('subtasks').doc('subtask-to-delete').set(subtask.toFirestore());

        // Verify it exists
        var doc = await fakeFirestore.collection('subtasks').doc('subtask-to-delete').get();
        expect(doc.exists, true);

        // Act
        await repository.deleteSubtask('subtask-to-delete');

        // Assert
        doc = await fakeFirestore.collection('subtasks').doc('subtask-to-delete').get();
        expect(doc.exists, false);
      });
    });

    group('toggleSubtaskCompletion', () {
      test('toggles subtask from incomplete to complete', () async {
        // Arrange
        final subtask = Subtask(
          id: 'subtask-1',
          taskId: 'task-1',
          title: 'Toggle Me',
          isCompleted: false,
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore.collection('subtasks').doc('subtask-1').set(subtask.toFirestore());

        // Act
        await repository.toggleSubtaskCompletion('subtask-1');

        // Assert
        final doc = await fakeFirestore.collection('subtasks').doc('subtask-1').get();
        final data = doc.data()!;
        expect(data['isCompleted'], true);
      });

      test('toggles subtask from complete to incomplete', () async {
        // Arrange
        final subtask = Subtask(
          id: 'subtask-1',
          taskId: 'task-1',
          title: 'Toggle Me',
          isCompleted: true,
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore.collection('subtasks').doc('subtask-1').set(subtask.toFirestore());

        // Act
        await repository.toggleSubtaskCompletion('subtask-1');

        // Assert
        final doc = await fakeFirestore.collection('subtasks').doc('subtask-1').get();
        final data = doc.data()!;
        expect(data['isCompleted'], false);
      });

      test('handles non-existent subtask gracefully', () async {
        // Act & Assert - should not throw
        await repository.toggleSubtaskCompletion('non-existent');
        expect(true, true);
      });
    });
  });
}
