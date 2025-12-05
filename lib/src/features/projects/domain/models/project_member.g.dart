// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectMember _$ProjectMemberFromJson(Map<String, dynamic> json) =>
    ProjectMember(
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      role: $enumDecode(_$ProjectRoleEnumMap, json['role']),
      addedAt: DateTime.parse(json['addedAt'] as String),
      addedBy: json['addedBy'] as String,
    );

Map<String, dynamic> _$ProjectMemberToJson(ProjectMember instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'role': _$ProjectRoleEnumMap[instance.role]!,
      'addedAt': instance.addedAt.toIso8601String(),
      'addedBy': instance.addedBy,
    };

const _$ProjectRoleEnumMap = {
  ProjectRole.owner: 'owner',
  ProjectRole.admin: 'admin',
  ProjectRole.editor: 'editor',
  ProjectRole.viewer: 'viewer',
};
