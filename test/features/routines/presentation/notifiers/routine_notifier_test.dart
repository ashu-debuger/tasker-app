import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:tasker/src/features/routines/data/repositories/firebase_routine_repository.dart';
import 'package:tasker/src/features/routines/domain/models/routine.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseRoutineRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirebaseRoutineRepository(fakeFirestore);
  });

  group('RoutineNotifier - State Management', () {
    test('createRoutine should create a new routine', () async {
      final routine = Routine(
        id: '',
        userId: 'user1',
        title: 'Morning Workout',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine);

      final routines = await repository.streamRoutinesForUser('user1').first;
      expect(routines.length, 1);
      expect(routines.first.title, 'Morning Workout');
    });

    test('updateRoutine should update routine with new values', () async {
      final routine = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'Original Title',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine);
      final routines = await repository.streamRoutinesForUser('user1').first;
      final createdRoutine = routines.first;

      final updatedRoutine = createdRoutine.copyWith(
        title: 'Updated Title',
        frequency: RoutineFrequency.weekly,
        daysOfWeek: [1, 3, 5],
      );

      await repository.updateRoutine(updatedRoutine);

      final retrieved = await repository.getRoutineById(createdRoutine.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Updated Title');
      expect(retrieved.frequency, RoutineFrequency.weekly);
      expect(retrieved.daysOfWeek, [1, 3, 5]);
    });

    test('deleteRoutine should remove routine', () async {
      final routine = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'To Delete',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine);
      final routines = await repository.streamRoutinesForUser('user1').first;
      final createdRoutine = routines.first;

      await repository.deleteRoutine(createdRoutine.id);

      final afterDelete = await repository.streamRoutinesForUser('user1').first;
      expect(afterDelete.isEmpty, true);
    });

    test('toggleRoutineActive should flip isActive status', () async {
      final routine = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'Test Routine',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine);
      final routines = await repository.streamRoutinesForUser('user1').first;
      final createdRoutine = routines.first;

      await repository.toggleRoutineActive(createdRoutine.id);

      final retrieved = await repository.getRoutineById(createdRoutine.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.isActive, false);

      await repository.toggleRoutineActive(createdRoutine.id);
      final retrievedAgain = await repository.getRoutineById(createdRoutine.id);
      expect(retrievedAgain, isNotNull);
      expect(retrievedAgain!.isActive, true);
    });
  });

  group('RoutineNotifier - Today\'s Routines Filtering', () {
    test('getActiveRoutinesToday returns daily active routines', () async {
      final routine = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'Daily Routine',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine);

      final routines = await repository.getActiveRoutinesToday('user1');
      expect(routines.length, 1);
      expect(routines.first.title, 'Daily Routine');
    });

    test('getActiveRoutinesToday filters out weekly routines on wrong day', () async {
      final now = DateTime.now();
      final wrongDay = (now.weekday % 7) + 1; // Different day

      final routine = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'Weekly Routine',
        frequency: RoutineFrequency.weekly,
        daysOfWeek: [wrongDay],
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine);

      final routines = await repository.getActiveRoutinesToday('user1');
      expect(routines.isEmpty, true);
    });

    test('getActiveRoutinesToday includes weekly routines on correct day', () async {
      final today = DateTime.now().weekday;

      final routine = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'Weekly Routine',
        frequency: RoutineFrequency.weekly,
        daysOfWeek: [today],
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine);

      final routines = await repository.getActiveRoutinesToday('user1');
      expect(routines.length, 1);
      expect(routines.first.title, 'Weekly Routine');
    });

    test('getActiveRoutinesToday returns empty list for user with no routines', () async {
      final routines = await repository.getActiveRoutinesToday('user1');
      expect(routines.isEmpty, true);
    });

    test('getActiveRoutinesToday filters out inactive routines', () async {
      final routine = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'Inactive Routine',
        frequency: RoutineFrequency.daily,
        isActive: false,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine);

      final routines = await repository.getActiveRoutinesToday('user1');
      expect(routines.isEmpty, true);
    });
  });

  group('RoutineNotifier - Stream Operations', () {
    test('streamRoutinesForUser returns stream of routines', () async {
      final routine = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'Test Routine',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine);

      final stream = repository.streamRoutinesForUser('user1');
      final routines = await stream.first;

      expect(routines.length, 1);
      expect(routines.first.title, 'Test Routine');
    });

    test('streamRoutinesForUser filters by userId', () async {
      final routine1 = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'User 1 Routine',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      final routine2 = Routine(
        id: 'routine2',
        userId: 'user2',
        title: 'User 2 Routine',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime(2025, 11, 13),
      );

      await repository.createRoutine(routine1);
      await repository.createRoutine(routine2);

      final user1Routines = await repository.streamRoutinesForUser('user1').first;
      expect(user1Routines.length, 1);
      expect(user1Routines.first.title, 'User 1 Routine');
    });
  });

  group('RoutineNotifier - Error Handling', () {
    test('getRoutineById returns null when routine does not exist', () async {
      final result = await repository.getRoutineById('nonexistent');
      expect(result, isNull);
    });

    test('toggleRoutineActive handles nonexistent routine gracefully', () async {
      // With FakeFirebaseFirestore, this will just do nothing or return null
      // In a real Firebase scenario, this would be handled by security rules
      await repository.toggleRoutineActive('nonexistent');
      // No exception expected with fake
    });
  });
}
