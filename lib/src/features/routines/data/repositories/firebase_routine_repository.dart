import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../domain/models/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../../../core/utils/app_logger.dart';

/// Firebase implementation of RoutineRepository
class FirebaseRoutineRepository implements RoutineRepository {
  final FirebaseFirestore _firestore;
  static const _logTag = '[Routine:Repo]';

  FirebaseRoutineRepository(this._firestore);

  /// Collection reference for routines
  CollectionReference get _routinesCollection =>
      _firestore.collection('routines');

  @override
  Future<Routine?> getRoutineById(String routineId) async {
    appLogger.d('$_logTag getRoutineById routineId=$routineId');
    try {
      final doc = await logTimedAsync(
        '$_logTag getRoutineDoc $routineId',
        () => _routinesCollection.doc(routineId).get(),
        level: Level.debug,
      );
      if (!doc.exists) return null;
      appLogger.i('$_logTag getRoutineById success routineId=$routineId');
      return Routine.fromFirestore(doc);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getRoutineById failed routineId=$routineId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Routine>> streamRoutinesForUser(String userId) {
    try {
      appLogger.d('$_logTag streamRoutinesForUser subscribed userId=$userId');
      return _routinesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) {
              final routines = snapshot.docs
                  .map((doc) => Routine.fromFirestore(doc))
                  .toList();
              appLogger.d(
                '$_logTag streamRoutinesForUser snapshot=${routines.length} userId=$userId',
              );
              return routines;
            },
          );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamRoutinesForUser failed userId=$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Routine>> getActiveRoutinesToday(String userId) async {
    appLogger.d('$_logTag getActiveRoutinesToday userId=$userId');
    try {
      final snapshot = await logTimedAsync(
        '$_logTag getActiveRoutines query userId=$userId',
        () => _routinesCollection
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .get(),
        level: Level.debug,
      );

      final routines = snapshot.docs
          .map((doc) => Routine.fromFirestore(doc))
          .toList();

      // Filter routines that should run today
      final today = routines.where((routine) => routine.shouldRunToday()).toList();
      appLogger.i(
        '$_logTag getActiveRoutinesToday success total=${today.length} userId=$userId',
      );
      return today;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getActiveRoutinesToday failed userId=$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<Routine> createRoutine(Routine routine) async {
    appLogger.i('$_logTag createRoutine requested userId=${routine.userId}');
    try {
      final docRef = _routinesCollection.doc();
      final routineWithId = routine.copyWith(id: docRef.id);
      await logTimedAsync(
        '$_logTag createRoutine write routineId=${routineWithId.id}',
        () => docRef.set(routineWithId.toFirestore()),
      );
      appLogger.i('$_logTag createRoutine success routineId=${routineWithId.id}');
      return routineWithId;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag createRoutine failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateRoutine(Routine routine) async {
    appLogger.i('$_logTag updateRoutine routineId=${routine.id}');
    try {
      final updatedRoutine = routine.copyWith(updatedAt: DateTime.now());
      await logTimedAsync(
        '$_logTag updateRoutine write routineId=${routine.id}',
        () => _routinesCollection.doc(routine.id).update(
              updatedRoutine.toFirestore(),
            ),
      );
      appLogger.i('$_logTag updateRoutine success routineId=${routine.id}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag updateRoutine failed routineId=${routine.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    appLogger.w('$_logTag deleteRoutine routineId=$routineId');
    try {
      await logTimedAsync(
        '$_logTag deleteRoutine write routineId=$routineId',
        () => _routinesCollection.doc(routineId).delete(),
      );
      appLogger.i('$_logTag deleteRoutine success routineId=$routineId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteRoutine failed routineId=$routineId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> toggleRoutineActive(String routineId) async {
    appLogger.i('$_logTag toggleRoutineActive routineId=$routineId');
    try {
      final routine = await getRoutineById(routineId);
      if (routine == null) return;

      final updatedRoutine = routine.copyWith(
        isActive: !routine.isActive,
        updatedAt: DateTime.now(),
      );

      await logTimedAsync(
        '$_logTag toggleRoutineActive write routineId=$routineId',
        () => _routinesCollection.doc(routineId).update(
              updatedRoutine.toFirestore(),
            ),
      );
      appLogger.i(
        '$_logTag toggleRoutineActive success routineId=$routineId isActive=${updatedRoutine.isActive}',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag toggleRoutineActive failed routineId=$routineId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
