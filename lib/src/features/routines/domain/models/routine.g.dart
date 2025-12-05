// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Routine _$RoutineFromJson(Map<String, dynamic> json) => Routine(
  id: json['id'] as String,
  userId: json['userId'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  frequency:
      $enumDecodeNullable(_$RoutineFrequencyEnumMap, json['frequency']) ??
      RoutineFrequency.daily,
  daysOfWeek:
      (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  timeOfDay: json['timeOfDay'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  reminderEnabled: json['reminderEnabled'] as bool? ?? false,
  reminderMinutesBefore: (json['reminderMinutesBefore'] as num?)?.toInt() ?? 15,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RoutineToJson(Routine instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'title': instance.title,
  'description': instance.description,
  'frequency': _$RoutineFrequencyEnumMap[instance.frequency]!,
  'daysOfWeek': instance.daysOfWeek,
  'timeOfDay': instance.timeOfDay,
  'isActive': instance.isActive,
  'reminderEnabled': instance.reminderEnabled,
  'reminderMinutesBefore': instance.reminderMinutesBefore,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$RoutineFrequencyEnumMap = {
  RoutineFrequency.daily: 'daily',
  RoutineFrequency.weekly: 'weekly',
  RoutineFrequency.custom: 'custom',
};
