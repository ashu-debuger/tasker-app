import 'package:tasker/src/core/notifications/notification_service.dart'
    as notif;
import 'package:tasker/src/features/settings/data/repositories/reminder_settings_repository.dart';

import '../../../../core/utils/app_logger.dart';

import '../models/task.dart';

/// Helper responsible for keeping local task reminders aligned with due dates.
class TaskReminderHelper {
  TaskReminderHelper(
    this._notificationService,
    this._reminderSettingsRepository,
  );

  final notif.NotificationService _notificationService;
  final ReminderSettingsRepository _reminderSettingsRepository;
  static const _logTag = 'TaskReminderHelper';

  /// Hash the task id into a consistent notification id recognized by the OS.
  int _notificationIdForTask(String taskId) => taskId.hashCode & 0x7FFFFFFF;

  Duration get _taskLeadTime {
    final minutes = _reminderSettingsRepository
        .getCurrentSettings()
        .taskLeadMinutes;
    return Duration(minutes: minutes);
  }

  /// Schedule a reminder if the task has a due date in the future.
  Future<void> scheduleTaskReminder(Task task) async {
    appLogger.d('$_logTag scheduleTaskReminder taskId=${task.id}');
    if (!task.reminderEnabled) {
      appLogger.i(
        '$_logTag skipping schedule - reminder disabled taskId=${task.id}',
      );
      await cancelTaskReminder(task.id);
      return;
    }

    final dueDate = task.dueDate;
    if (dueDate == null || task.status == TaskStatus.completed) {
      final reason = dueDate == null ? 'noDueDate' : 'completedStatus';
      appLogger.i(
        '$_logTag cancelling reminder due to $reason taskId=${task.id}',
      );
      await cancelTaskReminder(task.id);
      return;
    }

    final scheduledDate = _reminderDate(dueDate);
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      appLogger.d(
        '$_logTag reminder already past taskId=${task.id} scheduled=$scheduledDate now=$now',
      );
      return;
    }

    try {
      await _notificationService.scheduleNotification(
        id: _notificationIdForTask(task.id),
        title: 'Task due soon: ${task.title}',
        body: task.description ?? 'Due ${_friendlyDate(dueDate)}',
        scheduledDate: scheduledDate,
        payload: 'task:${task.projectId}:${task.id}',
      );
      appLogger.i(
        '$_logTag scheduled reminder taskId=${task.id} fireAt=$scheduledDate dueDate=$dueDate',
      );
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag failed to schedule reminder taskId=${task.id}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Cancel any reminder that may exist for the task.
  Future<void> cancelTaskReminder(String taskId) async {
    appLogger.d('$_logTag cancelTaskReminder taskId=$taskId');
    try {
      await _notificationService.cancelNotification(
        _notificationIdForTask(taskId),
      );
      appLogger.d('$_logTag cancelTaskReminder complete taskId=$taskId');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag failed to cancel reminder taskId=$taskId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Cancel and re-create the reminder for an updated task.
  Future<void> rescheduleTaskReminder(Task task) async {
    appLogger.d('$_logTag rescheduleTaskReminder taskId=${task.id}');
    await cancelTaskReminder(task.id);
    if (!task.reminderEnabled ||
        task.dueDate == null ||
        task.status == TaskStatus.completed) {
      appLogger.d(
        '$_logTag skip reschedule - condition unmet taskId=${task.id}',
      );
      return;
    }
    await scheduleTaskReminder(task);
  }

  DateTime _reminderDate(DateTime dueDate) {
    final reminderDate = dueDate.subtract(_taskLeadTime);
    return reminderDate.isBefore(DateTime.now())
        ? DateTime.now()
        : reminderDate;
  }

  String _friendlyDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
