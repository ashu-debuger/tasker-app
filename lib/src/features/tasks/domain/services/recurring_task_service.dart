import '../models/task.dart';
import '../../data/repositories/task_repository.dart';

import '../../../../core/utils/app_logger.dart';

/// Service for managing recurring task instances
class RecurringTaskService {
  final TaskRepository _taskRepository;
  static const _logTag = 'RecurringTaskService';

  RecurringTaskService(this._taskRepository);

  /// Generate the next instance of a recurring task
  /// Returns the created task instance, or null if no more instances should be created
  Future<Task?> createNextInstance(Task recurringTask) async {
    appLogger.d(
      '$_logTag createNextInstance requested taskId=${recurringTask.id}',
    );
    // Validate that this is a recurring task (not an instance)
    if (!recurringTask.isRecurring || recurringTask.dueDate == null) {
      appLogger.d(
        '$_logTag createNextInstance skipped - invalid recurrence taskId=${recurringTask.id}',
      );
      return null;
    }

    // Calculate next occurrence
    final nextDueDate = recurringTask.getNextOccurrence();
    if (nextDueDate == null) {
      // Recurrence has ended
      appLogger.i(
        '$_logTag createNextInstance ended recurrence taskId=${recurringTask.id}',
      );
      return null;
    }

    // Create the new task instance
    final newInstance = Task(
      id: '', // Firestore will generate
      projectId: recurringTask.projectId,
      title: recurringTask.title,
      description: recurringTask.description,
      isDescriptionEncrypted: recurringTask.isDescriptionEncrypted,
      dueDate: nextDueDate,
      status: TaskStatus.pending,
      assignees: recurringTask.assignees,
      createdAt: DateTime.now(),
      parentRecurringTaskId: recurringTask.id,
      reminderEnabled: recurringTask.reminderEnabled,
      // Instance does not inherit recurrence pattern
      recurrencePattern: RecurrencePattern.none,
      recurrenceInterval: 1,
    );

    try {
      await _taskRepository.createTask(newInstance);
      appLogger.i(
        '$_logTag created next instance parentId=${recurringTask.id} dueDate=$nextDueDate',
      );
      return newInstance;
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag failed to create next instance parentId=${recurringTask.id}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check all recurring tasks and create instances as needed
  /// Typically called when:
  /// 1. A recurring task instance is completed
  /// 2. The app starts (to generate any missed instances)
  /// 3. Periodically in the background
  Future<List<Task>> generatePendingInstances(
    String projectId, {
    int lookaheadDays = 30,
  }) async {
    appLogger.d(
      '$_logTag generatePendingInstances projectId=$projectId lookaheadDays=$lookaheadDays',
    );
    final tasks = await _taskRepository.getTasksByProject(projectId);

    // Filter for recurring tasks only
    final recurringTasks = tasks.where((task) => task.isRecurring).toList();

    final createdInstances = <Task>[];
    final now = DateTime.now();
    final lookaheadDate = now.add(Duration(days: lookaheadDays));

    for (final recurringTask in recurringTasks) {
      if (recurringTask.dueDate == null) continue;
      appLogger.d(
        '$_logTag processing recurring taskId=${recurringTask.id}',
      );

      // Find existing instances for this recurring task
      final existingInstances = tasks
          .where((t) => t.parentRecurringTaskId == recurringTask.id)
          .toList();

      // Sort by due date descending to find the latest instance
      existingInstances.sort(
        (a, b) => (b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );

      // Determine the base date for generating next instances
      DateTime currentDate;
      if (existingInstances.isNotEmpty &&
          existingInstances.first.dueDate != null) {
        currentDate = existingInstances.first.dueDate!;
      } else {
        currentDate = recurringTask.dueDate!;
      }

      // Generate instances up to the lookahead date
      var tempTask = recurringTask.copyWith(dueDate: currentDate);
      while (true) {
        final nextDate = tempTask.getNextOccurrence();
        if (nextDate == null || nextDate.isAfter(lookaheadDate)) {
          break;
        }

        // Check if an instance for this date already exists
        final instanceExists = existingInstances.any((instance) {
          if (instance.dueDate == null) return false;
          return instance.dueDate!.year == nextDate.year &&
              instance.dueDate!.month == nextDate.month &&
              instance.dueDate!.day == nextDate.day;
        });

        if (!instanceExists) {
          // Create the instance
          final newInstance = Task(
            id: '', // Firestore will generate
            projectId: recurringTask.projectId,
            title: recurringTask.title,
            description: recurringTask.description,
            isDescriptionEncrypted: recurringTask.isDescriptionEncrypted,
            dueDate: nextDate,
            status: TaskStatus.pending,
            assignees: recurringTask.assignees,
            createdAt: DateTime.now(),
            parentRecurringTaskId: recurringTask.id,
            reminderEnabled: recurringTask.reminderEnabled,
            recurrencePattern: RecurrencePattern.none,
            recurrenceInterval: 1,
          );
          try {
            await _taskRepository.createTask(newInstance);
            createdInstances.add(newInstance);
            appLogger.i(
              '$_logTag generated instance parentId=${recurringTask.id} dueDate=$nextDate',
            );
          } catch (error, stackTrace) {
            appLogger.e(
              '$_logTag failed to generate instance parentId=${recurringTask.id} dueDate=$nextDate',
              error: error,
              stackTrace: stackTrace,
            );
            rethrow;
          }
        }

        // Move to next occurrence
        tempTask = tempTask.copyWith(dueDate: nextDate);
      }
    }

    appLogger.i(
      '$_logTag generatePendingInstances created=${createdInstances.length} projectId=$projectId',
    );
    return createdInstances;
  }

  /// Get all instances of a recurring task
  Future<List<Task>> getRecurringTaskInstances(String recurringTaskId) async {
    appLogger.d(
      '$_logTag getRecurringTaskInstances recurringTaskId=$recurringTaskId',
    );
    try {
      return await _taskRepository
          .streamRecurringTaskInstances(recurringTaskId)
          .first;
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag failed to fetch recurring instances recurringTaskId=$recurringTaskId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get upcoming recurrences for a recurring task (as preview, not created yet)
  List<DateTime> getUpcomingRecurrences(Task recurringTask, {int count = 5}) {
    if (!recurringTask.isRecurring || recurringTask.dueDate == null) {
      return [];
    }

    final upcoming = <DateTime>[];
    var current = recurringTask;

    for (var i = 0; i < count; i++) {
      final next = current.getNextOccurrence();
      if (next == null) break;

      upcoming.add(next);
      current = current.copyWith(dueDate: next);
    }

    appLogger.d(
      '$_logTag computed upcoming recurrences count=${upcoming.length} taskId=${recurringTask.id}',
    );

    return upcoming;
  }
}
