import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/providers.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../projects/domain/models/project.dart';
import '../../../tasks/domain/models/task.dart';
import '../../domain/models/scheduled_reminder.dart';

part 'scheduled_reminders_provider.g.dart';

/// Provider that fetches pending notifications and enriches them with task data
@riverpod
class ScheduledReminders extends _$ScheduledReminders {
  @override
  Future<List<ScheduledReminder>> build() async {
    final authState = await ref.watch(authProvider.future);
    if (authState == null) return [];

    final notificationService = NotificationService();
    final pendingNotifications = await notificationService
        .getPendingNotifications();

    if (pendingNotifications.isEmpty) return [];

    // Fetch all projects and tasks to enrich notification data
    final firestore = ref.read(firestoreProvider);
    final userDoc = firestore.collection('users').doc(authState.id);
    final reminders = <ScheduledReminder>[];
    List<QueryDocumentSnapshot>? cachedProjects;
    final projectNameCache = <String, String?>{};

    Future<Task?> findTask({String? projectId, required String taskId}) async {
      if (projectId != null && projectId.isNotEmpty) {
        final taskDoc = await userDoc
            .collection('projects')
            .doc(projectId)
            .collection('tasks')
            .doc(taskId)
            .get();
        if (taskDoc.exists) {
          return Task.fromFirestore(taskDoc);
        }
        return null;
      }

      cachedProjects ??= (await userDoc.collection('projects').get()).docs;
      for (final projectDoc in cachedProjects!) {
        final taskDoc = await projectDoc.reference
            .collection('tasks')
            .doc(taskId)
            .get();
        if (taskDoc.exists) {
          return Task.fromFirestore(taskDoc);
        }
      }
      return null;
    }

    Future<String?> projectNameFor(String projectId) async {
      if (projectNameCache.containsKey(projectId)) {
        return projectNameCache[projectId];
      }
      final projectDoc = await userDoc
          .collection('projects')
          .doc(projectId)
          .get();
      final projectName = projectDoc.exists
          ? Project.fromFirestore(projectDoc).name
          : null;
      projectNameCache[projectId] = projectName;
      return projectName;
    }

    for (final notification in pendingNotifications) {
      try {
        // Parse payload to get taskId (and optional projectId for backward compatibility)
        final payload = notification.payload ?? '';
        if (!payload.startsWith('task:')) continue;

        final data = payload.substring('task:'.length);
        final segments = data.split(':');
        String? projectIdFromPayload;
        late String taskId;

        if (segments.length >= 2) {
          projectIdFromPayload = segments[0];
          taskId = segments[1];
        } else if (segments.isNotEmpty && segments.first.isNotEmpty) {
          taskId = segments.first;
        } else {
          continue;
        }

        final task = await findTask(
          projectId: projectIdFromPayload,
          taskId: taskId,
        );

        if (task == null) continue;

        final projectId = task.projectId;
        final projectName = projectId != null
            ? await projectNameFor(projectId)
            : 'Personal';

        reminders.add(
          ScheduledReminder(
            id: notification.id,
            taskId: task.id,
            projectId: projectId ?? 'personal',
            taskTitle: task.title,
            scheduledDate:
                DateTime.now(), // Placeholder - notification API doesn't expose scheduled time
            projectName: projectName,
            taskDueDate: task.dueDate,
          ),
        );
      } catch (e) {
        // Skip invalid notifications
        continue;
      }
    }

    return reminders;
  }

  /// Refresh the list of scheduled reminders
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
