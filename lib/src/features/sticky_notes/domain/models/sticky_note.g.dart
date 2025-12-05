// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sticky_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotePosition _$NotePositionFromJson(Map<String, dynamic> json) => NotePosition(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
);

Map<String, dynamic> _$NotePositionToJson(NotePosition instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y};

StickyNote _$StickyNoteFromJson(Map<String, dynamic> json) => StickyNote(
  id: json['id'] as String,
  title: json['title'] as String?,
  content: json['content'] as String,
  color:
      $enumDecodeNullable(_$NoteColorEnumMap, json['color']) ??
      NoteColor.yellow,
  position: NotePosition.fromJson(json['position'] as Map<String, dynamic>),
  userId: json['userId'] as String,
  createdAt: _dateTimeFromTimestamp(json['createdAt']),
  updatedAt: _dateTimeFromTimestampNullable(json['updatedAt']),
  zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
  width: (json['width'] as num?)?.toDouble() ?? 200.0,
  height: (json['height'] as num?)?.toDouble() ?? 200.0,
);

Map<String, dynamic> _$StickyNoteToJson(StickyNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'color': _$NoteColorEnumMap[instance.color]!,
      'position': instance.position.toJson(),
      'userId': instance.userId,
      'createdAt': _dateTimeToTimestamp(instance.createdAt),
      'updatedAt': _dateTimeToTimestampNullable(instance.updatedAt),
      'zIndex': instance.zIndex,
      'width': instance.width,
      'height': instance.height,
    };

const _$NoteColorEnumMap = {
  NoteColor.yellow: 'yellow',
  NoteColor.pink: 'pink',
  NoteColor.blue: 'blue',
  NoteColor.green: 'green',
  NoteColor.purple: 'purple',
  NoteColor.orange: 'orange',
};
