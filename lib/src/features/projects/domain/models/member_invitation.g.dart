// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberInvitation _$MemberInvitationFromJson(Map<String, dynamic> json) =>
    MemberInvitation(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      invitedByUserId: json['invitedByUserId'] as String,
      invitedByUserName: json['invitedByUserName'] as String,
      invitedEmail: json['invitedEmail'] as String,
      invitedUserId: json['invitedUserId'] as String?,
      status: $enumDecode(_$InvitationStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      role: $enumDecode(_$ProjectRoleEnumMap, json['role']),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$MemberInvitationToJson(MemberInvitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'projectName': instance.projectName,
      'invitedByUserId': instance.invitedByUserId,
      'invitedByUserName': instance.invitedByUserName,
      'invitedEmail': instance.invitedEmail,
      'invitedUserId': instance.invitedUserId,
      'status': _$InvitationStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'role': _$ProjectRoleEnumMap[instance.role]!,
      'message': instance.message,
    };

const _$InvitationStatusEnumMap = {
  InvitationStatus.pending: 'pending',
  InvitationStatus.accepted: 'accepted',
  InvitationStatus.declined: 'declined',
  InvitationStatus.cancelled: 'cancelled',
};

const _$ProjectRoleEnumMap = {
  ProjectRole.owner: 'owner',
  ProjectRole.admin: 'admin',
  ProjectRole.editor: 'editor',
  ProjectRole.viewer: 'viewer',
};
