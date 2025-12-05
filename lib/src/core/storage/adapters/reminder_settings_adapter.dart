import 'package:hive/hive.dart';
import 'package:tasker/src/features/settings/domain/models/reminder_settings.dart';

/// Hive TypeAdapter for ReminderSettings model
/// Type ID: 11
class ReminderSettingsAdapter extends TypeAdapter<ReminderSettings> {
  @override
  final int typeId = 11;

  @override
  ReminderSettings read(BinaryReader reader) {
    final taskLeadMinutes = reader.readInt();
    final routineLeadMinutes = reader.readInt();
    return ReminderSettings(
      taskLeadMinutes: taskLeadMinutes,
      routineLeadMinutes: routineLeadMinutes,
    );
  }

  @override
  void write(BinaryWriter writer, ReminderSettings obj) {
    writer
      ..writeInt(obj.taskLeadMinutes)
      ..writeInt(obj.routineLeadMinutes);
  }
}
