import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Offset;
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mind_map.g.dart';

/// Represents a mind map with hierarchical nodes
@HiveType(typeId: 7)
@JsonSerializable()
class MindMap {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String userId;

  @HiveField(4)
  final String rootNodeId;

  @HiveField(5)
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;

  @HiveField(6)
  @JsonKey(fromJson: _nullableTimestampFromJson, toJson: _timestampToJson)
  final DateTime? updatedAt;

  @HiveField(7)
  final List<String> collaboratorIds;

  const MindMap({
    required this.id,
    required this.title,
    this.description,
    required this.userId,
    required this.rootNodeId,
    required this.createdAt,
    this.updatedAt,
    this.collaboratorIds = const [],
  });

  factory MindMap.fromJson(Map<String, dynamic> json) =>
      _$MindMapFromJson(json);
  Map<String, dynamic> toJson() => _$MindMapToJson(this);

  MindMap copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    String? rootNodeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? collaboratorIds,
  }) {
    return MindMap(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      rootNodeId: rootNodeId ?? this.rootNodeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
    );
  }

  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.parse(timestamp as String);
  }

  static DateTime? _nullableTimestampFromJson(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.parse(timestamp as String);
  }

  static dynamic _timestampToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

/// Node colors for visual organization
@HiveType(typeId: 8)
enum NodeColor {
  @HiveField(0)
  blue,
  @HiveField(1)
  green,
  @HiveField(2)
  yellow,
  @HiveField(3)
  orange,
  @HiveField(4)
  red,
  @HiveField(5)
  purple,
  @HiveField(6)
  pink,
  @HiveField(7)
  gray;

  String get displayName {
    switch (this) {
      case NodeColor.blue:
        return 'Blue';
      case NodeColor.green:
        return 'Green';
      case NodeColor.yellow:
        return 'Yellow';
      case NodeColor.orange:
        return 'Orange';
      case NodeColor.red:
        return 'Red';
      case NodeColor.purple:
        return 'Purple';
      case NodeColor.pink:
        return 'Pink';
      case NodeColor.gray:
        return 'Gray';
    }
  }
}

/// Represents a node in a mind map
@HiveType(typeId: 9)
@JsonSerializable()
class MindMapNode {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String mindMapId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final String? parentId;

  @HiveField(4)
  final List<String> childIds;

  @HiveField(5)
  final double x;

  @HiveField(6)
  final double y;

  @HiveField(7)
  @JsonKey(defaultValue: NodeColor.blue)
  final NodeColor color;

  @HiveField(8)
  @JsonKey(defaultValue: false)
  final bool isCollapsed;

  @HiveField(9)
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;

  @HiveField(10)
  @JsonKey(fromJson: _nullableTimestampFromJson, toJson: _timestampToJson)
  final DateTime? updatedAt;

  const MindMapNode({
    required this.id,
    required this.mindMapId,
    required this.text,
    this.parentId,
    this.childIds = const [],
    required this.x,
    required this.y,
    this.color = NodeColor.blue,
    this.isCollapsed = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory MindMapNode.fromJson(Map<String, dynamic> json) =>
      _$MindMapNodeFromJson(json);
  Map<String, dynamic> toJson() => _$MindMapNodeToJson(this);

  MindMapNode copyWith({
    String? id,
    String? mindMapId,
    String? text,
    String? parentId,
    List<String>? childIds,
    double? x,
    double? y,
    NodeColor? color,
    bool? isCollapsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      mindMapId: mindMapId ?? this.mindMapId,
      text: text ?? this.text,
      parentId: parentId ?? this.parentId,
      childIds: childIds ?? this.childIds,
      x: x ?? this.x,
      y: y ?? this.y,
      color: color ?? this.color,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this node is a root node
  bool get isRoot => parentId == null;

  /// Check if this node is a leaf node (no children)
  bool get isLeaf => childIds.isEmpty;

  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.parse(timestamp as String);
  }

  static DateTime? _nullableTimestampFromJson(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.parse(timestamp as String);
  }

  static dynamic _timestampToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

/// Direction for placing child nodes relative to parent
enum NodeDirection {
  right,
  left,
  up,
  down;

  String get displayName {
    switch (this) {
      case NodeDirection.right:
        return 'Right →';
      case NodeDirection.left:
        return 'Left ←';
      case NodeDirection.up:
        return 'Up ↑';
      case NodeDirection.down:
        return 'Down ↓';
    }
  }

  /// Get offset for positioning child node relative to parent
  Offset getOffset({
    double spacing = 300.0,
    double verticalSpread = 120.0,
    int childIndex = 0,
  }) {
    switch (this) {
      case NodeDirection.right:
        return Offset(spacing, childIndex * verticalSpread);
      case NodeDirection.left:
        return Offset(-spacing, childIndex * verticalSpread);
      case NodeDirection.up:
        return Offset(childIndex * verticalSpread, -spacing);
      case NodeDirection.down:
        return Offset(childIndex * verticalSpread, spacing);
    }
  }
}
