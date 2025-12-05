// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: json['id'] as String,
  projectId: json['projectId'] as String?,
  title: json['title'] as String,
  description: json['description'] as String?,
  isDescriptionEncrypted: json['isDescriptionEncrypted'] as bool? ?? false,
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  status:
      $enumDecodeNullable(_$TaskStatusEnumMap, json['status']) ??
      TaskStatus.pending,
  priority:
      $enumDecodeNullable(_$TaskPriorityEnumMap, json['priority']) ??
      TaskPriority.medium,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  reminderEnabled: json['reminderEnabled'] as bool? ?? true,
  assignees: (json['assignees'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  assignedBy: json['assignedBy'] as String?,
  assignedAt: json['assignedAt'] == null
      ? null
      : DateTime.parse(json['assignedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  recurrencePattern:
      $enumDecodeNullable(
        _$RecurrencePatternEnumMap,
        json['recurrencePattern'],
      ) ??
      RecurrencePattern.none,
  recurrenceInterval: (json['recurrenceInterval'] as num?)?.toInt() ?? 1,
  recurrenceEndDate: json['recurrenceEndDate'] == null
      ? null
      : DateTime.parse(json['recurrenceEndDate'] as String),
  parentRecurringTaskId: json['parentRecurringTaskId'] as String?,
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'title': instance.title,
  'description': instance.description,
  'isDescriptionEncrypted': instance.isDescriptionEncrypted,
  'dueDate': instance.dueDate?.toIso8601String(),
  'status': _$TaskStatusEnumMap[instance.status]!,
  'priority': _$TaskPriorityEnumMap[instance.priority]!,
  'tags': instance.tags,
  'reminderEnabled': instance.reminderEnabled,
  'assignees': instance.assignees,
  'assignedBy': instance.assignedBy,
  'assignedAt': instance.assignedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'recurrencePattern': _$RecurrencePatternEnumMap[instance.recurrencePattern]!,
  'recurrenceInterval': instance.recurrenceInterval,
  'recurrenceEndDate': instance.recurrenceEndDate?.toIso8601String(),
  'parentRecurringTaskId': instance.parentRecurringTaskId,
};

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'pending',
  TaskStatus.inProgress: 'in_progress',
  TaskStatus.completed: 'completed',
};

const _$TaskPriorityEnumMap = {
  TaskPriority.low: 'low',
  TaskPriority.medium: 'medium',
  TaskPriority.high: 'high',
  TaskPriority.urgent: 'urgent',
};

const _$RecurrencePatternEnumMap = {
  RecurrencePattern.none: 'none',
  RecurrencePattern.daily: 'daily',
  RecurrencePattern.weekly: 'weekly',
  RecurrencePattern.monthly: 'monthly',
};
