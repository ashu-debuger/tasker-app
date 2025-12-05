import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tasker/src/core/providers/providers.dart';
import 'package:tasker/src/features/routines/domain/models/routine.dart';
import 'package:tasker/src/features/routines/domain/repositories/routine_repository.dart';
import 'package:tasker/src/features/routines/domain/helpers/routine_notification_helper.dart';

part 'routine_notifier.g.dart';

@riverpod
class RoutineNotifier extends _$RoutineNotifier {
  late final RoutineRepository _repository;
  late final RoutineNotificationHelper _notificationHelper;
  late String _userId;

  @override
  Stream<List<Routine>> build(String userId) {
    _userId = userId;
    _repository = ref.watch(routineRepositoryProvider);
    final notificationService = ref.watch(notificationServiceProvider);
    final reminderSettingsRepo = ref.watch(reminderSettingsRepositoryProvider);
    _notificationHelper = RoutineNotificationHelper(
      notificationService,
      reminderSettingsRepo,
    );
    return _repository.streamRoutinesForUser(userId);
  }

  Future<void> createRoutine({
    required String title,
    String? description,
    required RoutineFrequency frequency,
    List<int>? daysOfWeek,
    String? timeOfDay,
    bool isActive = true,
    bool reminderEnabled = false,
    int reminderMinutesBefore = 15,
  }) async {
    final routine = Routine(
      id: '', // Firestore will generate
      userId: _userId,
      title: title,
      description: description,
      frequency: frequency,
      daysOfWeek: daysOfWeek ?? [],
      timeOfDay: timeOfDay,
      isActive: isActive,
      reminderEnabled: reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore,
      createdAt: DateTime.now(),
    );

    final createdRoutine = await _repository.createRoutine(routine);

    if (createdRoutine.reminderEnabled) {
      await _notificationHelper.scheduleRoutineNotification(createdRoutine);
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    await _repository.updateRoutine(routine);

    // Reschedule notification
    await _notificationHelper.rescheduleRoutineNotification(routine);
  }

  Future<void> deleteRoutine(String routineId) async {
    // Cancel notification first
    await _notificationHelper.cancelRoutineNotification(routineId);

    await _repository.deleteRoutine(routineId);
  }

  Future<void> toggleRoutineActive(String routineId) async {
    await _repository.toggleRoutineActive(routineId);
    final routine = await _repository.getRoutineById(routineId);
    if (routine == null) return;

    if (routine.isActive) {
      await _notificationHelper.scheduleRoutineNotification(routine);
    } else {
      await _notificationHelper.cancelRoutineNotification(routineId);
    }
  }
}

@riverpod
class TodaysRoutines extends _$TodaysRoutines {
  late final RoutineRepository _repository;
  late String _userId;

  @override
  Future<List<Routine>> build(String userId) async {
    _userId = userId;
    _repository = ref.watch(routineRepositoryProvider);
    return _repository.getActiveRoutinesToday(userId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getActiveRoutinesToday(_userId),
    );
  }
}
