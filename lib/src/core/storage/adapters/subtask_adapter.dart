import 'package:hive/hive.dart';
import 'package:tasker/src/features/tasks/domain/models/subtask.dart';

/// Hive TypeAdapter for Subtask model
/// Type ID: 3
class SubtaskAdapter extends TypeAdapter<Subtask> {
  @override
  final int typeId = 3;

  @override
  Subtask read(BinaryReader reader) {
    final hasUpdatedAt = reader.readBool();
    final updatedAt = hasUpdatedAt
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;

    return Subtask(
      id: reader.readString(),
      taskId: reader.readString(),
      title: reader.readString(),
      isCompleted: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, Subtask obj) {
    writer.writeBool(obj.updatedAt != null);
    if (obj.updatedAt != null) {
      writer.writeInt(obj.updatedAt!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.id);
    writer.writeString(obj.taskId);
    writer.writeString(obj.title);
    writer.writeBool(obj.isCompleted);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
