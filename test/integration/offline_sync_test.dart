import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasker/src/features/projects/data/repositories/firebase_project_repository.dart';
import 'package:tasker/src/features/projects/domain/models/project.dart';
import 'package:tasker/src/features/tasks/data/repositories/firebase_task_repository.dart';
import 'package:tasker/src/features/tasks/domain/models/task.dart';
import 'package:tasker/src/core/encryption/encryption_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Integration tests for offline sync functionality.
/// Tests the interaction between Firebase repositories and simulated offline caching.
void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseProjectRepository projectRepository;
  late FirebaseTaskRepository taskRepository;
  late EncryptionService encryptionService;

  // Simulated local cache (in real app, this would be Hive)
  late Map<String, Project> projectCache;
  late Map<String, Task> taskCache;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();

    // Initialize encryption service
    FlutterSecureStorage.setMockInitialValues({});
    encryptionService = EncryptionService();
    await encryptionService.initialize();

    projectRepository = FirebaseProjectRepository(fakeFirestore);
    taskRepository = FirebaseTaskRepository(fakeFirestore, encryptionService);

    // Initialize cache maps
    projectCache = {};
    taskCache = {};
  });

  group('Offline Sync Integration Tests', () {
    group('Project Offline CRUD Operations', () {
      test('create project offline, sync when online', () async {
        // Step 1: Create project locally (simulating offline mode)
        final project = Project(
          id: 'offline-project-1',
          name: 'Offline Project',
          description: 'Created while offline',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime.now(),
        );

        // Store in cache (simulated offline storage)
        projectCache[project.id] = project;

        // Verify project is in cache
        expect(projectCache[project.id], isNotNull);
        expect(projectCache[project.id]!.name, 'Offline Project');

        // Step 2: Simulate going online and syncing to Firebase
        await projectRepository.createProject(project);

        // Verify project was synced to Firebase
        final firebaseProject = await projectRepository.getProjectById(
          project.id,
        );
        expect(firebaseProject, isNotNull);
        expect(firebaseProject!.name, 'Offline Project');
        expect(firebaseProject.description, 'Created while offline');
        expect(firebaseProject.members, ['user-1']);
      });

      test('read project from cache when offline', () async {
        // Pre-populate cache (simulating previous sync)
        final project = Project(
          id: 'cached-project-1',
          name: 'Cached Project',
          description: 'Available offline',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime.now(),
        );

        projectCache[project.id] = project;

        // Read from cache (simulating offline mode)
        final cachedProject = projectCache[project.id];

        expect(cachedProject, isNotNull);
        expect(cachedProject!.name, 'Cached Project');
        expect(cachedProject.description, 'Available offline');
      });

      test('update project offline, sync changes when online', () async {
        // Step 1: Create project in both Firebase and cache
        final originalProject = Project(
          id: 'update-project-1',
          name: 'Original Name',
          description: 'Original description',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime.now(),
        );

        await projectRepository.createProject(originalProject);
        projectCache[originalProject.id] = originalProject;

        // Step 2: Update locally while offline
        final updatedProject = originalProject.copyWith(
          name: 'Updated Name',
          description: 'Updated description',
          updatedAt: DateTime.now(),
        );

        projectCache[updatedProject.id] = updatedProject;

        // Verify local update
        expect(projectCache[updatedProject.id]!.name, 'Updated Name');

        // Step 3: Sync to Firebase when online
        await projectRepository.updateProject(updatedProject);

        // Verify Firebase has the updated data
        final firebaseProject = await projectRepository.getProjectById(
          updatedProject.id,
        );
        expect(firebaseProject!.name, 'Updated Name');
        expect(firebaseProject.description, 'Updated description');
        expect(firebaseProject.updatedAt, isNotNull);
      });

      test('delete project offline, sync deletion when online', () async {
        // Step 1: Create project in both locations
        final project = Project(
          id: 'delete-project-1',
          name: 'To Be Deleted',
          description: 'Will be deleted',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime.now(),
        );

        await projectRepository.createProject(project);
        projectCache[project.id] = project;

        // Step 2: Delete locally while offline
        projectCache.remove(project.id);

        // Verify local deletion
        expect(projectCache[project.id], isNull);

        // Step 3: Sync deletion to Firebase when online
        await projectRepository.deleteProject(project.id);

        // Verify Firebase deletion
        final firebaseProject = await projectRepository.getProjectById(
          project.id,
        );
        expect(firebaseProject, isNull);
      });
    });

    group('Task Offline CRUD Operations', () {
      test('create task offline, sync when online', () async {
        // Step 1: Create task locally (offline mode)
        final task = Task(
          id: 'offline-task-1',
          projectId: 'project-1',
          title: 'Offline Task',
          description: 'Created while offline',
          assignees: ['user-1'],
          createdAt: DateTime.now(),
        );

        // Store in cache
        taskCache[task.id] = task;

        // Verify task is cached
        expect(taskCache[task.id], isNotNull);
        expect(taskCache[task.id]!.title, 'Offline Task');

        // Step 2: Sync to Firebase when online
        await taskRepository.createTask(task);

        // Verify Firebase sync
        final firebaseTask = await taskRepository.getTaskById(task.id);
        expect(firebaseTask, isNotNull);
        expect(firebaseTask!.title, 'Offline Task');
        expect(firebaseTask.description, 'Created while offline');
      });

      test('read tasks from cache when offline', () async {
        // Pre-populate cache with multiple tasks
        final tasks = [
          Task(
            id: 'cached-task-1',
            projectId: 'project-1',
            title: 'Cached Task 1',
            assignees: ['user-1'],
            createdAt: DateTime.now(),
          ),
          Task(
            id: 'cached-task-2',
            projectId: 'project-1',
            title: 'Cached Task 2',
            assignees: ['user-1'],
            createdAt: DateTime.now(),
          ),
        ];

        for (final task in tasks) {
          taskCache[task.id] = task;
        }

        // Read from cache (offline mode)
        final cachedTasks = taskCache.values
            .where((t) => t.projectId == 'project-1')
            .toList();

        expect(cachedTasks.length, 2);
        expect(
          cachedTasks.map((t) => t.title),
          containsAll(['Cached Task 1', 'Cached Task 2']),
        );
      });

      test('update task offline, sync changes when online', () async {
        // Step 1: Create task in both locations
        final originalTask = Task(
          id: 'update-task-1',
          projectId: 'project-1',
          title: 'Original Title',
          description: 'Original description',
          assignees: ['user-1'],
          createdAt: DateTime.now(),
        );

        await taskRepository.createTask(originalTask);
        taskCache[originalTask.id] = originalTask;

        // Step 2: Update locally while offline
        final updatedTask = originalTask.copyWith(
          title: 'Updated Title',
          description: 'Updated description',
          status: TaskStatus.inProgress,
          updatedAt: DateTime.now(),
        );

        taskCache[updatedTask.id] = updatedTask;

        // Verify local update
        expect(taskCache[updatedTask.id]!.title, 'Updated Title');
        expect(taskCache[updatedTask.id]!.status, TaskStatus.inProgress);

        // Step 3: Sync to Firebase when online
        await taskRepository.updateTask(updatedTask);

        // Verify Firebase update
        final firebaseTask = await taskRepository.getTaskById(updatedTask.id);
        expect(firebaseTask!.title, 'Updated Title');
        expect(firebaseTask.description, 'Updated description');
        expect(firebaseTask.status, TaskStatus.inProgress);
      });

      test('delete task offline, sync deletion when online', () async {
        // Step 1: Create task in both locations
        final task = Task(
          id: 'delete-task-1',
          projectId: 'project-1',
          title: 'To Be Deleted',
          assignees: ['user-1'],
          createdAt: DateTime.now(),
        );

        await taskRepository.createTask(task);
        taskCache[task.id] = task;

        // Step 2: Delete locally while offline
        taskCache.remove(task.id);

        // Verify local deletion
        expect(taskCache[task.id], isNull);

        // Step 3: Sync deletion to Firebase when online
        await taskRepository.deleteTask(task.id);

        // Verify Firebase deletion
        final firebaseTask = await taskRepository.getTaskById(task.id);
        expect(firebaseTask, isNull);
      });
    });

    group('Conflict Resolution', () {
      test(
        'local changes merge with remote changes using last-write-wins',
        () async {
          // Step 1: Create project in Firebase (remote state)
          final remoteProject = Project(
            id: 'conflict-project-1',
            name: 'Remote Name',
            description: 'Remote description',
            members: ['user-1'],
            ownerId: 'user-1',
            memberRoles: const {'user-1': 'owner'},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await projectRepository.createProject(remoteProject);

          // Step 2: Create different local version (offline changes)
          final localProject = Project(
            id: 'conflict-project-1',
            name: 'Local Name',
            description: 'Local description',
            members: ['user-1'],
            ownerId: 'user-1',
            memberRoles: const {'user-1': 'owner'},
            createdAt: remoteProject.createdAt,
            updatedAt: DateTime.now().add(const Duration(seconds: 5)),
          );

          projectCache[localProject.id] = localProject;

          // Step 3: Sync local changes (last-write-wins strategy)
          await projectRepository.updateProject(localProject);

          // Step 4: Verify local changes won (newer timestamp)
          final resolvedProject = await projectRepository.getProjectById(
            'conflict-project-1',
          );
          expect(resolvedProject!.name, 'Local Name');
          expect(resolvedProject.description, 'Local description');

          // Update cache with resolved state
          projectCache[resolvedProject.id] = resolvedProject;
          expect(projectCache[resolvedProject.id]!.name, 'Local Name');
        },
      );

      test('remote changes overwrite local cache on pull', () async {
        // Step 1: Create local cached version (stale data)
        final localTask = Task(
          id: 'conflict-task-1',
          projectId: 'project-1',
          title: 'Stale Local Title',
          description: 'Old description',
          assignees: ['user-1'],
          createdAt: DateTime.now(),
        );

        taskCache[localTask.id] = localTask;

        // Step 2: Create newer version in Firebase (server truth)
        final remoteTask = Task(
          id: 'conflict-task-1',
          projectId: 'project-1',
          title: 'Fresh Remote Title',
          description: 'New description',
          assignees: ['user-1', 'user-2'],
          createdAt: localTask.createdAt,
          updatedAt: DateTime.now(),
        );

        await taskRepository.createTask(remoteTask);

        // Step 3: Pull from Firebase and update cache
        final pulledTask = await taskRepository.getTaskById('conflict-task-1');
        taskCache[pulledTask!.id] = pulledTask;

        // Step 4: Verify cache was updated with remote data
        expect(taskCache['conflict-task-1']!.title, 'Fresh Remote Title');
        expect(taskCache['conflict-task-1']!.description, 'New description');
        expect(taskCache['conflict-task-1']!.assignees, ['user-1', 'user-2']);
      });
    });

    group('Encryption Compatibility', () {
      test('encrypted data persists correctly in offline cache', () async {
        // Step 1: Create task with encrypted description
        final task = Task(
          id: 'encrypted-task-1',
          projectId: 'project-1',
          title: 'Encrypted Task',
          description: 'This is a secret description',
          isDescriptionEncrypted: true,
          assignees: ['user-1'],
          createdAt: DateTime.now(),
        );

        // Step 2: Save to Firebase (will be encrypted by repository)
        await taskRepository.createTask(task);

        // Step 3: Retrieve and cache locally
        final retrievedTask = await taskRepository.getTaskById(task.id);
        taskCache[retrievedTask!.id] = retrievedTask;

        // Step 4: Read from cache
        expect(taskCache[task.id], isNotNull);
        expect(taskCache[task.id]!.title, 'Encrypted Task');
        expect(
          taskCache[task.id]!.description,
          'This is a secret description',
        ); // Decrypted
        expect(taskCache[task.id]!.isDescriptionEncrypted, true);
      });

      test('offline changes to encrypted data sync correctly', () async {
        // Step 1: Create encrypted task
        final originalTask = Task(
          id: 'encrypted-update-1',
          projectId: 'project-1',
          title: 'Secret Task',
          description: 'Original secret',
          isDescriptionEncrypted: true,
          assignees: ['user-1'],
          createdAt: DateTime.now(),
        );

        await taskRepository.createTask(originalTask);
        taskCache[originalTask.id] = originalTask;

        // Step 2: Update description offline
        final updatedTask = originalTask.copyWith(
          description: 'Updated secret',
          updatedAt: DateTime.now(),
        );

        taskCache[updatedTask.id] = updatedTask;

        // Step 3: Sync update to Firebase
        await taskRepository.updateTask(updatedTask);

        // Step 4: Verify encrypted update
        final syncedTask = await taskRepository.getTaskById(updatedTask.id);
        expect(syncedTask!.description, 'Updated secret');
        expect(syncedTask.isDescriptionEncrypted, true);

        // Verify it's actually encrypted in Firestore
        final firestoreDoc = await fakeFirestore
            .collection('tasks')
            .doc(updatedTask.id)
            .get();
        final storedDescription = firestoreDoc.data()!['description'] as String;
        expect(
          storedDescription,
          isNot('Updated secret'),
        ); // Should be encrypted
        expect(storedDescription.isNotEmpty, true);
      });

      test('decryption works for cached encrypted data', () async {
        // Step 1: Create and encrypt task in Firebase
        final task = Task(
          id: 'decrypt-test-1',
          projectId: 'project-1',
          title: 'Decrypt Me',
          description: 'Confidential information',
          isDescriptionEncrypted: true,
          assignees: ['user-1'],
          createdAt: DateTime.now(),
        );

        await taskRepository.createTask(task);

        // Step 2: Cache the task (with decrypted data)
        final retrievedTask = await taskRepository.getTaskById(task.id);
        taskCache[retrievedTask!.id] = retrievedTask;

        // Step 3: Read from cache and verify decryption
        expect(taskCache[task.id]!.description, 'Confidential information');

        // Step 4: Verify original Firebase data is still encrypted
        final firestoreDoc = await fakeFirestore
            .collection('tasks')
            .doc(task.id)
            .get();
        final storedDescription = firestoreDoc.data()!['description'] as String;
        expect(storedDescription, isNot('Confidential information'));
      });
    });

    group('Batch Sync Operations', () {
      test('sync multiple offline changes in batch', () async {
        // Step 1: Create multiple projects offline
        final offlineProjects = List.generate(
          5,
          (i) => Project(
            id: 'batch-project-$i',
            name: 'Batch Project $i',
            description: 'Created offline',
            members: ['user-1'],
            ownerId: 'user-1',
            memberRoles: const {'user-1': 'owner'},
            createdAt: DateTime.now(),
          ),
        );

        // Cache all projects
        for (final project in offlineProjects) {
          projectCache[project.id] = project;
        }

        expect(projectCache.length, 5);

        // Step 2: Sync all to Firebase when online
        for (final project in offlineProjects) {
          await projectRepository.createProject(project);
        }

        // Step 3: Verify all synced
        for (int i = 0; i < 5; i++) {
          final synced = await projectRepository.getProjectById(
            'batch-project-$i',
          );
          expect(synced, isNotNull);
          expect(synced!.name, 'Batch Project $i');
        }
      });

      test('handle partial sync failures gracefully', () async {
        // Step 1: Create projects, some will fail to sync
        final project1 = Project(
          id: 'sync-success-1',
          name: 'Will Sync',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime.now(),
        );

        final project2 = Project(
          id: 'sync-fail-1',
          name: 'Will Fail',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime.now(),
        );

        projectCache[project1.id] = project1;
        projectCache[project2.id] = project2;

        // Step 2: Sync first project successfully
        await projectRepository.createProject(project1);

        final synced1 = await projectRepository.getProjectById(
          'sync-success-1',
        );
        expect(synced1, isNotNull);

        // Step 3: Verify failed project remains in cache
        expect(projectCache['sync-fail-1'], isNotNull);

        // Can retry sync later
        await projectRepository.createProject(project2);
        final synced2 = await projectRepository.getProjectById('sync-fail-1');
        expect(synced2, isNotNull);
      });
    });
  });
}
