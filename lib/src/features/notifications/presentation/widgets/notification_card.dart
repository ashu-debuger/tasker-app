import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/notifications/models/app_notification.dart';
import '../../../../core/notifications/models/notification_type.dart';
import '../notifiers/notification_notifier.dart';

class NotificationCard extends ConsumerWidget {
  final AppNotification notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) {
        ref
            .read(notificationListProvider.notifier)
            .deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () {
          if (isUnread) {
            ref
                .read(notificationListProvider.notifier)
                .markAsRead(notification.id);
          }

          if (notification.actionUrl != null) {
            context.push(notification.actionUrl!);
          }
        },
        child: Container(
          color: isUnread
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : null,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(notification.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final theme = Theme.of(context);
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.invitationReceived:
        iconData = Icons.mail_outline;
        iconColor = Colors.blue;
        break;
      case NotificationType.invitationAccepted:
      case NotificationType.invitationDeclined:
        iconData = Icons.how_to_reg_outlined;
        iconColor = Colors.green;
        break;
      case NotificationType.taskAssigned:
      case NotificationType.taskReassigned:
        iconData = Icons.assignment_ind_outlined;
        iconColor = Colors.orange;
        break;
      case NotificationType.taskUnassigned:
        iconData = Icons.assignment_outlined;
        iconColor = Colors.grey;
        break;
      case NotificationType.taskCompleted:
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case NotificationType.taskCommentAdded:
        iconData = Icons.comment_outlined;
        iconColor = Colors.blue;
        break;
      case NotificationType.taskDueSoon:
      case NotificationType.taskOverdue:
        iconData = Icons.alarm;
        iconColor = Colors.red;
        break;
      case NotificationType.memberAdded:
        iconData = Icons.person_add_outlined;
        iconColor = Colors.purple;
        break;
      case NotificationType.memberRemoved:
        iconData = Icons.person_remove_outlined;
        iconColor = Colors.red;
        break;
      case NotificationType.memberRoleChanged:
        iconData = Icons.admin_panel_settings_outlined;
        iconColor = Colors.indigo;
        break;
      case NotificationType.projectShared:
        iconData = Icons.share_outlined;
        iconColor = Colors.teal;
        break;
      case NotificationType.projectArchived:
        iconData = Icons.archive_outlined;
        iconColor = Colors.grey;
        break;
      case NotificationType.taskReminder:
      case NotificationType.routineReminder:
        iconData = Icons.notifications_outlined;
        iconColor = theme.colorScheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(dateTime);
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }
}
