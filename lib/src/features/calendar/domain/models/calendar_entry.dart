import '../../../projects/domain/models/project.dart';
import '../../../tasks/domain/models/task.dart';
import '../../../routines/domain/models/routine.dart';

/// Unified calendar entry representing either a task due date or a routine run.
enum CalendarEntryType { taskDue, assignedTaskDue, routine }

class CalendarEntry {
  const CalendarEntry({
    required this.type,
    required this.date,
    required this.title,
    this.subtitle,
    this.task,
    this.routine,
    this.project,
  });

  final CalendarEntryType type;
  final DateTime date;
  final String title;
  final String? subtitle;
  final Task? task;
  final Routine? routine;
  final Project? project;

  bool get isTask =>
      (type == CalendarEntryType.taskDue ||
          type == CalendarEntryType.assignedTaskDue) &&
      task != null;
  bool get isRoutine => type == CalendarEntryType.routine && routine != null;
  bool get isAssignedTask =>
      type == CalendarEntryType.assignedTaskDue && task != null;

  bool get isCompleted => isTask && task!.status == TaskStatus.completed;

  bool get isOverdue {
    if (!isTask) return false;
    final dueDate = task!.dueDate;
    if (dueDate == null) return false;
    if (isCompleted) return false;
    return DateTime.now().isAfter(dueDate);
  }
}
