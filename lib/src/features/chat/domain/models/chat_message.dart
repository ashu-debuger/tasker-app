import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

/// Chat message model for project communication
@JsonSerializable()
class ChatMessage extends Equatable {
  /// Unique message identifier
  final String id;

  /// ID of the project this message belongs to
  final String projectId;

  /// User ID of the message sender
  final String senderId;

  /// Display name of the sender (cached for offline viewing)
  final String senderName;

  /// Message text content
  final String text;

  /// Whether this message is encrypted (for future E2E encryption)
  final bool isEncrypted;

  /// Timestamp when message was created
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// Timestamp when message was last edited (null if never edited)
  @JsonKey(fromJson: _dateTimeFromJsonNullable, toJson: _dateTimeToJsonNullable)
  final DateTime? editedAt;

  /// Whether this message has been deleted (soft delete)
  final bool isDeleted;

  const ChatMessage({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.isEncrypted = false,
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
  });

  /// Check if message was edited
  bool get isEdited => editedAt != null;

  /// Creates a copy of this message with updated fields
  ChatMessage copyWith({
    String? id,
    String? projectId,
    String? senderId,
    String? senderName,
    String? text,
    bool? isEncrypted,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isDeleted,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Converts this message to a JSON map
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  /// Creates a message from a JSON map
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// Converts to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'isEncrypted': isEncrypted,
      'createdAt': createdAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  /// Creates message from Firestore document data
  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      projectId: data['projectId'] as String,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      text: data['text'] as String,
      isEncrypted: data['isEncrypted'] as bool? ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
      editedAt: data['editedAt'] != null
          ? DateTime.parse(data['editedAt'] as String)
          : null,
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    senderId,
    senderName,
    text,
    isEncrypted,
    createdAt,
    editedAt,
    isDeleted,
  ];

  @override
  String toString() {
    return 'ChatMessage(id: $id, projectId: $projectId, senderId: $senderId, '
        'text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, '
        'isEncrypted: $isEncrypted, createdAt: $createdAt)';
  }
}

/// Helper functions for DateTime serialization
DateTime _dateTimeFromJson(String json) => DateTime.parse(json);

String _dateTimeToJson(DateTime dateTime) => dateTime.toIso8601String();

DateTime? _dateTimeFromJsonNullable(String? json) =>
    json != null ? DateTime.parse(json) : null;

String? _dateTimeToJsonNullable(DateTime? dateTime) =>
    dateTime?.toIso8601String();
