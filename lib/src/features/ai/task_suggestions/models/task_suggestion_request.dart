import 'package:equatable/equatable.dart';

/// Context passed to the suggestion engine for generating task ideas.
class TaskSuggestionRequest extends Equatable {
  const TaskSuggestionRequest({
    required this.projectId,
    required this.projectName,
    this.recentTasks = const <String>[],
    this.keywords = const <String>[],
    this.desiredDueDate,
    this.desiredCount = 3,
    this.focusArea,
  }) : assert(desiredCount > 0, 'desiredCount must be positive');

  final String projectId;
  final String projectName;
  final List<String> recentTasks;
  final List<String> keywords;
  final DateTime? desiredDueDate;
  final int desiredCount;
  final String? focusArea;

  @override
  List<Object?> get props => <Object?>[
        projectId,
        projectName,
        recentTasks,
        keywords,
        desiredDueDate,
        desiredCount,
        focusArea,
      ];
}
