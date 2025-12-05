import 'package:tasker/src/core/notifications/notification_service.dart'
    as notif;
import 'package:tasker/src/features/routines/domain/models/routine.dart';
import 'package:tasker/src/features/settings/data/repositories/reminder_settings_repository.dart';

/// Helper class for managing routine notifications
class RoutineNotificationHelper {
  final notif.NotificationService _notificationService;
  final ReminderSettingsRepository _reminderSettingsRepository;

  RoutineNotificationHelper(
    this._notificationService,
    this._reminderSettingsRepository,
  );

  /// Generate a unique notification ID from routine ID
  int _getNotificationId(String routineId) {
    // Use hashCode to generate consistent integer ID
    return routineId.hashCode & 0x7FFFFFFF; // Ensure positive integer
  }

  /// Schedule notifications for a routine
  Future<void> scheduleRoutineNotification(Routine routine) async {
    // Only schedule if routine has reminder enabled, is active, and has a time set
    if (!routine.reminderEnabled ||
        !routine.isActive ||
        routine.timeOfDay == null) {
      return;
    }

    final notificationId = _getNotificationId(routine.id);
    final timeParts = routine.timeOfDay!.split(':');
    if (timeParts.length != 2) return;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return;

    final reminderTime = _buildReminderTime(
      hour: hour,
      minute: minute,
      leadMinutes: _resolveLeadMinutes(routine),
    );

    // For daily routines, schedule a daily notification
    if (routine.frequency == RoutineFrequency.daily) {
      await _notificationService.scheduleDailyNotification(
        id: notificationId,
        title: 'Routine Reminder: ${routine.title}',
        body: routine.description ?? 'Time to complete your routine',
        time: reminderTime,
        payload: 'routine:${routine.id}',
      );
    } else {
      // For weekly/custom routines, we'd need to schedule multiple notifications
      // For now, use daily and check day-of-week in the app
      // A better approach would be to schedule for specific days
      await _notificationService.scheduleDailyNotification(
        id: notificationId,
        title: 'Routine Reminder: ${routine.title}',
        body: routine.description ?? 'Time to complete your routine',
        time: reminderTime,
        payload: 'routine:${routine.id}',
      );
    }
  }

  /// Cancel notifications for a routine
  Future<void> cancelRoutineNotification(String routineId) async {
    final notificationId = _getNotificationId(routineId);
    await _notificationService.cancelNotification(notificationId);
  }

  /// Reschedule notification (cancel and schedule)
  Future<void> rescheduleRoutineNotification(Routine routine) async {
    await cancelRoutineNotification(routine.id);
    await scheduleRoutineNotification(routine);
  }

  notif.TimeOfDay _buildReminderTime({
    required int hour,
    required int minute,
    required int leadMinutes,
  }) {
    final totalMinutes = (hour * 60) + minute;
    var reminderMinutes = totalMinutes - leadMinutes;

    while (reminderMinutes < 0) {
      reminderMinutes += 24 * 60;
    }

    final reminderHour = (reminderMinutes ~/ 60) % 24;
    final reminderMinute = reminderMinutes % 60;

    return notif.TimeOfDay(hour: reminderHour, minute: reminderMinute);
  }

  int _resolveLeadMinutes(Routine routine) {
    final override = routine.reminderMinutesBefore;
    if (override > 0) {
      return override;
    }

    return _reminderSettingsRepository.getCurrentSettings().routineLeadMinutes;
  }
}
