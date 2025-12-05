// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mind_map.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MindMap _$MindMapFromJson(Map<String, dynamic> json) => MindMap(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  userId: json['userId'] as String,
  rootNodeId: json['rootNodeId'] as String,
  createdAt: MindMap._timestampFromJson(json['createdAt']),
  updatedAt: MindMap._nullableTimestampFromJson(json['updatedAt']),
  collaboratorIds:
      (json['collaboratorIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$MindMapToJson(MindMap instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'userId': instance.userId,
  'rootNodeId': instance.rootNodeId,
  'createdAt': MindMap._timestampToJson(instance.createdAt),
  'updatedAt': MindMap._timestampToJson(instance.updatedAt),
  'collaboratorIds': instance.collaboratorIds,
};

MindMapNode _$MindMapNodeFromJson(Map<String, dynamic> json) => MindMapNode(
  id: json['id'] as String,
  mindMapId: json['mindMapId'] as String,
  text: json['text'] as String,
  parentId: json['parentId'] as String?,
  childIds:
      (json['childIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  color:
      $enumDecodeNullable(_$NodeColorEnumMap, json['color']) ?? NodeColor.blue,
  isCollapsed: json['isCollapsed'] as bool? ?? false,
  createdAt: MindMapNode._timestampFromJson(json['createdAt']),
  updatedAt: MindMapNode._nullableTimestampFromJson(json['updatedAt']),
);

Map<String, dynamic> _$MindMapNodeToJson(MindMapNode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mindMapId': instance.mindMapId,
      'text': instance.text,
      'parentId': instance.parentId,
      'childIds': instance.childIds,
      'x': instance.x,
      'y': instance.y,
      'color': _$NodeColorEnumMap[instance.color]!,
      'isCollapsed': instance.isCollapsed,
      'createdAt': MindMapNode._timestampToJson(instance.createdAt),
      'updatedAt': MindMapNode._timestampToJson(instance.updatedAt),
    };

const _$NodeColorEnumMap = {
  NodeColor.blue: 'blue',
  NodeColor.green: 'green',
  NodeColor.yellow: 'yellow',
  NodeColor.orange: 'orange',
  NodeColor.red: 'red',
  NodeColor.purple: 'purple',
  NodeColor.pink: 'pink',
  NodeColor.gray: 'gray',
};
