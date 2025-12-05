import 'package:hive/hive.dart';
import 'package:tasker/src/features/auth/domain/models/app_user.dart';

/// Hive TypeAdapter for AppUser model
/// Type ID: 0
class AppUserAdapter extends TypeAdapter<AppUser> {
  @override
  final int typeId = 0;

  @override
  AppUser read(BinaryReader reader) {
    final displayName = reader.readString();
    final photoUrl = reader.readString();
    final hasCreatedAt = reader.readBool();
    final createdAt = hasCreatedAt
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final hasUpdatedAt = reader.readBool();
    final updatedAt = hasUpdatedAt
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;

    return AppUser(
      id: reader.readString(),
      email: reader.readString(),
      displayName: displayName.isEmpty ? null : displayName,
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, AppUser obj) {
    writer.writeString(obj.displayName ?? '');
    writer.writeString(obj.photoUrl ?? '');
    writer.writeBool(obj.createdAt != null);
    if (obj.createdAt != null) {
      writer.writeInt(obj.createdAt!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.updatedAt != null);
    if (obj.updatedAt != null) {
      writer.writeInt(obj.updatedAt!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.id);
    writer.writeString(obj.email);
  }
}
