import '../../domain/models/task.dart';
import '../../domain/models/subtask.dart';

/// Abstract repository for task and subtask operations
abstract class TaskRepository {
  /// Get a single task by ID
  Future<Task?> getTaskById(String taskId);

  /// Stream updates for a single task
  Stream<Task?> streamTaskById(String taskId);

  /// Stream tasks for a specific project
  Stream<List<Task>> streamTasksForProject(String projectId);

  /// Stream all tasks assigned to a specific user
  Stream<List<Task>> streamTasksForUser(String userId);

  /// Stream recurring task instances (tasks that have a parent recurring task)
  Stream<List<Task>> streamRecurringTaskInstances(String parentRecurringTaskId);

  /// Get all tasks for a project (as a Future, for one-time queries)
  Future<List<Task>> getTasksByProject(String projectId);

  /// Create a new task
  Future<void> createTask(Task task);

  /// Update an existing task
  Future<void> updateTask(Task task);

  /// Delete a task
  Future<void> deleteTask(String taskId);

  /// Delete all tasks (and subtasks) associated with a project
  Future<void> deleteTasksForProject(String projectId);

  /// Get a single subtask by ID
  Future<Subtask?> getSubtaskById(String subtaskId);

  /// Stream subtasks for a specific task
  Stream<List<Subtask>> streamSubtasksForTask(String taskId);

  /// Create a new subtask
  Future<void> createSubtask(Subtask subtask);

  /// Update an existing subtask
  Future<void> updateSubtask(Subtask subtask);

  /// Delete a subtask
  Future<void> deleteSubtask(String subtaskId);

  /// Toggle subtask completion status
  Future<void> toggleSubtaskCompletion(String subtaskId);

  /// Assign task to specific user(s)
  Future<void> assignTask({
    required String taskId,
    required List<String> assigneeIds,
    required String assignedBy,
  });

  /// Unassign all users from a task
  Future<void> unassignTask(String taskId);

  /// Get tasks assigned to a specific user in a project
  Stream<List<Task>> streamTasksAssignedToUser({
    required String userId,
    String? projectId,
  });

  /// Get unassigned tasks in a project
  Stream<List<Task>> streamUnassignedTasks(String projectId);

  /// Stream personal tasks (tasks without a project, i.e., projectId == null)
  /// These are tasks created from Cliq or other sources without a project assignment
  Stream<List<Task>> streamPersonalTasks(String userId);
}
