import 'package:hive/hive.dart';
import 'package:tasker/src/features/tasks/domain/models/task.dart';

/// Hive TypeAdapter for Task model
/// Type ID: 2
class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 2;

  @override
  Task read(BinaryReader reader) {
    final description = reader.readString();
    final isDescriptionEncrypted = reader.readBool();
    final hasDueDate = reader.readBool();
    final dueDate = hasDueDate
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final hasUpdatedAt = reader.readBool();
    final updatedAt = hasUpdatedAt
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final recurrencePatternIndex = reader.readInt();
    final recurrenceInterval = reader.readInt();
    final hasRecurrenceEndDate = reader.readBool();
    final recurrenceEndDate = hasRecurrenceEndDate
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final parentRecurringTaskId = reader.readString();

    final id = reader.readString();
    final projectIdRaw = reader.readString();
    final projectId = projectIdRaw.isEmpty ? null : projectIdRaw;

    return Task(
      id: id,
      projectId: projectId,
      title: reader.readString(),
      description: description.isEmpty ? null : description,
      isDescriptionEncrypted: isDescriptionEncrypted,
      status: TaskStatus.values[reader.readInt()],
      dueDate: dueDate,
      assignees: (reader.readList()).cast<String>(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: updatedAt,
      recurrencePattern: RecurrencePattern.values[recurrencePatternIndex],
      recurrenceInterval: recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate,
      parentRecurringTaskId: parentRecurringTaskId.isEmpty
          ? null
          : parentRecurringTaskId,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.description ?? '');
    writer.writeBool(obj.isDescriptionEncrypted);
    writer.writeBool(obj.dueDate != null);
    if (obj.dueDate != null) {
      writer.writeInt(obj.dueDate!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.updatedAt != null);
    if (obj.updatedAt != null) {
      writer.writeInt(obj.updatedAt!.millisecondsSinceEpoch);
    }
    writer.writeInt(obj.recurrencePattern.index);
    writer.writeInt(obj.recurrenceInterval);
    writer.writeBool(obj.recurrenceEndDate != null);
    if (obj.recurrenceEndDate != null) {
      writer.writeInt(obj.recurrenceEndDate!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.parentRecurringTaskId ?? '');
    writer.writeString(obj.id);
    writer.writeString(obj.projectId ?? '');
    writer.writeString(obj.title);
    writer.writeInt(obj.status.index);
    writer.writeList(obj.assignees);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
