import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/task.dart';
import '../../domain/models/subtask.dart';
import '../../domain/helpers/task_reminder_helper.dart';
import '../../data/repositories/task_repository.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/app_logger.dart';

part 'task_detail_notifier.g.dart';

/// State class combining task, subtasks, and progress
class TaskDetailState {
  final Task? task;
  final List<Subtask> subtasks;
  final String? error;

  const TaskDetailState({this.task, this.subtasks = const [], this.error});

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress {
    if (subtasks.isEmpty) return 0.0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  /// Calculate completion percentage (0 to 100)
  int get completionPercentage {
    if (subtasks.isEmpty) return 0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return ((completed / subtasks.length) * 100).round();
  }

  /// Get count of completed subtasks
  int get completedCount => subtasks.where((s) => s.isCompleted).length;

  /// Get total count of subtasks
  int get totalCount => subtasks.length;

  /// Check if all subtasks are completed
  bool get isFullyCompleted =>
      subtasks.isNotEmpty && completedCount == totalCount;

  TaskDetailState copyWith({
    Task? task,
    List<Subtask>? subtasks,
    String? error,
  }) {
    return TaskDetailState(
      task: task ?? this.task,
      subtasks: subtasks ?? this.subtasks,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing task details and associated subtasks
@riverpod
class TaskDetailNotifier extends _$TaskDetailNotifier {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);
  TaskReminderHelper get _reminderHelper =>
      ref.read(taskReminderHelperProvider);
  static const _logTag = 'TaskDetailNotifier';
  late String _taskId;

  @override
  Stream<TaskDetailState> build(String taskId) {
    _taskId = taskId;
    appLogger.d('$_logTag build invoked taskId=$taskId');
    return _combineStreams(taskId);
  }

  Stream<TaskDetailState> _combineStreams(String taskId) {
    return Stream.multi((controller) {
      appLogger.d('$_logTag starting combined stream taskId=$taskId');
      Task? currentTask;
      List<Subtask> currentSubtasks = const [];
      bool hasTask = false;

      void emitState() {
        if (!hasTask || currentTask == null) return;
        controller.add(
          TaskDetailState(task: currentTask, subtasks: currentSubtasks),
        );
      }

      final taskSubscription = _repository
          .streamTaskById(taskId)
          .listen(
            (task) {
              if (task == null) {
                hasTask = false;
                currentTask = null;
                appLogger.w('$_logTag task not found taskId=$taskId');
                controller.add(
                  const TaskDetailState(
                    task: null,
                    subtasks: [],
                    error: 'Task not found',
                  ),
                );
                return;
              }
              currentTask = task;
              hasTask = true;
              emitState();
            },
            onError: (error, stackTrace) {
              appLogger.e(
                '$_logTag task stream error taskId=$taskId',
                error: error,
                stackTrace: stackTrace,
              );
              controller.addError(error, stackTrace);
            },
          );

      final subtaskSubscription = _repository
          .streamSubtasksForTask(taskId)
          .listen(
            (subtasks) {
              currentSubtasks = subtasks;
              emitState();
            },
            onError: (error, stackTrace) {
              appLogger.e(
                '$_logTag subtask stream error taskId=$taskId',
                error: error,
                stackTrace: stackTrace,
              );
              controller.addError(error, stackTrace);
            },
          );

      controller.onCancel = () async {
        appLogger.d('$_logTag cancelling subscriptions taskId=$taskId');
        await taskSubscription.cancel();
        await subtaskSubscription.cancel();
      };
    });
  }

  /// Create a new subtask
  Future<void> createSubtask({
    required String id,
    required String title,
    DateTime? dueDate,
  }) async {
    final currentState = state.value;
    final task = currentState?.task;
    if (task == null) return;
    appLogger.i('$_logTag createSubtask requested taskId=${task.id}');
    final subtask = Subtask(
      id: id,
      taskId: task.id,
      title: title,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );

    try {
      await _repository.createSubtask(subtask);
      appLogger.i('$_logTag createSubtask success subtaskId=${subtask.id}');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag createSubtask failed taskId=${subtask.taskId}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing subtask
  Future<void> updateSubtask(Subtask subtask) async {
    appLogger.d('$_logTag updateSubtask subtaskId=${subtask.id}');
    try {
      await _repository.updateSubtask(subtask);
      appLogger.i('$_logTag updateSubtask success subtaskId=${subtask.id}');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag updateSubtask failed subtaskId=${subtask.id}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a subtask
  Future<void> deleteSubtask(String subtaskId) async {
    appLogger.w('$_logTag deleteSubtask requested subtaskId=$subtaskId');
    try {
      await _repository.deleteSubtask(subtaskId);
      appLogger.i('$_logTag deleteSubtask success subtaskId=$subtaskId');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag deleteSubtask failed subtaskId=$subtaskId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Toggle subtask completion status
  Future<void> toggleSubtaskCompletion(String subtaskId) async {
    appLogger.d('$_logTag toggleSubtaskCompletion subtaskId=$subtaskId');
    try {
      await _repository.toggleSubtaskCompletion(subtaskId);
      appLogger.i(
        '$_logTag toggleSubtaskCompletion success subtaskId=$subtaskId',
      );
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag toggleSubtaskCompletion failed subtaskId=$subtaskId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update the task itself
  Future<void> updateTask(Task task) async {
    appLogger.d('$_logTag updateTask taskId=${task.id}');
    try {
      await _repository.updateTask(task);
      await _reminderHelper.rescheduleTaskReminder(task);
      appLogger.i('$_logTag updateTask success taskId=${task.id}');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag updateTask failed taskId=${task.id}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update task status
  Future<void> updateTaskStatus(TaskStatus status) async {
    final currentState = state.value;
    final baseTask = currentState?.task;
    if (baseTask == null) return;

    final updatedTask = baseTask.copyWith(status: status);
    appLogger.d(
      '$_logTag updateTaskStatus taskId=${updatedTask.id} status=$status',
    );
    try {
      await _repository.updateTask(updatedTask);
      await _reminderHelper.rescheduleTaskReminder(updatedTask);
      appLogger.i('$_logTag updateTaskStatus success taskId=${updatedTask.id}');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag updateTaskStatus failed taskId=${updatedTask.id}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete the current task and its subtasks
  Future<void> deleteTask() async {
    appLogger.w('$_logTag deleteTask requested taskId=$_taskId');
    try {
      await _repository.deleteTask(_taskId);
      await _reminderHelper.cancelTaskReminder(_taskId);
      appLogger.i('$_logTag deleteTask success taskId=$_taskId');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag deleteTask failed taskId=$_taskId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Assign task to user(s)
  Future<void> assignTask({
    required String taskId,
    required List<String> assigneeIds,
    required String assignedBy,
  }) async {
    appLogger.d(
      '$_logTag assignTask taskId=$taskId assignees=${assigneeIds.length}',
    );
    try {
      await _repository.assignTask(
        taskId: taskId,
        assigneeIds: assigneeIds,
        assignedBy: assignedBy,
      );
      appLogger.i('$_logTag assignTask success taskId=$taskId');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag assignTask failed taskId=$taskId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Unassign task
  Future<void> unassignTask(String taskId) async {
    appLogger.d('$_logTag unassignTask taskId=$taskId');
    try {
      await _repository.unassignTask(taskId);
      appLogger.i('$_logTag unassignTask success taskId=$taskId');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag unassignTask failed taskId=$taskId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
