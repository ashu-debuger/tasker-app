import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../domain/models/task.dart';
import '../../domain/models/subtask.dart';
import 'task_repository.dart';
import '../../../../core/encryption/encryption_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/notifications/repositories/notification_repository.dart';
import '../../../../core/notifications/models/notification_type.dart';

/// Firebase implementation of TaskRepository
class FirebaseTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;
  final NotificationRepository? _notificationRepository;
  static const _logTag = '[Task:Repo]';

  FirebaseTaskRepository(
    this._firestore,
    this._encryptionService, [
    this._notificationRepository,
  ]);

  /// Collection reference for tasks
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  /// Collection reference for subtasks
  CollectionReference get _subtasksCollection =>
      _firestore.collection('subtasks');

  // ===== Task Operations =====

  @override
  Future<Task?> getTaskById(String taskId) async {
    appLogger.d('$_logTag getTaskById taskId=$taskId');
    try {
      final doc = await logTimedAsync(
        '$_logTag getTaskDoc $taskId',
        () => _tasksCollection.doc(taskId).get(),
        level: Level.debug,
      );
      if (!doc.exists) return null;

      final task = await _decryptDescriptionIfNeeded(
        Task.fromFirestore(doc),
        context: 'getTaskById',
        taskId: taskId,
      );

      appLogger.i('$_logTag getTaskById success taskId=$taskId');
      return task;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getTaskById failed taskId=$taskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<Task?> streamTaskById(String taskId) {
    try {
      appLogger.d('$_logTag streamTaskById subscribed taskId=$taskId');
      return _tasksCollection.doc(taskId).snapshots().asyncMap((doc) async {
        if (!doc.exists) return null;

        return _decryptDescriptionIfNeeded(
          Task.fromFirestore(doc),
          context: 'streamTaskById',
          taskId: taskId,
        );
      });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamTaskById setup failed taskId=$taskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Task>> streamTasksForProject(String projectId) {
    try {
      appLogger.d(
        '$_logTag streamTasksForProject subscribed projectId=$projectId',
      );
      return _tasksCollection
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            final tasks = <Task>[];
            for (final doc in snapshot.docs) {
              final task = await _decryptDescriptionIfNeeded(
                Task.fromFirestore(doc),
                context: 'streamTasksForProject',
                taskId: doc.id,
              );
              tasks.add(task);
            }
            appLogger.d(
              '$_logTag streamTasksForProject snapshot=${tasks.length} projectId=$projectId',
            );
            return tasks;
          });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamTasksForProject failed projectId=$projectId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Task>> streamTasksForUser(String userId) {
    try {
      appLogger.d('$_logTag streamTasksForUser subscribed userId=$userId');

      // First, get all projects where the user is a member
      return _firestore
          .collection('projects')
          .where('members', arrayContains: userId)
          .snapshots()
          .asyncExpand((projectsSnapshot) {
            if (projectsSnapshot.docs.isEmpty) {
              appLogger.d(
                '$_logTag streamTasksForUser no projects for userId=$userId',
              );
              return Stream.value(<Task>[]);
            }

            final projectIds = projectsSnapshot.docs
                .map((doc) => doc.id)
                .toList();
            appLogger.d(
              '$_logTag streamTasksForUser found ${projectIds.length} projects for userId=$userId',
            );

            // Then fetch all tasks from those projects
            return _tasksCollection
                .where(
                  'projectId',
                  whereIn: projectIds.take(10).toList(),
                ) // Firestore limit is 10 for whereIn
                .orderBy('dueDate', descending: false)
                .snapshots()
                .asyncMap((snapshot) async {
                  final tasks = <Task>[];
                  for (final doc in snapshot.docs) {
                    final task = await _decryptDescriptionIfNeeded(
                      Task.fromFirestore(doc),
                      context: 'streamTasksForUser',
                      taskId: doc.id,
                    );
                    tasks.add(task);
                  }
                  appLogger.d(
                    '$_logTag streamTasksForUser snapshot=${tasks.length} userId=$userId',
                  );
                  return tasks;
                });
          });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamTasksForUser failed userId=$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Task>> streamRecurringTaskInstances(
    String parentRecurringTaskId,
  ) {
    try {
      appLogger.d(
        '$_logTag streamRecurringTaskInstances subscribed parentId=$parentRecurringTaskId',
      );
      return _tasksCollection
          .where('parentRecurringTaskId', isEqualTo: parentRecurringTaskId)
          .orderBy('dueDate', descending: false)
          .snapshots()
          .asyncMap((snapshot) async {
            final tasks = <Task>[];
            for (final doc in snapshot.docs) {
              final task = await _decryptDescriptionIfNeeded(
                Task.fromFirestore(doc),
                context: 'streamRecurringTaskInstances',
                taskId: doc.id,
              );
              tasks.add(task);
            }
            appLogger.d(
              '$_logTag streamRecurringTaskInstances snapshot=${tasks.length} parentId=$parentRecurringTaskId',
            );
            return tasks;
          });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamRecurringTaskInstances failed parentId=$parentRecurringTaskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Task>> getTasksByProject(String projectId) async {
    appLogger.d('$_logTag getTasksByProject projectId=$projectId');
    try {
      final snapshot = await logTimedAsync(
        '$_logTag getTasksByProject query projectId=$projectId',
        () => _tasksCollection.where('projectId', isEqualTo: projectId).get(),
        level: Level.debug,
      );

      final tasks = <Task>[];
      for (final doc in snapshot.docs) {
        final task = await _decryptDescriptionIfNeeded(
          Task.fromFirestore(doc),
          context: 'getTasksByProject',
          taskId: doc.id,
        );
        tasks.add(task);
      }
      appLogger.i(
        '$_logTag getTasksByProject success count=${tasks.length} projectId=$projectId',
      );
      return tasks;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getTasksByProject failed projectId=$projectId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> createTask(Task task) async {
    appLogger.i(
      '$_logTag createTask requested taskId=${task.id} projectId=${task.projectId}',
    );
    try {
      final taskToSave = await _encryptDescriptionIfNeeded(
        task,
        context: 'createTask',
      );

      await logTimedAsync(
        '$_logTag createTask write taskId=${taskToSave.id}',
        () => _tasksCollection.doc(taskToSave.id).set(taskToSave.toFirestore()),
      );
      appLogger.i('$_logTag createTask success taskId=${task.id}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag createTask failed taskId=${task.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    appLogger.i('$_logTag updateTask requested taskId=${task.id}');
    try {
      // Get the old task to check if status changed to completed
      final oldTaskDoc = await _tasksCollection.doc(task.id).get();
      final oldTask = oldTaskDoc.exists ? Task.fromFirestore(oldTaskDoc) : null;

      var updatedTask = task.copyWith(updatedAt: DateTime.now());

      updatedTask = await _encryptDescriptionIfNeeded(
        updatedTask,
        context: 'updateTask',
      );

      await logTimedAsync(
        '$_logTag updateTask write taskId=${task.id}',
        () => _tasksCollection.doc(task.id).update(updatedTask.toFirestore()),
      );
      appLogger.i('$_logTag updateTask success taskId=${task.id}');

      // Send notification if task just became completed
      if (_notificationRepository != null &&
          oldTask != null &&
          oldTask.status != TaskStatus.completed &&
          updatedTask.status == TaskStatus.completed) {
        _sendTaskCompletedNotification(updatedTask, oldTask).catchError((e) {
          appLogger.w(
            '$_logTag Failed to send task completed notification: $e',
          );
        });
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag updateTask failed taskId=${task.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    appLogger.w('$_logTag deleteTask requested taskId=$taskId');
    try {
      await logTimedAsync(
        '$_logTag deleteTask transaction taskId=$taskId',
        () => _firestore.runTransaction((transaction) async {
          transaction.delete(_tasksCollection.doc(taskId));

          final subtasksSnapshot = await _subtasksCollection
              .where('taskId', isEqualTo: taskId)
              .get();
          appLogger.d(
            '$_logTag deleteTask removing ${subtasksSnapshot.docs.length} subtasks taskId=$taskId',
          );

          for (final doc in subtasksSnapshot.docs) {
            transaction.delete(doc.reference);
          }
        }),
      );
      appLogger.i('$_logTag deleteTask success taskId=$taskId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteTask failed taskId=$taskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTasksForProject(String projectId) async {
    appLogger.w('$_logTag deleteTasksForProject projectId=$projectId');
    try {
      final tasksSnapshot = await logTimedAsync(
        '$_logTag deleteTasksForProject query projectId=$projectId',
        () => _tasksCollection.where('projectId', isEqualTo: projectId).get(),
        level: Level.debug,
      );

      for (final doc in tasksSnapshot.docs) {
        await deleteTask(doc.id);
      }
      appLogger.i(
        '$_logTag deleteTasksForProject success count=${tasksSnapshot.docs.length} projectId=$projectId',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteTasksForProject failed projectId=$projectId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ===== Subtask Operations =====

  @override
  Future<Subtask?> getSubtaskById(String subtaskId) async {
    appLogger.d('$_logTag getSubtaskById subtaskId=$subtaskId');
    try {
      final doc = await logTimedAsync(
        '$_logTag getSubtaskDoc $subtaskId',
        () => _subtasksCollection.doc(subtaskId).get(),
        level: Level.debug,
      );
      if (!doc.exists) return null;
      appLogger.i('$_logTag getSubtaskById success subtaskId=$subtaskId');
      return Subtask.fromFirestore(doc);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getSubtaskById failed subtaskId=$subtaskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Subtask>> streamSubtasksForTask(String taskId) {
    try {
      appLogger.d('$_logTag streamSubtasksForTask subscribed taskId=$taskId');
      return _subtasksCollection
          .where('taskId', isEqualTo: taskId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
            appLogger.d(
              '$_logTag streamSubtasksForTask snapshot=${snapshot.docs.length} taskId=$taskId',
            );
            return snapshot.docs
                .map((doc) => Subtask.fromFirestore(doc))
                .toList();
          });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamSubtasksForTask failed taskId=$taskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> createSubtask(Subtask subtask) async {
    appLogger.i(
      '$_logTag createSubtask subtaskId=${subtask.id} taskId=${subtask.taskId}',
    );
    try {
      await logTimedAsync(
        '$_logTag createSubtask write subtaskId=${subtask.id}',
        () => _subtasksCollection.doc(subtask.id).set(subtask.toFirestore()),
      );
      appLogger.i('$_logTag createSubtask success subtaskId=${subtask.id}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag createSubtask failed subtaskId=${subtask.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateSubtask(Subtask subtask) async {
    appLogger.i('$_logTag updateSubtask subtaskId=${subtask.id}');
    try {
      final updatedSubtask = subtask.copyWith(updatedAt: DateTime.now());
      await logTimedAsync(
        '$_logTag updateSubtask write subtaskId=${subtask.id}',
        () => _subtasksCollection
            .doc(subtask.id)
            .update(updatedSubtask.toFirestore()),
      );
      appLogger.i('$_logTag updateSubtask success subtaskId=${subtask.id}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag updateSubtask failed subtaskId=${subtask.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteSubtask(String subtaskId) async {
    appLogger.w('$_logTag deleteSubtask subtaskId=$subtaskId');
    try {
      await logTimedAsync(
        '$_logTag deleteSubtask write subtaskId=$subtaskId',
        () => _subtasksCollection.doc(subtaskId).delete(),
      );
      appLogger.i('$_logTag deleteSubtask success subtaskId=$subtaskId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteSubtask failed subtaskId=$subtaskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> toggleSubtaskCompletion(String subtaskId) async {
    appLogger.i('$_logTag toggleSubtaskCompletion subtaskId=$subtaskId');
    try {
      final subtask = await getSubtaskById(subtaskId);
      if (subtask == null) return;

      final updatedSubtask = subtask.copyWith(
        isCompleted: !subtask.isCompleted,
        updatedAt: DateTime.now(),
      );

      await logTimedAsync(
        '$_logTag toggleSubtaskCompletion write subtaskId=$subtaskId',
        () => _subtasksCollection
            .doc(subtaskId)
            .update(updatedSubtask.toFirestore()),
      );
      appLogger.i(
        '$_logTag toggleSubtaskCompletion success subtaskId=$subtaskId completed=${updatedSubtask.isCompleted}',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag toggleSubtaskCompletion failed subtaskId=$subtaskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> assignTask({
    required String taskId,
    required List<String> assigneeIds,
    required String assignedBy,
  }) async {
    appLogger.d(
      '$_logTag assignTask taskId=$taskId assignees=${assigneeIds.length}',
    );
    try {
      // Get old assignees before update
      final taskDoc = await _tasksCollection.doc(taskId).get();
      final oldAssignees =
          (taskDoc.data() as Map<String, dynamic>?)?['assignees']
              as List<dynamic>? ??
          [];
      final oldAssigneeIds = oldAssignees.cast<String>();

      await logTimedAsync(
        '$_logTag assignTask update $taskId',
        () => _tasksCollection.doc(taskId).update({
          'assignees': assigneeIds,
          'assignedBy': assignedBy,
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        level: Level.debug,
      );
      appLogger.i('$_logTag assignTask success taskId=$taskId');

      // Send notifications to newly assigned users
      try {
        final taskData = taskDoc.data() as Map<String, dynamic>?;
        final taskTitle = taskData?['title'] as String? ?? 'Task';
        final projectId = taskData?['projectId'] as String? ?? '';

        // Get project name
        String projectName = 'Project';
        if (projectId.isNotEmpty) {
          final projectDoc = await _firestore
              .collection('projects')
              .doc(projectId)
              .get();
          projectName = (projectDoc.data()?['name'] as String?) ?? 'Project';
        }

        // Get assigner name
        String assignerName = 'Someone';
        try {
          final assignerDoc = await _firestore
              .collection('users')
              .doc(assignedBy)
              .get();
          assignerName =
              assignerDoc.data()?['displayName'] as String? ??
              assignerDoc.data()?['email'] as String? ??
              'Someone';
        } catch (e) {
          appLogger.w('$_logTag Failed to get assigner name', error: e);
        }

        // Notify new assignees
        for (final assigneeId in assigneeIds) {
          if (!oldAssigneeIds.contains(assigneeId)) {
            await _notificationRepository?.sendNotification(
              userId: assigneeId,
              type: NotificationType.taskAssigned,
              title: 'New Task Assigned',
              body: '$assignerName assigned you \'$taskTitle\' in $projectName',
              data: {
                'taskId': taskId,
                'taskTitle': taskTitle,
                'projectId': projectId,
                'projectName': projectName,
                'assignedBy': assignedBy,
                'assignerName': assignerName,
              },
              actionUrl: '/projects/$projectId/tasks/$taskId',
            );
          }
        }

        // Notify removed assignees
        for (final oldAssigneeId in oldAssigneeIds) {
          if (!assigneeIds.contains(oldAssigneeId)) {
            await _notificationRepository?.sendNotification(
              userId: oldAssigneeId,
              type: NotificationType.taskUnassigned,
              title: 'Task Reassigned',
              body: 'You were unassigned from \'$taskTitle\'',
              data: {
                'taskId': taskId,
                'taskTitle': taskTitle,
                'projectId': projectId,
                'projectName': projectName,
              },
              actionUrl: '/projects/$projectId',
            );
          }
        }
      } catch (e) {
        appLogger.w(
          '$_logTag Failed to send assignment notifications',
          error: e,
        );
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag assignTask failed taskId=$taskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> unassignTask(String taskId) async {
    appLogger.d('$_logTag unassignTask taskId=$taskId');
    try {
      await logTimedAsync(
        '$_logTag unassignTask update $taskId',
        () => _tasksCollection.doc(taskId).update({
          'assignees': [],
          'assignedBy': null,
          'assignedAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        level: Level.debug,
      );
      appLogger.i('$_logTag unassignTask success taskId=$taskId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag unassignTask failed taskId=$taskId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Task>> streamTasksAssignedToUser({
    required String userId,
    String? projectId,
  }) {
    try {
      appLogger.d(
        '$_logTag streamTasksAssignedToUser userId=$userId projectId=$projectId',
      );

      Query query = _tasksCollection.where('assignees', arrayContains: userId);

      if (projectId != null) {
        query = query.where('projectId', isEqualTo: projectId);
      }

      return query.orderBy('dueDate', descending: false).snapshots().asyncMap((
        snapshot,
      ) async {
        final tasks = <Task>[];
        for (final doc in snapshot.docs) {
          final task = await _decryptDescriptionIfNeeded(
            Task.fromFirestore(doc),
            context: 'streamTasksAssignedToUser',
            taskId: doc.id,
          );
          tasks.add(task);
        }
        appLogger.d(
          '$_logTag streamTasksAssignedToUser snapshot=${tasks.length}',
        );
        return tasks;
      });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamTasksAssignedToUser failed userId=$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Task>> streamUnassignedTasks(String projectId) {
    try {
      appLogger.d('$_logTag streamUnassignedTasks projectId=$projectId');
      return _tasksCollection
          .where('projectId', isEqualTo: projectId)
          .where('assignees', isEqualTo: [])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            final tasks = <Task>[];
            for (final doc in snapshot.docs) {
              final task = await _decryptDescriptionIfNeeded(
                Task.fromFirestore(doc),
                context: 'streamUnassignedTasks',
                taskId: doc.id,
              );
              tasks.add(task);
            }
            appLogger.d(
              '$_logTag streamUnassignedTasks snapshot=${tasks.length}',
            );
            return tasks;
          });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamUnassignedTasks failed projectId=$projectId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Task> _decryptDescriptionIfNeeded(
    Task task, {
    required String context,
    required String taskId,
  }) async {
    if (!task.isDescriptionEncrypted || task.description == null) {
      return task;
    }

    try {
      final decryptedDesc = await _encryptionService.decrypt(task.description!);
      return task.copyWith(description: decryptedDesc);
    } catch (e, stackTrace) {
      appLogger.w(
        '$_logTag $context decrypt failed taskId=$taskId',
        error: e,
        stackTrace: stackTrace,
      );
      return task.copyWith(description: '[Unable to decrypt description]');
    }
  }

  Future<Task> _encryptDescriptionIfNeeded(
    Task task, {
    required String context,
  }) async {
    if (!task.isDescriptionEncrypted || task.description == null) {
      return task;
    }

    try {
      final encryptedDesc = await _encryptionService.encrypt(task.description!);
      return task.copyWith(description: encryptedDesc);
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag $context encrypt failed taskId=${task.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Helper method to send task completed notification
  Future<void> _sendTaskCompletedNotification(
    Task completedTask,
    Task oldTask,
  ) async {
    try {
      // Get project name
      String projectName = 'Personal';
      if (completedTask.projectId != null) {
        final projectDoc = await _firestore
            .collection('projects')
            .doc(completedTask.projectId)
            .get();
        projectName = projectDoc.exists
            ? (projectDoc.data()?['name'] as String? ?? 'Unknown Project')
            : 'Unknown Project';
      }

      // Get completer name (current user from auth or assignee)
      String? completerName;
      String? completerId;

      // If task has assignees, use the first one as the completer
      if (completedTask.assignees.isNotEmpty) {
        completerId = completedTask.assignees.first;
        final completerDoc = await _firestore
            .collection('users')
            .doc(completerId)
            .get();
        completerName = completerDoc.exists
            ? (completerDoc.data()?['displayName'] as String? ??
                  completerDoc.data()?['email'] as String?)
            : null;
      }

      // Notify all assignees from the old task who are not the completer
      for (final assigneeId in oldTask.assignees) {
        if (assigneeId != completerId) {
          await _notificationRepository!.sendNotification(
            userId: assigneeId,
            type: NotificationType.taskCompleted,
            title: 'Task Completed',
            body: completerName != null
                ? '$completerName completed "${completedTask.title}" in $projectName'
                : 'Task "${completedTask.title}" was completed in $projectName',
            data: {
              'taskId': completedTask.id,
              'taskTitle': completedTask.title,
              'projectId': completedTask.projectId,
              'projectName': projectName,
              if (completerId != null) 'completedBy': completerId,
              if (completerName != null) 'completerName': completerName,
            },
            actionUrl: completedTask.projectId != null
                ? '/projects/${completedTask.projectId}/tasks/${completedTask.id}'
                : '/projects/personal/tasks/${completedTask.id}',
          );
        }
      }
    } catch (e) {
      appLogger.w('$_logTag Failed to send taskCompleted notification: $e');
    }
  }

  @override
  Stream<List<Task>> streamPersonalTasks(String userId) {
    try {
      appLogger.d('$_logTag streamPersonalTasks subscribed userId=$userId');
      // Query tasks where projectId is null and user is in assignees
      return _tasksCollection
          .where('projectId', isNull: true)
          .where('assignees', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            final tasks = <Task>[];
            for (final doc in snapshot.docs) {
              final task = await _decryptDescriptionIfNeeded(
                Task.fromFirestore(doc),
                context: 'streamPersonalTasks',
                taskId: doc.id,
              );
              tasks.add(task);
            }
            appLogger.d(
              '$_logTag streamPersonalTasks snapshot=${tasks.length} userId=$userId',
            );
            return tasks;
          });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamPersonalTasks failed userId=$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
