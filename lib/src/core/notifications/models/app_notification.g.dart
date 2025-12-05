// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'body': instance.body,
      'imageUrl': instance.imageUrl,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'isRead': instance.isRead,
      'actionUrl': instance.actionUrl,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.invitationReceived: 'invitationReceived',
  NotificationType.invitationAccepted: 'invitationAccepted',
  NotificationType.invitationDeclined: 'invitationDeclined',
  NotificationType.taskAssigned: 'taskAssigned',
  NotificationType.taskReassigned: 'taskReassigned',
  NotificationType.taskUnassigned: 'taskUnassigned',
  NotificationType.taskCompleted: 'taskCompleted',
  NotificationType.taskCommentAdded: 'taskCommentAdded',
  NotificationType.taskDueSoon: 'taskDueSoon',
  NotificationType.taskOverdue: 'taskOverdue',
  NotificationType.memberAdded: 'memberAdded',
  NotificationType.memberRemoved: 'memberRemoved',
  NotificationType.memberRoleChanged: 'memberRoleChanged',
  NotificationType.projectShared: 'projectShared',
  NotificationType.projectArchived: 'projectArchived',
  NotificationType.taskReminder: 'taskReminder',
  NotificationType.routineReminder: 'routineReminder',
};
