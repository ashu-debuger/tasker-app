import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/providers.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/subtask.dart';

part 'task_progress_provider.g.dart';

/// Summary info about a task's subtasks
class TaskSubtaskSummary {
  final int total;
  final int completed;
  final bool isLoading;

  const TaskSubtaskSummary({
    required this.total,
    required this.completed,
    this.isLoading = false,
  });

  const TaskSubtaskSummary.loading()
    : total = 0,
      completed = 0,
      isLoading = true;

  const TaskSubtaskSummary.empty()
    : total = 0,
      completed = 0,
      isLoading = false;

  int get remaining => total - completed;
  bool get hasSubtasks => !isLoading && total > 0;
  bool get allComplete => hasSubtasks && remaining == 0;
  double get progress => total == 0 ? 0 : completed / total;
}

@riverpod
Stream<TaskSubtaskSummary> taskSubtaskSummary(Ref ref, String taskId) {
  final TaskRepository repository = ref.watch(taskRepositoryProvider);
  return repository.streamSubtasksForTask(taskId).map((List<Subtask> subtasks) {
    final int total = subtasks.length;
    final int completed = subtasks
        .where((subtask) => subtask.isCompleted)
        .length;
    return TaskSubtaskSummary(total: total, completed: completed);
  });
}
