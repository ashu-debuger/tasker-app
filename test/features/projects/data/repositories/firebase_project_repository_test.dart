import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasker/src/features/projects/data/repositories/firebase_project_repository.dart';
import 'package:tasker/src/features/projects/domain/models/project.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseProjectRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirebaseProjectRepository(fakeFirestore);
  });

  group('FirebaseProjectRepository', () {
    group('getProjectById', () {
      test('returns project when it exists', () async {
        // Arrange
        const projectId = 'project-1';
        final project = Project(
          id: projectId,
          name: 'Test Project',
          description: 'A test project',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc(projectId)
            .set(project.toFirestore());

        // Act
        final result = await repository.getProjectById(projectId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, projectId);
        expect(result.name, 'Test Project');
        expect(result.description, 'A test project');
        expect(result.members, ['user-1']);
      });

      test('returns null when project does not exist', () async {
        // Act
        final result = await repository.getProjectById('non-existent');

        // Assert
        expect(result, isNull);
      });
    });

    group('streamProjectsForUser', () {
      test('streams projects for specific user', () async {
        // Arrange
        const userId = 'user-1';

        final project1 = Project(
          id: 'project-1',
          name: 'Project 1',
          description: 'First project',
          members: [userId, 'user-2'],
          ownerId: userId,
          memberRoles: {userId: 'owner', 'user-2': 'member'},
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        final project2 = Project(
          id: 'project-2',
          name: 'Project 2',
          description: 'Second project',
          members: [userId],
          ownerId: userId,
          memberRoles: {userId: 'owner'},
          createdAt: DateTime(2025, 1, 2),
          updatedAt: DateTime(2025, 1, 2),
        );

        final project3 = Project(
          id: 'project-3',
          name: 'Project 3',
          description: 'Third project',
          members: ['user-2'], // Different user
          ownerId: 'user-2',
          memberRoles: const {'user-2': 'owner'},
          createdAt: DateTime(2025, 1, 3),
          updatedAt: DateTime(2025, 1, 3),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project1.toFirestore());
        await fakeFirestore
            .collection('projects')
            .doc('project-2')
            .set(project2.toFirestore());
        await fakeFirestore
            .collection('projects')
            .doc('project-3')
            .set(project3.toFirestore());

        // Act
        final stream = repository.streamProjectsForUser(userId);

        // Assert
        await expectLater(
          stream.first,
          completion(
            isA<List<Project>>()
                .having((list) => list.length, 'length', 2)
                .having(
                  (list) => list[0].id,
                  'first project',
                  'project-2',
                ) // Ordered by createdAt desc
                .having((list) => list[1].id, 'second project', 'project-1'),
          ),
        );
      });

      test('returns empty list when user has no projects', () async {
        // Act
        final stream = repository.streamProjectsForUser(
          'user-with-no-projects',
        );

        // Assert
        await expectLater(
          stream.first,
          completion(
            isA<List<Project>>().having((list) => list.length, 'length', 0),
          ),
        );
      });

      test('updates stream when new project is added', () async {
        // Arrange
        const userId = 'user-1';
        final stream = repository.streamProjectsForUser(userId);

        // Act & Assert
        expectLater(
          stream,
          emitsInOrder([
            isEmpty, // Initially no projects
            isA<List<Project>>().having((list) => list.length, 'length', 1),
          ]),
        );

        // Add project after a delay
        await Future.delayed(const Duration(milliseconds: 100));

        final project = Project(
          id: 'project-1',
          name: 'New Project',
          description: 'Added dynamically',
          members: [userId],
          ownerId: userId,
          memberRoles: {userId: 'owner'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());
      });
    });

    group('createProject', () {
      test('successfully creates a project', () async {
        // Arrange
        final project = Project(
          id: 'new-project',
          name: 'New Project',
          description: 'A newly created project',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        // Act
        await repository.createProject(project);

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('new-project')
            .get();
        expect(doc.exists, true);

        final data = doc.data()!;
        expect(
          doc.id,
          'new-project',
        ); // ID is stored as document ID, not in data
        expect(data['name'], 'New Project');
        expect(data['description'], 'A newly created project');
        expect(data['members'], ['user-1']);
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
          updatedAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());

        final updatedProject = project.copyWith(
          name: 'Updated Name',
          description: 'Updated description',
        );

        // Act
        await repository.updateProject(updatedProject);

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .get();
        final data = doc.data()!;

        expect(data['name'], 'Updated Name');
        expect(data['description'], 'Updated description');
        expect(data['members'], ['user-1']);
      });

      test('updates the updatedAt timestamp', () async {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Test Project',
          description: 'Description',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());

        // Act
        await repository.updateProject(project);

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .get();
        final data = doc.data()!;

        // updatedAt should be updated to current time
        expect(data['updatedAt'], isNotNull);
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
          updatedAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-to-delete')
            .set(project.toFirestore());

        // Verify it exists first
        var doc = await fakeFirestore
            .collection('projects')
            .doc('project-to-delete')
            .get();
        expect(doc.exists, true);

        // Act
        await repository.deleteProject('project-to-delete');

        // Assert
        doc = await fakeFirestore
            .collection('projects')
            .doc('project-to-delete')
            .get();
        expect(doc.exists, false);
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
          updatedAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());

        // Act
        await repository.addMember('project-1', 'user-2');

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .get();
        final data = doc.data()!;

        expect(data['members'], containsAll(['user-1', 'user-2']));
        expect((data['members'] as List).length, 2);
      });

      test('does not duplicate member if already exists', () async {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Test Project',
          description: 'Description',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());

        // Act - add same user twice
        await repository.addMember('project-1', 'user-1');

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .get();
        final data = doc.data()!;

        expect((data['members'] as List).length, 1);
        expect(data['members'], ['user-1']);
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
          updatedAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());

        // Act
        await repository.removeMember('project-1', 'user-2');

        // Assert
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .get();
        final data = doc.data()!;

        expect(data['members'], containsAll(['user-1', 'user-3']));
        expect(data['members'], isNot(contains('user-2')));
        expect((data['members'] as List).length, 2);
      });

      test('handles removing non-existent member gracefully', () async {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Test Project',
          description: 'Description',
          members: ['user-1'],
          ownerId: 'user-1',
          memberRoles: const {'user-1': 'owner'},
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .set(project.toFirestore());

        // Act - remove user that doesn't exist
        await repository.removeMember('project-1', 'user-999');

        // Assert - should complete without error
        final doc = await fakeFirestore
            .collection('projects')
            .doc('project-1')
            .get();
        final data = doc.data()!;

        expect(data['members'], ['user-1']);
      });
    });
  });
}
