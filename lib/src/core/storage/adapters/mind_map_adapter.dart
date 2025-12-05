import 'package:hive/hive.dart';
import '../../../features/mind_maps/domain/models/mind_map.dart';

/// Hive adapter for MindMap model
class MindMapAdapter extends TypeAdapter<MindMap> {
  @override
  final int typeId = 7;

  @override
  MindMap read(BinaryReader reader) {
    return MindMap(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readBool() ? reader.readString() : null,
      userId: reader.readString(),
      rootNodeId: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      collaboratorIds: (reader.readList()).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MindMap obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeBool(obj.description != null);
    if (obj.description != null) {
      writer.writeString(obj.description!);
    }
    writer.writeString(obj.userId);
    writer.writeString(obj.rootNodeId);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.updatedAt != null);
    if (obj.updatedAt != null) {
      writer.writeInt(obj.updatedAt!.millisecondsSinceEpoch);
    }
    writer.writeList(obj.collaboratorIds);
  }
}

/// Hive adapter for NodeColor enum
class NodeColorAdapter extends TypeAdapter<NodeColor> {
  @override
  final int typeId = 8;

  @override
  NodeColor read(BinaryReader reader) {
    return NodeColor.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, NodeColor obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive adapter for MindMapNode model
class MindMapNodeAdapter extends TypeAdapter<MindMapNode> {
  @override
  final int typeId = 9;

  @override
  MindMapNode read(BinaryReader reader) {
    return MindMapNode(
      id: reader.readString(),
      mindMapId: reader.readString(),
      text: reader.readString(),
      parentId: reader.readBool() ? reader.readString() : null,
      childIds: (reader.readList()).cast<String>(),
      x: reader.readDouble(),
      y: reader.readDouble(),
      color: NodeColor.values[reader.readByte()],
      isCollapsed: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, MindMapNode obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.mindMapId);
    writer.writeString(obj.text);
    writer.writeBool(obj.parentId != null);
    if (obj.parentId != null) {
      writer.writeString(obj.parentId!);
    }
    writer.writeList(obj.childIds);
    writer.writeDouble(obj.x);
    writer.writeDouble(obj.y);
    writer.writeByte(obj.color.index);
    writer.writeBool(obj.isCollapsed);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.updatedAt != null);
    if (obj.updatedAt != null) {
      writer.writeInt(obj.updatedAt!.millisecondsSinceEpoch);
    }
  }
}
