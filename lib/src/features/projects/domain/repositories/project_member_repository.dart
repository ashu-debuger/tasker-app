import '../models/project_member.dart';
import '../models/project_role.dart';

/// Repository for managing project members
abstract class ProjectMemberRepository {
  /// Add a member to a project
  ///
  /// [projectId] - Project ID
  /// [userId] - User ID to add
  /// [role] - Role to assign
  ///
  /// Throws exception if user is already a member
  Future<void> addMember({
    required String projectId,
    required String userId,
    required ProjectRole role,
  });

  /// Remove a member from a project
  ///
  /// [projectId] - Project ID
  /// [userId] - User ID to remove
  ///
  /// Also removes member from project tasks and cleans up related data
  Future<void> removeMember({
    required String projectId,
    required String userId,
  });

  /// Update a member's role in a project
  ///
  /// [projectId] - Project ID
  /// [userId] - User ID
  /// [newRole] - New role to assign
  Future<void> updateMemberRole({
    required String projectId,
    required String userId,
    required ProjectRole newRole,
  });

  /// Get all members of a project
  ///
  /// [projectId] - Project ID
  ///
  /// Returns stream of project members
  Stream<List<ProjectMember>> getProjectMembers(String projectId);

  /// Get a specific member's details
  ///
  /// [projectId] - Project ID
  /// [userId] - User ID
  ///
  /// Returns the member or null if not found
  Future<ProjectMember?> getMember({
    required String projectId,
    required String userId,
  });

  /// Get user's role in a project
  ///
  /// [projectId] - Project ID
  /// [userId] - User ID
  ///
  /// Returns the role or null if not a member
  Future<ProjectRole?> getUserRole({
    required String projectId,
    required String userId,
  });

  /// Check if user is a member of a project
  ///
  /// [projectId] - Project ID
  /// [userId] - User ID
  ///
  /// Returns true if user is a member
  Future<bool> isMember({required String projectId, required String userId});

  /// Get all projects a user is a member of
  ///
  /// [userId] - User ID
  ///
  /// Returns stream of project IDs
  Stream<List<String>> getUserProjects(String userId);

  /// Get count of members in a project
  ///
  /// [projectId] - Project ID
  ///
  /// Returns member count
  Future<int> getMemberCount(String projectId);
}
