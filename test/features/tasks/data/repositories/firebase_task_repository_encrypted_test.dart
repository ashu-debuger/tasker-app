import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:tasker/src/features/tasks/data/repositories/firebase_task_repository.dart';
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

  group('FirebaseTaskRepository - Task Description Encryption', () {
    test('encrypts task description when isDescriptionEncrypted is true', () async {
      // Arrange
      final task = Task(
        id: 'task1',
        projectId: 'project1',
        title: 'Secret Task',
        description: 'This is a secret description',
        isDescriptionEncrypted: true,
        assignees: const [],
        createdAt: DateTime.now(),
      );

      // Act
      await repository.createTask(task);

      // Assert
      final doc = await fakeFirestore.collection('tasks').doc('task1').get();
      expect(doc.exists, true);
      expect(doc.data()?['isDescriptionEncrypted'], true);
      expect(doc.data()?['description'], isNot('This is a secret description'));
      expect(doc.data()?['description'], isNotEmpty);
    });

    test('does not encrypt task description when isDescriptionEncrypted is false', () async {
      // Arrange
      final task = Task(
        id: 'task2',
        projectId: 'project1',
        title: 'Regular Task',
        description: 'This is a plain description',
        isDescriptionEncrypted: false,
        assignees: const [],
        createdAt: DateTime.now(),
      );

      // Act
      await repository.createTask(task);

      // Assert
      final doc = await fakeFirestore.collection('tasks').doc('task2').get();
      expect(doc.exists, true);
      expect(doc.data()?['isDescriptionEncrypted'], false);
      expect(doc.data()?['description'], 'This is a plain description');
    });

    test('decrypts encrypted task description when retrieving by ID', () async {
      // Arrange
      const plainDescription = 'Secret project details';
      final encryptedDesc = await encryptionService.encrypt(plainDescription);
      
      final taskData = {
        'projectId': 'project1',
        'title': 'Encrypted Task',
        'description': encryptedDesc,
        'isDescriptionEncrypted': true,
        'status': 'pending',
        'assignees': [],
        'createdAt': DateTime.now(),
        'updatedAt': null,
        'dueDate': null,
      };
      
      await fakeFirestore.collection('tasks').doc('task3').set(taskData);

      // Act
      final task = await repository.getTaskById('task3');

      // Assert
      expect(task, isNotNull);
      expect(task!.description, plainDescription);
      expect(task.isDescriptionEncrypted, true);
    });

    test('handles decryption failure gracefully when retrieving task', () async {
      // Arrange - Invalid encrypted data
      final taskData = {
        'projectId': 'project1',
        'title': 'Corrupted Task',
        'description': 'invalid-encrypted-data',
        'isDescriptionEncrypted': true,
        'status': 'pending',
        'assignees': [],
        'createdAt': DateTime.now(),
        'updatedAt': null,
        'dueDate': null,
      };
      
      await fakeFirestore.collection('tasks').doc('task4').set(taskData);

      // Act
      final task = await repository.getTaskById('task4');

      // Assert
      expect(task, isNotNull);
      expect(task!.description, '[Unable to decrypt description]');
      expect(task.isDescriptionEncrypted, true);
    });

    test('encrypts task description when updating', () async {
      // Arrange - Create initial task
      final initialTask = Task(
        id: 'task5',
        projectId: 'project1',
        title: 'Task to Update',
        description: 'Initial description',
        isDescriptionEncrypted: false,
        assignees: const [],
        createdAt: DateTime.now(),
      );
      await repository.createTask(initialTask);

      // Act - Update with encrypted description
      final updatedTask = initialTask.copyWith(
        description: 'New encrypted description',
        isDescriptionEncrypted: true,
      );
      await repository.updateTask(updatedTask);

      // Assert
      final doc = await fakeFirestore.collection('tasks').doc('task5').get();
      expect(doc.data()?['isDescriptionEncrypted'], true);
      expect(doc.data()?['description'], isNot('New encrypted description'));
      expect(doc.data()?['description'], isNotEmpty);
      expect(doc.data()?['updatedAt'], isNotNull);
    });

    test('streams and decrypts encrypted task descriptions', () async {
      // Arrange - Create mix of encrypted and plain tasks
      const plainDesc1 = 'Secret task 1';
      const plainDesc2 = 'Secret task 2';
      final encrypted1 = await encryptionService.encrypt(plainDesc1);
      final encrypted2 = await encryptionService.encrypt(plainDesc2);

      await fakeFirestore.collection('tasks').doc('task6').set({
        'projectId': 'project1',
        'title': 'Encrypted 1',
        'description': encrypted1,
        'isDescriptionEncrypted': true,
        'status': 'pending',
        'assignees': [],
        'createdAt': DateTime.now(),
        'updatedAt': null,
        'dueDate': null,
      });

      await fakeFirestore.collection('tasks').doc('task7').set({
        'projectId': 'project1',
        'title': 'Plain Task',
        'description': 'Plain description',
        'isDescriptionEncrypted': false,
        'status': 'pending',
        'assignees': [],
        'createdAt': DateTime.now(),
        'updatedAt': null,
        'dueDate': null,
      });

      await fakeFirestore.collection('tasks').doc('task8').set({
        'projectId': 'project1',
        'title': 'Encrypted 2',
        'description': encrypted2,
        'isDescriptionEncrypted': true,
        'status': 'pending',
        'assignees': [],
        'createdAt': DateTime.now(),
        'updatedAt': null,
        'dueDate': null,
      });

      // Act
      final tasks = await repository.streamTasksForProject('project1').first;

      // Assert
      expect(tasks.length, 3);
      
      final encryptedTasks = tasks.where((t) => t.isDescriptionEncrypted).toList();
      expect(encryptedTasks.length, 2);
      expect(encryptedTasks.any((t) => t.description == plainDesc1), true);
      expect(encryptedTasks.any((t) => t.description == plainDesc2), true);

      final plainTask = tasks.firstWhere((t) => !t.isDescriptionEncrypted);
      expect(plainTask.description, 'Plain description');
    });

    test('round-trip: create encrypted task and retrieve decrypted', () async {
      // Arrange
      const secretDesc = 'Highly confidential task information';
      final task = Task(
        id: 'task9',
        projectId: 'project1',
        title: 'Confidential Task',
        description: secretDesc,
        isDescriptionEncrypted: true,
        assignees: const ['user1'],
        createdAt: DateTime.now(),
      );

      // Act - Create and retrieve
      await repository.createTask(task);
      final retrieved = await repository.getTaskById('task9');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.description, secretDesc);
      expect(retrieved.isDescriptionEncrypted, true);
      expect(retrieved.title, task.title);
      expect(retrieved.assignees, task.assignees);
    });

    test('handles task with null description and encryption flag', () async {
      // Arrange
      final task = Task(
        id: 'task10',
        projectId: 'project1',
        title: 'No Description Task',
        description: null,
        isDescriptionEncrypted: true,
        assignees: const [],
        createdAt: DateTime.now(),
      );

      // Act
      await repository.createTask(task);
      final retrieved = await repository.getTaskById('task10');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.description, null);
      expect(retrieved.isDescriptionEncrypted, true);
    });

    test('preserves encryption state when updating non-description fields', () async {
      // Arrange - Create encrypted task
      final task = Task(
        id: 'task11',
        projectId: 'project1',
        title: 'Original Title',
        description: 'Secret description',
        isDescriptionEncrypted: true,
        assignees: const [],
        createdAt: DateTime.now(),
      );
      await repository.createTask(task);

      // Act - Update only title (not description)
      final updatedTask = task.copyWith(title: 'Updated Title');
      await repository.updateTask(updatedTask);

      // Assert
      final retrieved = await repository.getTaskById('task11');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Updated Title');
      expect(retrieved.description, 'Secret description');
      expect(retrieved.isDescriptionEncrypted, true);
    });
  });
}
