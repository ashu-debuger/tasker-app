import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../domain/models/project.dart';
import 'project_repository.dart';
import '../../../../core/utils/app_logger.dart';

/// Firebase implementation of ProjectRepository
class FirebaseProjectRepository implements ProjectRepository {
  final FirebaseFirestore _firestore;
  static const _logTag = '[Project:Repo]';

  FirebaseProjectRepository(this._firestore);

  /// Collection reference for projects
  CollectionReference get _projectsCollection =>
      _firestore.collection('projects');

  @override
  Future<Project?> getProjectById(String projectId) async {
    appLogger.d('$_logTag getProjectById projectId=$projectId');
    try {
      final doc = await logTimedAsync(
        '$_logTag getProjectDoc $projectId',
        () => _projectsCollection.doc(projectId).get(),
        level: Level.debug,
      );
      if (!doc.exists) return null;
      appLogger.i('$_logTag getProjectById success projectId=$projectId');
      return Project.fromFirestore(doc);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getProjectById failed projectId=$projectId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Project>> streamProjectsForUser(String userId) {
    try {
      appLogger.d('$_logTag streamProjectsForUser subscribed userId=$userId');
      return _projectsCollection
          .where('members', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) {
              final projects =
                  snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
              appLogger.d(
                '$_logTag streamProjectsForUser snapshot=${projects.length} userId=$userId',
              );
              return projects;
            },
          );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamProjectsForUser failed userId=$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> createProject(Project project) async {
    appLogger.i(
      '$_logTag createProject requested projectId=${project.id} memberCount=${project.members.length}',
    );
    try {
      await logTimedAsync(
        '$_logTag createProject write projectId=${project.id}',
        () => _projectsCollection.doc(project.id).set(project.toFirestore()),
      );
      appLogger.i('$_logTag createProject success projectId=${project.id}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag createProject failed projectId=${project.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateProject(Project project) async {
    appLogger.i('$_logTag updateProject requested projectId=${project.id}');
    try {
      final updatedProject = project.copyWith(updatedAt: DateTime.now());
      await logTimedAsync(
        '$_logTag updateProject write projectId=${project.id}',
        () => _projectsCollection.doc(project.id).update(
              updatedProject.toFirestore(),
            ),
      );
      appLogger.i('$_logTag updateProject success projectId=${project.id}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag updateProject failed projectId=${project.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    appLogger.w('$_logTag deleteProject requested projectId=$projectId');
    try {
      await logTimedAsync(
        '$_logTag deleteProject write projectId=$projectId',
        () => _projectsCollection.doc(projectId).delete(),
      );
      appLogger.i('$_logTag deleteProject success projectId=$projectId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteProject failed projectId=$projectId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> addMember(String projectId, String userId) async {
    appLogger.i('$_logTag addMember projectId=$projectId userId=$userId');
    try {
      await logTimedAsync(
        '$_logTag addMember write projectId=$projectId',
        () => _projectsCollection.doc(projectId).update({
              'members': FieldValue.arrayUnion([userId]),
              'updatedAt': Timestamp.now(),
            }),
      );
      appLogger.i('$_logTag addMember success projectId=$projectId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag addMember failed projectId=$projectId userId=$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> removeMember(String projectId, String userId) async {
    appLogger.i('$_logTag removeMember projectId=$projectId userId=$userId');
    try {
      await logTimedAsync(
        '$_logTag removeMember write projectId=$projectId',
        () => _projectsCollection.doc(projectId).update({
              'members': FieldValue.arrayRemove([userId]),
              'updatedAt': Timestamp.now(),
            }),
      );
      appLogger.i('$_logTag removeMember success projectId=$projectId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag removeMember failed projectId=$projectId userId=$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
