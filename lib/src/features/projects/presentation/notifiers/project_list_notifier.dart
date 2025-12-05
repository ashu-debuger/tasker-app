import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/project.dart';
import '../../data/repositories/project_repository.dart';
import '../../../tasks/data/repositories/task_repository.dart';
import '../../../../core/providers/providers.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../../core/utils/app_logger.dart';

part 'project_list_notifier.g.dart';

/// Notifier for managing the list of projects
@riverpod
class ProjectListNotifier extends _$ProjectListNotifier {
  ProjectRepository get _repository => ref.read(projectRepositoryProvider);
  TaskRepository get _taskRepository => ref.read(taskRepositoryProvider);
  static const _logTag = 'ProjectListNotifier';

  @override
  Stream<List<Project>> build() {
    appLogger.d('$_logTag build invoked');
    // Get current user ID from auth state
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // No user logged in, return empty stream
          appLogger.w('$_logTag no authenticated user - emitting empty list');
          return Stream.value(const <Project>[]);
        }
        // Stream projects for the current user, prepending Personal project
        appLogger.d('$_logTag streaming projects for userId=${user.id}');
        final personalProject = Project.personal(user.id);
        return _repository
            .streamProjectsForUser(user.id)
            .map((projects) {
              // Prepend Personal project at the top
              return [personalProject, ...projects];
            })
            .handleError((error, stackTrace) {
              appLogger.e(
                '$_logTag project stream error userId=${user.id}',
                error: error,
                stackTrace: stackTrace,
              );
            });
      },
      loading: () {
        appLogger.d('$_logTag auth loading - emitting empty list');
        return Stream.value(const <Project>[]);
      },
      error: (error, stackTrace) {
        appLogger.e(
          '$_logTag auth state error - emitting empty list',
          error: error,
          stackTrace: stackTrace,
        );
        return Stream.value(const <Project>[]);
      },
    );
  }

  /// Create a new project
  Future<void> createProject({
    required String id,
    required String name,
    String? description,
  }) async {
    appLogger.i('$_logTag createProject requested name=$name');
    final authState = ref.read(authProvider);
    final user = authState.value;

    if (user == null) {
      appLogger.w('$_logTag createProject blocked - no authenticated user');
      throw Exception('User must be logged in to create a project');
    }

    final project = Project(
      id: id,
      name: name,
      description: description,
      members: [user.id], // Creator is the first member
      ownerId: user.id, // Set creator as owner
      memberRoles: {user.id: 'owner'}, // Creator has owner role
      createdAt: DateTime.now(),
    );

    try {
      await _repository.createProject(project);
      appLogger.i('$_logTag createProject success projectId=${project.id}');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag createProject failed projectId=${project.id}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing project
  Future<void> updateProject(Project project) async {
    appLogger.d('$_logTag updateProject projectId=${project.id}');
    try {
      await _repository.updateProject(project);
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

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    appLogger.w('$_logTag deleteProject requested projectId=$projectId');
    try {
      await _taskRepository.deleteTasksForProject(projectId);
      await _repository.deleteProject(projectId);
      appLogger.i('$_logTag deleteProject success projectId=$projectId');
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag deleteProject failed projectId=$projectId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Add a member to a project
  Future<void> addMember(String projectId, String userId) async {
    appLogger.d('$_logTag addMember projectId=$projectId userId=$userId');
    try {
      await _repository.addMember(projectId, userId);
      appLogger.i(
        '$_logTag addMember success projectId=$projectId userId=$userId',
      );
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag addMember failed projectId=$projectId userId=$userId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Remove a member from a project
  Future<void> removeMember(String projectId, String userId) async {
    appLogger.d('$_logTag removeMember projectId=$projectId userId=$userId');
    try {
      await _repository.removeMember(projectId, userId);
      appLogger.i(
        '$_logTag removeMember success projectId=$projectId userId=$userId',
      );
    } catch (error, stackTrace) {
      appLogger.e(
        '$_logTag removeMember failed projectId=$projectId userId=$userId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
