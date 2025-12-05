import '../models/routine.dart';

/// Repository interface for routine operations
abstract class RoutineRepository {
  /// Get a routine by ID
  Future<Routine?> getRoutineById(String routineId);

  /// Stream all routines for a user
  Stream<List<Routine>> streamRoutinesForUser(String userId);

  /// Get active routines for today
  Future<List<Routine>> getActiveRoutinesToday(String userId);

  /// Create a new routine and return the stored instance (with generated ID)
  Future<Routine> createRoutine(Routine routine);

  /// Update an existing routine
  Future<void> updateRoutine(Routine routine);

  /// Delete a routine
  Future<void> deleteRoutine(String routineId);

  /// Toggle routine active status
  Future<void> toggleRoutineActive(String routineId);
}
