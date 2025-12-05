import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasker/src/core/providers/providers.dart';
import 'package:tasker/src/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:tasker/src/features/auth/presentation/notifiers/auth_notifier.dart'
    show authProvider;
import 'package:tasker/src/features/projects/data/repositories/firebase_project_repository.dart';
import 'package:tasker/src/features/projects/domain/models/project.dart';
import 'package:tasker/src/features/projects/presentation/notifiers/project_list_notifier.dart'
    show projectListProvider;
import 'package:tasker/src/features/tasks/data/repositories/task_repository.dart';
import 'package:tasker/src/features/tasks/domain/models/task.dart';
import 'package:tasker/src/features/tasks/domain/models/subtask.dart';

class _FakeTaskRepository implements TaskRepository {
  final List<String> deletedProjects = [];

  @override
  Future<void> createSubtask(Subtask subtask) async {}

  @override
  Future<void> createTask(Task task) async {}

  @override
  Future<void> deleteSubtask(String subtaskId) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<void> deleteTasksForProject(String projectId) async {
    deletedProjects.add(projectId);
  }

  @override
  Future<Task?> getTaskById(String taskId) async => null;

  @override
  Future<List<Task>> getTasksByProject(String projectId) async => [];

  @override
  Future<Subtask?> getSubtaskById(String subtaskId) async => null;

  @override
  Future<void> toggleSubtaskCompletion(String subtaskId) async {}

  @override
  Future<void> updateSubtask(Subtask subtask) async {}

  @override
  Future<void> updateTask(Task task) async {}

  @override
  Stream<List<Task>> streamRecurringTaskInstances(
    String parentRecurringTaskId,
  ) => const Stream.empty();

  @override
  Stream<List<Subtask>> streamSubtasksForTask(String taskId) =>
      const Stream.empty();

  @override
  Stream<List<Task>> streamTasksForProject(String projectId) =>
      const Stream.empty();

  @override
  Stream<List<Task>> streamTasksForUser(String userId) => const Stream.empty();

  @override
  Stream<Task?> streamTaskById(String taskId) => const Stream.empty();

  @override
  Future<void> assignTask({
    required String taskId,
    required List<String> assigneeIds,
    required String assignedBy,
  }) async {}

  @override
  Future<void> unassignTask(String taskId) async {}

  @override
  Stream<List<Task>> streamTasksAssignedToUser({
    required String userId,
    String? projectId,
  }) => const Stream.empty();

  @override
  Stream<List<Task>> streamUnassignedTasks(String projectId) =>
      const Stream.empty();

  @override
  Stream<List<Task>> streamPersonalTasks(String userId) => const Stream.empty();
}

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late _FakeTaskRepository fakeTaskRepository;
  late ProviderContainer container;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    fakeTaskRepository = _FakeTaskRepository();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FirebaseAuthRepository(
            firebaseAuth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
        projectRepositoryProvider.overrideWithValue(
          FirebaseProjectRepository(fakeFirestore),
        ),
        taskRepositoryProvider.overrideWithValue(fakeTaskRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ProjectListNotifier', () {
    group('createProject', () {
      test('successfully creates a project for logged in user', () async {
        // Arrange
        final mockUser = MockUser(uid: 'user-1', email: 'test@example.com');
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FirebaseAuthRepository(
                firebaseAuth: mockAuth,
                firestore: fakeFirestore,
              ),
            ),
            projectRepositoryProvider.overrideWithValue(
              FirebaseProjectRepository(fakeFirestore),
            ),
            taskRepositoryProvider.overrideWithValue(fakeTaskRepository),
          ],
        );

        // Sign in to set up auth state
        final authNotifier = container.read(authProvider.notifier);
        await authNotifier.signIn(
          email: 'test@example.com',
          password: 'password',
        );

        final notifier = container.read(projectListProvider.notifier);

        // Act
        await notifier.createProject(
          id: 'new-project',
          name: 'New Project',
          description: 'A new project',
        );

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('new-project')
            .get();
        expect(doc.exists, true);

        final data = doc.data()!;
        expect(data['name'], 'New Project');
        expect(data['description'], 'A new project');
        expect(data['members'], ['user-1']);
      });

      test('throws exception when user is not logged in', () async {
        // Arrange - no user logged in
        final notifier = container.read(projectListProvider.notifier);

        // Act & Assert
        expect(
          () => notifier.createProject(id: 'project', name: 'Project'),
          throwsException,
        );
      });

      test('adds current user as first member', () async {
        // Arrange
        final mockUser = MockUser(
          uid: 'creator-id',
          email: 'creator@example.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FirebaseAuthRepository(
                firebaseAuth: mockAuth,
                firestore: fakeFirestore,
              ),
            ),
            projectRepositoryProvider.overrideWithValue(
              FirebaseProjectRepository(fakeFirestore),
            ),
            taskRepositoryProvider.overrideWithValue(fakeTaskRepository),
          ],
        );

        // Sign in to set up auth state
        final authNotifier = container.read(authProvider.notifier);
        await authNotifier.signIn(
          email: 'creator@example.com',
          password: 'password',
        );

        final notifier = container.read(projectListProvider.notifier);

        // Act
        await notifier.createProject(id: 'project', name: 'My Project');

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project')
            .get();
        final data = doc.data()!;
        expect(data['members'], ['creator-id']);
      });
    });

    group('updateProject', () {
      test('successfully updates a project', () async {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Original Name',
          description: 'Original description',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());

        final notifier = container.read(projectListProvider.notifier);

        final updatedProject = project.copyWith(
          name: 'Updated Name',
          description: 'Updated description',
        );

        // Act
        await notifier.updateProject(updatedProject);

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .get();
        final data = doc.data()!;

        expect(data['name'], 'Updated Name');
        expect(data['description'], 'Updated description');
      });
    });

    group('deleteProject', () {
      test('successfully deletes a project', () async {
        // Arrange
        final project = Project(
          id: 'project-to-delete',
          name: 'Delete Me',
          description: 'This will be deleted',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-to-delete')
            .set(project.toFirestore());

        final notifier = container.read(projectListProvider.notifier);

        // Verify it exists
        var doc = await fakeFirestore
            .collection('projects')
            .doc('project-to-delete')
            .get();
        expect(doc.exists, true);

        // Act
        await notifier.deleteProject('project-to-delete');

        // Assert
        doc = await fakeFirestore
            .collection('projects')
            .doc('project-to-delete')
            .get();
        expect(doc.exists, false);
        expect(
          fakeTaskRepository.deletedProjects,
          contains('project-to-delete'),
        );
      });
    });

    group('addMember', () {
      test('successfully adds a member to project', () async {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Test Project',
          description: 'Description',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());

        final notifier = container.read(projectListProvider.notifier);

        // Act
        await notifier.addMember('project-1', 'user-2');

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .get();
        final data = doc.data()!;

        expect(data['members'], containsAll(['user-1', 'user-2']));
      });
    });

    group('removeMember', () {
      test('successfully removes a member from project', () async {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Test Project',
          description: 'Description',
          members: ['user-1', 'user-2', 'user-3'],
          ownerId: 'user-1',
          memberRoles: const {
            'user-1': 'owner',
            'user-2': 'member',
            'user-3': 'member',
          },
          createdAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());

        final notifier = container.read(projectListProvider.notifier);

        // Act
        await notifier.removeMember('project-1', 'user-2');

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .get();
        final data = doc.data()!;

        expect(data['members'], containsAll(['user-1', 'user-3']));
        expect(data['members'], isNot(contains('user-2')));
      });
    });
  });
}
