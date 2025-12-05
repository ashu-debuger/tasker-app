import 'package:equatable/equatable.dart';

/// Represents a single diary entry with title, body, and metadata
///
/// Hive adapter located at: lib/src/core/storage/adapters/diary_entry_adapter.dart
class DiaryEntry extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime entryDate; // The date this diary entry is for
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? mood;
  final String? linkedTaskId;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.mood,
    this.linkedTaskId,
  });

  /// Create a copy with updated fields
  DiaryEntry copyWith({
    String? title,
    String? body,
    DateTime? entryDate,
    DateTime? updatedAt,
    List<String>? tags,
    String? mood,
    String? linkedTaskId,
  }) {
    return DiaryEntry(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
    );
  }

  /// Convert to JSON for potential export/sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'entryDate': entryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'mood': mood,
      'linkedTaskId': linkedTaskId,
    };
  }

  /// Create from JSON
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      entryDate: json['entryDate'] != null
          ? DateTime.parse(json['entryDate'] as String)
          : DateTime.parse(
              json['createdAt'] as String,
            ), // Fallback for old entries
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      mood: json['mood'] as String?,
      linkedTaskId: json['linkedTaskId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    entryDate,
    createdAt,
    updatedAt,
    tags,
    mood,
    linkedTaskId,
  ];
}
