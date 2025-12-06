import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/providers.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/project_role.dart';

part 'project_members_notifier.g.dart';

/// State for project member operations
class ProjectMembersState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ProjectMembersState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ProjectMembersState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ProjectMembersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Notifier for managing project members
@riverpod
class ProjectMembersNotifier extends _$ProjectMembersNotifier {
  @override
  ProjectMembersState build() {
    return const ProjectMembersState();
  }

  /// Add a member to a project (typically called after accepting invitation)
  Future<void> addMember({
    required String projectId,
    required String userId,
    required ProjectRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final repository = ref.read(projectMemberRepositoryProvider);

      // Permission: only owner/admin can add members
      final currentUser = ref.read(authProvider).value;
      final currentUserId = currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      final currentRole = await repository.getUserRole(
        projectId: projectId,
        userId: currentUserId,
      );
      if (currentRole == null || !currentRole.isAdmin) {
        throw Exception('You do not have permission to add members');
      }

      await repository.addMember(
        projectId: projectId,
        userId: userId,
        role: role,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Member added successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Remove a member from a project
  Future<void> removeMember({
    required String projectId,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final repository = ref.read(projectMemberRepositoryProvider);

      // Permission: only owner/admin can remove members
      final currentUser = ref.read(authProvider).value;
      final currentUserId = currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      final currentRole = await repository.getUserRole(
        projectId: projectId,
        userId: currentUserId,
      );
      if (currentRole == null || !currentRole.isAdmin) {
        throw Exception('You do not have permission to remove members');
      }

      await repository.removeMember(projectId: projectId, userId: userId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Member removed successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Update a member's role in a project
  Future<void> updateMemberRole({
    required String projectId,
    required String userId,
    required ProjectRole newRole,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final repository = ref.read(projectMemberRepositoryProvider);

      // Permission: only owner/admin can change roles
      final currentUser = ref.read(authProvider).value;
      final currentUserId = currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      final currentRole = await repository.getUserRole(
        projectId: projectId,
        userId: currentUserId,
      );
      if (currentRole == null || !currentRole.isAdmin) {
        throw Exception('You do not have permission to change roles');
      }

      await repository.updateMemberRole(
        projectId: projectId,
        userId: userId,
        newRole: newRole,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Member role updated successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Clear any error or success messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Stream provider for project members
@riverpod
Stream<List<ProjectMember>> projectMembersList(Ref ref, String projectId) {
  // Personal project is synthetic - no members in Firestore
  if (projectId == Project.personalProjectId) {
    return Stream.value([]);
  }
  final repository = ref.watch(projectMemberRepositoryProvider);
  return repository.getProjectMembers(projectId);
}

/// Provider to get a specific member's role
@riverpod
Future<ProjectRole?> memberRole(Ref ref, String projectId, String userId) {
  // Personal project is synthetic - user is always the owner
  if (projectId == Project.personalProjectId) {
    return Future.value(ProjectRole.owner);
  }
  final repository = ref.watch(projectMemberRepositoryProvider);
  return repository.getUserRole(projectId: projectId, userId: userId);
}

/// Provider to check if a user is a member of a project
@riverpod
Future<bool> isMember(Ref ref, String projectId, String userId) {
  // Personal project is synthetic - user is always a member
  if (projectId == Project.personalProjectId) {
    return Future.value(true);
  }
  final repository = ref.watch(projectMemberRepositoryProvider);
  return repository.isMember(projectId: projectId, userId: userId);
}

/// Stream provider for user's projects (where they are a member)
@riverpod
Stream<List<String>> userProjectIds(Ref ref, String userId) {
  final repository = ref.watch(projectMemberRepositoryProvider);
  return repository.getUserProjects(userId);
}
