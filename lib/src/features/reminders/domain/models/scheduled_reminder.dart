import 'package:equatable/equatable.dart';

/// Model representing a scheduled reminder with task information
class ScheduledReminder extends Equatable {
  const ScheduledReminder({
    required this.id,
    required this.taskId,
    required this.projectId,
    required this.taskTitle,
    required this.scheduledDate,
    this.projectName,
    this.taskDueDate,
  });

  final int id;
  final String taskId;
  final String projectId;
  final String taskTitle;
  final DateTime scheduledDate;
  final String? projectName;
  final DateTime? taskDueDate;

  @override
  List<Object?> get props => [
        id,
        taskId,
        projectId,
        taskTitle,
        scheduledDate,
        projectName,
        taskDueDate,
      ];
}
