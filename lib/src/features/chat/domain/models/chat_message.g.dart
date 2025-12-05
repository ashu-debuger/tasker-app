// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  text: json['text'] as String,
  isEncrypted: json['isEncrypted'] as bool? ?? false,
  createdAt: _dateTimeFromJson(json['createdAt'] as String),
  editedAt: _dateTimeFromJsonNullable(json['editedAt'] as String?),
  isDeleted: json['isDeleted'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'text': instance.text,
      'isEncrypted': instance.isEncrypted,
      'createdAt': _dateTimeToJson(instance.createdAt),
      'editedAt': _dateTimeToJsonNullable(instance.editedAt),
      'isDeleted': instance.isDeleted,
    };
