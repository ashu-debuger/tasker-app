import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/project.dart';
import '../../../tasks/domain/models/task.dart';
import '../../data/repositories/project_repository.dart';
import '../../../tasks/data/repositories/task_repository.dart';
import '../../../tasks/domain/helpers/task_reminder_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';

part 'project_detail_notifier.g.dart';

/// State class combining project and its tasks
class ProjectDetailState {
  final Project? project;
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  const ProjectDetailState({
    this.project,
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  ProjectDetailState copyWith({
    Project? project,
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return ProjectDetailState(
      project: project ?? this.project,
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing project details and associated tasks
@riverpod
class ProjectDetailNotifier extends _$ProjectDetailNotifier {
  ProjectRepository get _projectRepository =>
      ref.read(projectRepositoryProvider);
  TaskRepository get _taskRepository => ref.read(taskRepositoryProvider);
  TaskReminderHelper get _reminderHelper =>
      ref.read(taskReminderHelperProvider);
  static const _logTag = 'ProjectDetailNotifier';
  late String _projectId;

  @override
  Stream<ProjectDetailState> build(String projectId) {
    _projectId = projectId;
    appLogger.d('$_logTag build invoked projectId=$projectId');
    // Combine project and tasks streams
    return _combineStreams(projectId);
  }

  Stream<ProjectDetailState> _combineStreams(String projectId) async* {
    appLogger.d('$_logTag starting combined stream projectId=$projectId');
    yield const ProjectDetailState(isLoading: true);

    try {
      // Handle Personal project (synthetic, not in Firestore)
      if (projectId == Project.personalProjectId) {
        final authState = ref.read(authProvider);
        final user = authState.value;
        if (user == null) {
          appLogger.w('$_logTag no authenticated user for personal project');
          yield const ProjectDetailState(
            isLoading: false,
            error: 'User not authenticated',
          );
          return;
        }

        final personalProject = Project.personal(user.id);
        appLogger.d('$_logTag streaming personal tasks for userId=${user.id}');

        // Stream personal tasks (tasks with projectId == null)
        await for (final tasks
            in _taskRepository.streamPersonalTasks(user.id).handleError((
              error,
              stackTrace,
            ) {
              appLogger.e(
                '$_logTag personal task stream error userId=${user.id}',
                error: error,
                stackTrace: stackTrace,
              );
            })) {
          yield ProjectDetailState(
            project: personalProject,
            tasks: tasks,
            isLoading: false,
          );
        }
        return;
      }

      // Regular project handling
      final project = await _projectRepository.getProjectById(projectId);

      if (project == null) {
        appLogger.w('$_logTag project not found projectId=$projectId');
        yield ProjectDetailState(isLoading: false, error: 'Project not found');
        return;
      }

      appLogger.d('$_logTag streaming tasks for projectId=$projectId');
      // Stream tasks for the project
      await for (final tasks
          in _taskRepository.streamTasksForProject(projectId).handleError((
            error,
            stackTrace,
          ) {
            appLogger.e(
              '$_logTag task stream error projectId=$projectId',
              error: error,
              stackTrace: stackTrace,
            );
          })) {
        yield ProjectDetailState(
          project: project,
          tasks: tasks,
          isLoading: false,
        );
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag combine stream failed projectId=$projectId',
        error: e,
        stackTrace: stackTrace,
      );
      yield ProjectDetailState(isLoading: false, error: e.toString());
    }
  }

  /// Create a new task in this project
  Future<void> createTask({
    required String id,
    required String title,
    String? description,
    bool isDescriptionEncrypted = false,
    DateTime? dueDate,
    List<String> assignees = const [],
    RecurrencePattern recurrencePattern = RecurrencePattern.none,
    int recurrenceInterval = 1,
    DateTime? recurrenceEndDate,
    bool reminderEnabled = true,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
  }) async {
    final currentState = state.value;
    final project = currentState?.project;
    if (project == null) return;
    appLogger.i('$_logTag createTask requested projectId=${project.id}');

    // For Personal project, set projectId to null
    final effectiveProjectId = project.isPersonal ? null : project.id;

    // Get current user ID
    final currentUserId = ref.read(authProvider).value?.id ?? '';

    // Auto-assign creator if no assignees provided (for both Personal and Project tasks)
    final effectiveAssignees = assignees.isEmpty && currentUserId.isNotEmpty
        ? [currentUserId]
        : assignees;

    final task = Task(
      id: id,
      projectId: effectiveProjectId,
      title: title,
      description: description,
      isDescriptionEncrypted: isDescriptionEncrypted,
      dueDate: dueDate,
      assignees: effectiveAssignees,
      createdAt: DateTime.now(),
      recurrencePattern: recurrencePattern,
      recurrenceInterval: recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate,
      reminderEnabled: reminderEnabled,
      priority: priority,
      tags: tags,
    );

    try {
      await _taskRepository.createTask(task);
      appLogger.i('$_logTag createTask success taskId=${task.id}');
      await _reminderHelper.scheduleTaskReminder(task);
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag createTask failed projectId=${task.projectId}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    appLogger.d('$_logTag updateTask taskId=${task.id}');
    try {
      await _taskRepository.updateTask(task);
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

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    appLogger.w('$_logTag deleteTask requested taskId=$taskId');
    try {
      await _taskRepository.deleteTask(taskId);
      await _reminderHelper.cancelTaskReminder(taskId);
      appLogger.i('$_logTag deleteTask success taskId=$taskId');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag deleteTask failed taskId=$taskId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update the project itself
  Future<void> updateProject(Project project) async {
    appLogger.d('$_logTag updateProject projectId=${project.id}');
    try {
      await _projectRepository.updateProject(project);
      appLogger.i('$_logTag updateProject success projectId=${project.id}');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag updateProject failed projectId=${project.id}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete the entire project and its tasks
  Future<void> deleteProject() async {
    // Get all tasks to cancel their reminders
    final state = this.state.value;
    if (state != null && state.tasks.isNotEmpty) {
      appLogger.d(
        '$_logTag cancelling reminders before project delete projectId=$_projectId count=${state.tasks.length}',
      );
      for (final task in state.tasks) {
        await _reminderHelper.cancelTaskReminder(task.id);
      }
    }

    appLogger.w('$_logTag deleteProject requested projectId=$_projectId');
    try {
      await _taskRepository.deleteTasksForProject(_projectId);
      await _projectRepository.deleteProject(_projectId);
      appLogger.i('$_logTag deleteProject success projectId=$_projectId');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag deleteProject failed projectId=$_projectId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
