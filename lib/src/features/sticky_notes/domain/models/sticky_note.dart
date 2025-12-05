import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sticky_note.g.dart';

/// Position of a sticky note on the canvas
@HiveType(typeId: 6)
@JsonSerializable()
class NotePosition extends Equatable {
  /// X coordinate (left position)
  @HiveField(0)
  final double x;

  /// Y coordinate (top position)
  @HiveField(1)
  final double y;

  const NotePosition({required this.x, required this.y});

  /// Default position (top-left)
  static const zero = NotePosition(x: 0, y: 0);

  /// JSON serialization
  factory NotePosition.fromJson(Map<String, dynamic> json) =>
      _$NotePositionFromJson(json);

  Map<String, dynamic> toJson() => _$NotePositionToJson(this);

  /// Convert to Offset for Flutter rendering
  Offset toOffset() => Offset(x, y);

  /// Create from Offset
  factory NotePosition.fromOffset(Offset offset) =>
      NotePosition(x: offset.dx, y: offset.dy);

  @override
  List<Object?> get props => [x, y];
}

/// Color preset for sticky notes
enum NoteColor {
  @JsonValue('yellow')
  yellow,
  @JsonValue('pink')
  pink,
  @JsonValue('blue')
  blue,
  @JsonValue('green')
  green,
  @JsonValue('purple')
  purple,
  @JsonValue('orange')
  orange;

  /// Display color for the note
  Color get color {
    switch (this) {
      case NoteColor.yellow:
        return const Color(0xFFFFF9C4);
      case NoteColor.pink:
        return const Color(0xFFF8BBD0);
      case NoteColor.blue:
        return const Color(0xFFBBDEFB);
      case NoteColor.green:
        return const Color(0xFFC8E6C9);
      case NoteColor.purple:
        return const Color(0xFFE1BEE7);
      case NoteColor.orange:
        return const Color(0xFFFFCCBC);
    }
  }

  /// Display name for the color
  String get displayName {
    switch (this) {
      case NoteColor.yellow:
        return 'Yellow';
      case NoteColor.pink:
        return 'Pink';
      case NoteColor.blue:
        return 'Blue';
      case NoteColor.green:
        return 'Green';
      case NoteColor.purple:
        return 'Purple';
      case NoteColor.orange:
        return 'Orange';
    }
  }
}

/// StickyNote model for quick notes and ideas
@HiveType(typeId: 5)
@JsonSerializable(explicitToJson: true)
class StickyNote extends Equatable {
  /// Unique note identifier
  @HiveField(0)
  final String id;

  /// Note title (optional)
  @HiveField(1)
  final String? title;

  /// Note content (rich text supported)
  @HiveField(2)
  final String content;

  /// Note color preset
  @HiveField(3)
  @JsonKey(defaultValue: NoteColor.yellow)
  final NoteColor color;

  /// Position on the canvas
  @HiveField(4)
  final NotePosition position;

  /// Owner user ID
  @HiveField(5)
  final String userId;

  /// Creation timestamp
  @HiveField(6)
  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
  final DateTime createdAt;

  /// Last update timestamp
  @HiveField(7)
  @JsonKey(
    fromJson: _dateTimeFromTimestampNullable,
    toJson: _dateTimeToTimestampNullable,
  )
  final DateTime? updatedAt;

  /// Z-index for layering (higher = on top)
  @HiveField(8)
  @JsonKey(defaultValue: 0)
  final int zIndex;

  /// Note width in pixels
  @HiveField(9)
  @JsonKey(defaultValue: 200.0)
  final double width;

  /// Note height in pixels
  @HiveField(10)
  @JsonKey(defaultValue: 200.0)
  final double height;

  const StickyNote({
    required this.id,
    this.title,
    required this.content,
    required this.color,
    required this.position,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.zIndex = 0,
    this.width = 200.0,
    this.height = 200.0,
  });

  /// Empty sticky note instance for initial state
  static final empty = StickyNote(
    id: '',
    content: '',
    color: NoteColor.yellow,
    position: NotePosition.zero,
    userId: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Check if note is empty
  bool get isEmpty => this == StickyNote.empty;

  /// Check if note is not empty
  bool get isNotEmpty => this != StickyNote.empty;

  /// JSON serialization
  factory StickyNote.fromJson(Map<String, dynamic> json) =>
      _$StickyNoteFromJson(json);

  Map<String, dynamic> toJson() => _$StickyNoteToJson(this);

  /// Create a copy with updated fields
  StickyNote copyWith({
    String? id,
    String? title,
    String? content,
    NoteColor? color,
    NotePosition? position,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? zIndex,
    double? width,
    double? height,
  }) {
    return StickyNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      position: position ?? this.position,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      zIndex: zIndex ?? this.zIndex,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    color,
    position,
    userId,
    createdAt,
    updatedAt,
    zIndex,
    width,
    height,
  ];
}

// Helper functions for Timestamp conversion
DateTime _dateTimeFromTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }
  return DateTime.parse(timestamp as String);
}

dynamic _dateTimeToTimestamp(DateTime dateTime) {
  return Timestamp.fromDate(dateTime);
}

DateTime? _dateTimeFromTimestampNullable(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }
  return DateTime.parse(timestamp as String);
}

dynamic _dateTimeToTimestampNullable(DateTime? dateTime) {
  if (dateTime == null) return null;
  return Timestamp.fromDate(dateTime);
}
