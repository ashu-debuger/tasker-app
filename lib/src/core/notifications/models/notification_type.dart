/// Types of notifications in the app
enum NotificationType {
  // Invitation notifications
  invitationReceived,
  invitationAccepted,
  invitationDeclined,

  // Task assignment
  taskAssigned,
  taskReassigned,
  taskUnassigned,

  // Task updates (for assigned tasks)
  taskCompleted,
  taskCommentAdded,
  taskDueSoon,
  taskOverdue,

  // Member activity
  memberAdded,
  memberRemoved,
  memberRoleChanged,

  // Project updates
  projectShared,
  projectArchived,

  // Reminder notifications
  taskReminder,
  routineReminder;

  /// Display name for the notification type
  String get displayName {
    switch (this) {
      case NotificationType.invitationReceived:
        return 'Project Invitation';
      case NotificationType.invitationAccepted:
        return 'Invitation Accepted';
      case NotificationType.invitationDeclined:
        return 'Invitation Declined';
      case NotificationType.taskAssigned:
        return 'Task Assigned';
      case NotificationType.taskReassigned:
        return 'Task Reassigned';
      case NotificationType.taskUnassigned:
        return 'Task Unassigned';
      case NotificationType.taskCompleted:
        return 'Task Completed';
      case NotificationType.taskCommentAdded:
        return 'New Comment';
      case NotificationType.taskDueSoon:
        return 'Task Due Soon';
      case NotificationType.taskOverdue:
        return 'Task Overdue';
      case NotificationType.memberAdded:
        return 'New Member';
      case NotificationType.memberRemoved:
        return 'Member Removed';
      case NotificationType.memberRoleChanged:
        return 'Role Changed';
      case NotificationType.projectShared:
        return 'Project Shared';
      case NotificationType.projectArchived:
        return 'Project Archived';
      case NotificationType.taskReminder:
        return 'Task Reminder';
      case NotificationType.routineReminder:
        return 'Routine Reminder';
    }
  }

  /// Icon for the notification type
  String get iconName {
    switch (this) {
      case NotificationType.invitationReceived:
        return 'mail';
      case NotificationType.invitationAccepted:
      case NotificationType.invitationDeclined:
        return 'how_to_reg';
      case NotificationType.taskAssigned:
      case NotificationType.taskReassigned:
        return 'assignment_ind';
      case NotificationType.taskUnassigned:
        return 'assignment';
      case NotificationType.taskCompleted:
        return 'check_circle';
      case NotificationType.taskCommentAdded:
        return 'comment';
      case NotificationType.taskDueSoon:
      case NotificationType.taskOverdue:
        return 'alarm';
      case NotificationType.memberAdded:
        return 'person_add';
      case NotificationType.memberRemoved:
        return 'person_remove';
      case NotificationType.memberRoleChanged:
        return 'admin_panel_settings';
      case NotificationType.projectShared:
        return 'share';
      case NotificationType.projectArchived:
        return 'archive';
      case NotificationType.taskReminder:
      case NotificationType.routineReminder:
        return 'notifications';
    }
  }
}
