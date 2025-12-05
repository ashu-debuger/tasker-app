import 'package:hive/hive.dart';
import 'package:tasker/src/features/diary/models/diary_entry.dart';

/// Hive TypeAdapter for DiaryEntry model
/// Type ID: 12 (next available after ReminderSettings=11)
class DiaryEntryAdapter extends TypeAdapter<DiaryEntry> {
  @override
  final int typeId = 12;

  @override
  DiaryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Handle migration: if entryDate (field 8) doesn't exist, use createdAt
    final createdAt = fields[3] as DateTime;
    final entryDate =
        fields[8] as DateTime? ??
        DateTime(createdAt.year, createdAt.month, createdAt.day);

    return DiaryEntry(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      entryDate: entryDate,
      createdAt: createdAt,
      updatedAt: fields[4] as DateTime,
      tags: (fields[5] as List).cast<String>(),
      mood: fields[6] as String?,
      linkedTaskId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DiaryEntry obj) {
    writer
      ..writeByte(9) // Updated to 9 fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.mood)
      ..writeByte(7)
      ..write(obj.linkedTaskId)
      ..writeByte(8)
      ..write(obj.entryDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
