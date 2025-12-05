import '../../domain/models/project.dart';

/// Abstract repository for project operations
abstract class ProjectRepository {
  /// Get a single project by ID
  Future<Project?> getProjectById(String projectId);

  /// Stream projects for a specific user
  Stream<List<Project>> streamProjectsForUser(String userId);

  /// Create a new project
  Future<void> createProject(Project project);

  /// Update an existing project
  Future<void> updateProject(Project project);

  /// Delete a project
  Future<void> deleteProject(String projectId);

  /// Add a member to a project
  Future<void> addMember(String projectId, String userId);

  /// Remove a member from a project
  Future<void> removeMember(String projectId, String userId);
}
