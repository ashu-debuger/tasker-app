import 'package:hive/hive.dart';
import 'package:tasker/src/features/sticky_notes/domain/models/sticky_note.dart';

/// Hive TypeAdapter for NotePosition model
/// Type ID: 6
class NotePositionAdapter extends TypeAdapter<NotePosition> {
  @override
  final int typeId = 6;

  @override
  NotePosition read(BinaryReader reader) {
    return NotePosition(x: reader.readDouble(), y: reader.readDouble());
  }

  @override
  void write(BinaryWriter writer, NotePosition obj) {
    writer.writeDouble(obj.x);
    writer.writeDouble(obj.y);
  }
}

/// Hive TypeAdapter for StickyNote model
/// Type ID: 5
class StickyNoteAdapter extends TypeAdapter<StickyNote> {
  @override
  final int typeId = 5;

  @override
  StickyNote read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final content = reader.readString();
    final colorIndex = reader.readInt();
    final x = reader.readDouble();
    final y = reader.readDouble();
    final userId = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasUpdatedAt = reader.readBool();
    final updatedAt = hasUpdatedAt
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final zIndex = reader.readInt();
    final width = reader.readDouble();
    final height = reader.readDouble();

    return StickyNote(
      id: id,
      title: title.isEmpty ? null : title,
      content: content,
      color: NoteColor.values[colorIndex],
      position: NotePosition(x: x, y: y),
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      zIndex: zIndex,
      width: width,
      height: height,
    );
  }

  @override
  void write(BinaryWriter writer, StickyNote obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title ?? '');
    writer.writeString(obj.content);
    writer.writeInt(obj.color.index);
    writer.writeDouble(obj.position.x);
    writer.writeDouble(obj.position.y);
    writer.writeString(obj.userId);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.updatedAt != null);
    if (obj.updatedAt != null) {
      writer.writeInt(obj.updatedAt!.millisecondsSinceEpoch);
    }
    writer.writeInt(obj.zIndex);
    writer.writeDouble(obj.width);
    writer.writeDouble(obj.height);
  }
}
