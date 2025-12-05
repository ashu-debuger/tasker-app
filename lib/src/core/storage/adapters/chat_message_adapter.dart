import 'package:hive/hive.dart';
import 'package:tasker/src/features/chat/domain/models/chat_message.dart';

/// Hive TypeAdapter for ChatMessage model
/// Type ID: 4
class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 4;

  @override
  ChatMessage read(BinaryReader reader) {
    final hasEditedAt = reader.readBool();
    final editedAt = hasEditedAt
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;

    return ChatMessage(
      id: reader.readString(),
      projectId: reader.readString(),
      senderId: reader.readString(),
      senderName: reader.readString(),
      text: reader.readString(),
      isEncrypted: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      editedAt: editedAt,
      isDeleted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer.writeBool(obj.editedAt != null);
    if (obj.editedAt != null) {
      writer.writeInt(obj.editedAt!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.id);
    writer.writeString(obj.projectId);
    writer.writeString(obj.senderId);
    writer.writeString(obj.senderName);
    writer.writeString(obj.text);
    writer.writeBool(obj.isEncrypted);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isDeleted);
  }
}
