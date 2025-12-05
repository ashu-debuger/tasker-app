import 'package:hive/hive.dart';
import 'package:tasker/src/features/projects/domain/models/project.dart';

/// Hive TypeAdapter for Project model
/// Type ID: 1
class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 1;

  @override
  Project read(BinaryReader reader) {
    final description = reader.readString();
    final hasUpdatedAt = reader.readBool();
    final updatedAt = hasUpdatedAt
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;

    return Project(
      id: reader.readString(),
      name: reader.readString(),
      description: description.isEmpty ? null : description,
      members: (reader.readList()).cast<String>(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: updatedAt,
      ownerId: '', // Legacy data - owner unknown
      memberRoles: const {},
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer.writeString(obj.description ?? '');
    writer.writeBool(obj.updatedAt != null);
    if (obj.updatedAt != null) {
      writer.writeInt(obj.updatedAt!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeList(obj.members);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
