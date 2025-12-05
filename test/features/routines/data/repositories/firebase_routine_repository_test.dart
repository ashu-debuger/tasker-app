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

  group('FirebaseRoutineRepository', () {
    test('creates and retrieves a routine', () async {
      // Arrange
      final routine = Routine(
        id: 'routine1',
        userId: 'user1',
        title: 'Morning Exercise',
        description: 'Daily workout routine',
        frequency: RoutineFrequency.daily,
        timeOfDay: '07:00',
        createdAt: DateTime.now(),
      );

      // Act
      final created = await repository.createRoutine(routine);
      final retrieved = await repository.getRoutineById(created.id);

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, created.id);
      expect(retrieved.title, 'Morning Exercise');
      expect(retrieved.frequency, RoutineFrequency.daily);
      expect(retrieved.isActive, true);
    });

    test('updates a routine', () async {
      // Arrange
      final routine = Routine(
        id: 'routine2',
        userId: 'user1',
        title: 'Evening Reading',
        frequency: RoutineFrequency.daily,
        createdAt: DateTime.now(),
      );
      final created = await repository.createRoutine(routine);

      // Act
      final updated = created.copyWith(
        title: 'Night Reading',
        timeOfDay: '21:00',
      );
      await repository.updateRoutine(updated);
      final retrieved = await repository.getRoutineById(created.id);

      // Assert
      expect(retrieved!.title, 'Night Reading');
      expect(retrieved.timeOfDay, '21:00');
      expect(retrieved.updatedAt, isNotNull);
    });

    test('deletes a routine', () async {
      // Arrange
      final routine = Routine(
        id: 'routine3',
        userId: 'user1',
        title: 'Delete Me',
        createdAt: DateTime.now(),
      );
      final created = await repository.createRoutine(routine);

      // Act
      await repository.deleteRoutine(created.id);
      final retrieved = await repository.getRoutineById(created.id);

      // Assert
      expect(retrieved, isNull);
    });

    test('streams routines for user', () async {
      // Arrange
      final routine1 = Routine(
        id: 'routine4',
        userId: 'user1',
        title: 'User1 Routine 1',
        createdAt: DateTime.now(),
      );
      final routine2 = Routine(
        id: 'routine5',
        userId: 'user1',
        title: 'User1 Routine 2',
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
      );
      final routine3 = Routine(
        id: 'routine6',
        userId: 'user2',
        title: 'User2 Routine',
        createdAt: DateTime.now(),
      );

      await repository.createRoutine(routine1);
      await repository.createRoutine(routine2);
      await repository.createRoutine(routine3);

      // Act
      final routines = await repository.streamRoutinesForUser('user1').first;

      // Assert
      expect(routines.length, 2);
      expect(routines.every((r) => r.userId == 'user1'), true);
      expect(routines.first.title, 'User1 Routine 2');
      expect(routines.last.title, 'User1 Routine 1');
    });

    test('toggles routine active status', () async {
      // Arrange
      final routine = Routine(
        id: 'routine7',
        userId: 'user1',
        title: 'Toggle Me',
        isActive: true,
        createdAt: DateTime.now(),
      );
      final created = await repository.createRoutine(routine);

      // Act
      await repository.toggleRoutineActive(created.id);
      final retrieved = await repository.getRoutineById(created.id);

      // Assert
      expect(retrieved!.isActive, false);
      expect(retrieved.updatedAt, isNotNull);
    });

    test('gets active routines for today - daily frequency', () async {
      // Arrange
      final activeDaily = Routine(
        id: 'routine8',
        userId: 'user1',
        title: 'Active Daily',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime.now(),
      );
      final inactiveDaily = Routine(
        id: 'routine9',
        userId: 'user1',
        title: 'Inactive Daily',
        frequency: RoutineFrequency.daily,
        isActive: false,
        createdAt: DateTime.now(),
      );

      await repository.createRoutine(activeDaily);
      await repository.createRoutine(inactiveDaily);

      // Act
      final todaysRoutines = await repository.getActiveRoutinesToday('user1');

      // Assert
      expect(todaysRoutines.length, 1);
      expect(todaysRoutines.first.title, 'Active Daily');
    });

    test('gets active routines for today - weekly frequency matching today', () async {
      // Arrange
      final today = DateTime.now().weekday; // 1=Monday, 7=Sunday
      
      final matchingWeekly = Routine(
        id: 'routine10',
        userId: 'user1',
        title: 'Matching Weekly',
        frequency: RoutineFrequency.weekly,
        daysOfWeek: [today],
        isActive: true,
        createdAt: DateTime.now(),
      );
      final nonMatchingWeekly = Routine(
        id: 'routine11',
        userId: 'user1',
        title: 'Non-matching Weekly',
        frequency: RoutineFrequency.weekly,
        daysOfWeek: [today == 7 ? 1 : today + 1], // Different day
        isActive: true,
        createdAt: DateTime.now(),
      );

      await repository.createRoutine(matchingWeekly);
      await repository.createRoutine(nonMatchingWeekly);

      // Act
      final todaysRoutines = await repository.getActiveRoutinesToday('user1');

      // Assert
      expect(todaysRoutines.length, 1);
      expect(todaysRoutines.first.title, 'Matching Weekly');
    });

    test('gets active routines for today - custom frequency with multiple days', () async {
      // Arrange
      final today = DateTime.now().weekday;
      final tomorrow = today == 7 ? 1 : today + 1;
      
      final customRoutine = Routine(
        id: 'routine12',
        userId: 'user1',
        title: 'Custom Routine',
        frequency: RoutineFrequency.custom,
        daysOfWeek: [today, tomorrow],
        isActive: true,
        createdAt: DateTime.now(),
      );

      await repository.createRoutine(customRoutine);

      // Act
      final todaysRoutines = await repository.getActiveRoutinesToday('user1');

      // Assert
      expect(todaysRoutines.length, 1);
      expect(todaysRoutines.first.title, 'Custom Routine');
    });

    test('returns null when routine does not exist', () async {
      // Act
      final routine = await repository.getRoutineById('nonexistent');

      // Assert
      expect(routine, isNull);
    });

    test('preserves all fields when creating routine', () async {
      // Arrange
      final routine = Routine(
        id: 'routine13',
        userId: 'user1',
        title: 'Complete Routine',
        description: 'Full description',
        frequency: RoutineFrequency.weekly,
        daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
        timeOfDay: '09:30',
        isActive: true,
        createdAt: DateTime(2025, 1, 1, 10, 0),
      );

      // Act
      final created = await repository.createRoutine(routine);
      final retrieved = await repository.getRoutineById(created.id);

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.userId, 'user1');
      expect(retrieved.title, 'Complete Routine');
      expect(retrieved.description, 'Full description');
      expect(retrieved.frequency, RoutineFrequency.weekly);
      expect(retrieved.daysOfWeek, [1, 3, 5]);
      expect(retrieved.timeOfDay, '09:30');
      expect(retrieved.isActive, true);
      expect(retrieved.createdAt.year, 2025);
    });
  });

  group('Routine Model', () {
    test('shouldRunToday returns true for daily routine when active', () {
      final routine = Routine(
        id: 'test',
        userId: 'user1',
        title: 'Test',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(routine.shouldRunToday(), true);
    });

    test('shouldRunToday returns false when routine is inactive', () {
      final routine = Routine(
        id: 'test',
        userId: 'user1',
        title: 'Test',
        frequency: RoutineFrequency.daily,
        isActive: false,
        createdAt: DateTime.now(),
      );

      expect(routine.shouldRunToday(), false);
    });

    test('shouldRunToday checks daysOfWeek for weekly routine', () {
      final today = DateTime.now().weekday;
      final tomorrow = today == 7 ? 1 : today + 1;

      final routineToday = Routine(
        id: 'test1',
        userId: 'user1',
        title: 'Test',
        frequency: RoutineFrequency.weekly,
        daysOfWeek: [today],
        isActive: true,
        createdAt: DateTime.now(),
      );

      final routineTomorrow = Routine(
        id: 'test2',
        userId: 'user1',
        title: 'Test',
        frequency: RoutineFrequency.weekly,
        daysOfWeek: [tomorrow],
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(routineToday.shouldRunToday(), true);
      expect(routineTomorrow.shouldRunToday(), false);
    });

    test('empty routine has correct default values', () {
      expect(Routine.empty.id, '');
      expect(Routine.empty.userId, '');
      expect(Routine.empty.title, '');
      expect(Routine.empty.isEmpty, true);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Routine(
        id: 'test',
        userId: 'user1',
        title: 'Original',
        frequency: RoutineFrequency.daily,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        title: 'Updated',
        isActive: false,
      );

      expect(updated.title, 'Updated');
      expect(updated.isActive, false);
      expect(updated.id, 'test'); // Unchanged
      expect(updated.userId, 'user1'); // Unchanged
    });
  });
}
