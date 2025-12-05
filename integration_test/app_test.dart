import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tasker/src/core/providers/providers.dart';
import 'package:tasker/src/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:tasker/src/features/auth/presentation/notifiers/auth_notifier.dart'
    show authProvider;
import 'package:tasker/src/features/projects/data/repositories/firebase_project_repository.dart';
import 'package:tasker/src/features/projects/domain/models/project.dart';
import 'package:tasker/src/features/projects/presentation/notifiers/project_list_notifier.dart'
    show projectListProvider;
import 'package:tasker/src/features/tasks/data/repositories/firebase_task_repository.dart';
import 'package:tasker/src/features/tasks/domain/models/task.dart';

/// Integration tests validating end-to-end workflows with mocked Firebase services.
/// These tests verify that repositories, notifiers, and business logic work correctly together.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late ProviderContainer container;

  setUp(() {
    mockAuth = MockFirebaseAuth(signedIn: false);
    fakeFirestore = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        firestoreProvider.overrideWithValue(fakeFirestore),
        authRepositoryProvider.overrideWith(
          (ref) => FirebaseAuthRepository(
            firebaseAuth: ref.watch(firebaseAuthProvider),
            firestore: ref.watch(firestoreProvider),
          ),
        ),
        projectRepositoryProvider.overrideWith(
          (ref) => FirebaseProjectRepository(ref.watch(firestoreProvider)),
        ),
        taskRepositoryProvider.overrideWith(
          (ref) => FirebaseTaskRepository(
            ref.watch(firestoreProvider),
            ref.watch(encryptionServiceProvider),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Integration Tests: Sign In Flow & Project Creation', () {
    test(
      'Complete user workflow: sign up -> create project -> create task',
      () async {
        // Step 1: Sign up a new user
        final authNotifier = container.read(authProvider.notifier);

        await authNotifier.signUp(
          email: 'integration@test.com',
          password: 'password123',
          displayName: 'Integration Test User',
        );

        // Verify user is signed in
        final authState = container.read(authProvider);
        expect(authState.hasValue, isTrue);
        expect(authState.value?.email, equals('integration@test.com'));
        expect(authState.value?.displayName, equals('Integration Test User'));

        // Step 2: Create a project
        final projectNotifier = container.read(projectListProvider.notifier);

        await projectNotifier.createProject(
          id: 'integration-test-project-1',
          name: 'Integration Test Project',
          description: 'A project created during integration testing',
        );

        // Verify project was created in Firestore
        final projectDoc = await fakeFirestore
            .collection('projects')
            .doc('integration-test-project-1')
            .get();

        expect(projectDoc.exists, isTrue);
        final projectData = projectDoc.data()!;
        expect(projectData['name'], equals('Integration Test Project'));
        expect(
          projectData['description'],
          equals('A project created during integration testing'),
        );

        final projectId = projectDoc.id;

        // Step 3: Create a task in the project
        final taskRepository = container.read(taskRepositoryProvider);

        final task = Task(
          id: 'test-task-1',
          projectId: projectId,
          title: 'Integration Test Task',
          description: 'A task created during integration testing',
          assignees: [authState.value!.id],
          createdAt: DateTime.now(),
        );

        await taskRepository.createTask(task);

        // Verify task was created
        final taskDoc = await fakeFirestore
            .collection('tasks')
            .doc('test-task-1')
            .get();

        expect(taskDoc.exists, isTrue);
        expect(taskDoc.data()!['title'], equals('Integration Test Task'));
        expect(taskDoc.data()!['projectId'], equals(projectId));

        // Step 4: Sign out
        await authNotifier.signOut();

        // Verify user is signed out
        final finalAuthState = container.read(authProvider);
        expect(finalAuthState.value, isNull);
      },
    );

    test('Data persistence: existing user can access their projects', () async {
      // Pre-create a user in the mock auth
      final mockUser = MockUser(
        uid: 'existing-user-123',
        email: 'existing@test.com',
        displayName: 'Existing User',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);

      // Recreate container with updated mock auth
      container.dispose();
      container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firestoreProvider.overrideWithValue(fakeFirestore),
          authRepositoryProvider.overrideWith(
            (ref) => FirebaseAuthRepository(
              firebaseAuth: ref.watch(firebaseAuthProvider),
              firestore: ref.watch(firestoreProvider),
            ),
          ),
          projectRepositoryProvider.overrideWith(
            (ref) => FirebaseProjectRepository(ref.watch(firestoreProvider)),
          ),
          taskRepositoryProvider.overrideWith(
            (ref) => FirebaseTaskRepository(
              ref.watch(firestoreProvider),
              ref.watch(encryptionServiceProvider),
            ),
          ),
        ],
      );

      // Pre-create user document
      await fakeFirestore.collection('users').doc('existing-user-123').set({
        'id': 'existing-user-123',
        'email': 'existing@test.com',
        'displayName': 'Existing User',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Pre-create a project for this user
      final project = Project(
        id: 'existing-project-123',
        name: 'Existing Project',
        description: 'A pre-existing project',
        members: ['existing-user-123'],
        ownerId: 'existing-user-123',
        memberRoles: const {'existing-user-123': 'owner'},
        createdAt: DateTime.now(),
      );

      await fakeFirestore
          .collection('projects')
          .doc('existing-project-123')
          .set(project.toFirestore());

      // Sign in the existing user
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.signIn(
        email: 'existing@test.com',
        password: 'password123',
      );

      // Verify user is signed in
      final authState = container.read(authProvider);
      expect(authState.value?.id, equals('existing-user-123'));

      // Verify the user can access their project
      final projectRepository = container.read(projectRepositoryProvider);
      final retrievedProject = await projectRepository.getProjectById(
        'existing-project-123',
      );

      expect(retrievedProject, isNotNull);
      expect(retrievedProject!.name, equals('Existing Project'));
      expect(retrievedProject.description, equals('A pre-existing project'));
      expect(retrievedProject.members, contains('existing-user-123'));
    });

    test(
      'Multi-user collaboration: project members can access shared project',
      () async {
        // Create first user
        await fakeFirestore.collection('users').doc('user-1').set({
          'id': 'user-1',
          'email': 'user1@test.com',
          'displayName': 'User One',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        // Create a shared project
        final projectRepository = container.read(projectRepositoryProvider);
        final project = Project(
          id: 'shared-project-123',
          name: 'Shared Project',
          description: 'A project shared between multiple users',
          members: ['user-1', 'user-2'], // Both users are members
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner', 'user-2': 'member'},
          createdAt: DateTime.now(),
        );

        await fakeFirestore
            .collection('projects')
            .doc('shared-project-123')
            .set(project.toFirestore());

        // Verify project has both members
        final retrievedProject = await projectRepository.getProjectById(
          'shared-project-123',
        );
        expect(retrievedProject, isNotNull);
        expect(retrievedProject!.members, contains('user-1'));
        expect(retrievedProject.members, contains('user-2'));
      },
    );
  });
}
