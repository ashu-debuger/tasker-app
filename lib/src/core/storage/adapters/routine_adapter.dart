import 'package:hive/hive.dart';
import 'package:tasker/src/features/routines/domain/models/routine.dart';

/// Hive TypeAdapter for Routine model
/// Type ID: 10
class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 10;

  @override
  Routine read(BinaryReader reader) {
    final description = reader.readString();
    final frequencyIndex = reader.readInt();
    final daysOfWeekLength = reader.readInt();
    final daysOfWeek = List<int>.generate(
      daysOfWeekLength,
      (_) => reader.readInt(),
    );
    final timeOfDay = reader.readString();
    final hasUpdatedAt = reader.readBool();
    final updatedAt = hasUpdatedAt
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;

    return Routine(
      id: reader.readString(),
      userId: reader.readString(),
      title: reader.readString(),
      description: description.isEmpty ? null : description,
      frequency: RoutineFrequency.values[frequencyIndex],
      daysOfWeek: daysOfWeek,
      timeOfDay: timeOfDay.isEmpty ? null : timeOfDay,
      isActive: reader.readBool(),
      reminderEnabled: reader.readBool(),
      reminderMinutesBefore: reader.readInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer.writeString(obj.description ?? '');
    writer.writeInt(obj.frequency.index);
    writer.writeInt(obj.daysOfWeek.length);
    for (final day in obj.daysOfWeek) {
      writer.writeInt(day);
    }
    writer.writeString(obj.timeOfDay ?? '');
    writer.writeBool(obj.updatedAt != null);
    if (obj.updatedAt != null) {
      writer.writeInt(obj.updatedAt!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.title);
    writer.writeBool(obj.isActive);
    writer.writeBool(obj.reminderEnabled);
    writer.writeInt(obj.reminderMinutesBefore);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
