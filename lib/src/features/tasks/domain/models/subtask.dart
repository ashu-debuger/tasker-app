import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subtask.g.dart';

/// Subtask model representing a smaller work item within a task
@JsonSerializable(explicitToJson: true)
class Subtask extends Equatable {
  /// Unique subtask identifier
  final String id;

  /// Parent task ID
  final String taskId;

  /// Subtask title/description
  final String title;

  /// Completion status
  @JsonKey(defaultValue: false)
  final bool isCompleted;

  /// Subtask creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;

  /// Optional due date/time for the subtask
  final DateTime? dueDate;

  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
  });

  /// Empty subtask instance for initial state
  static final empty = Subtask(
    id: '',
    taskId: '',
    title: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    dueDate: null,
  );

  /// Check if subtask is empty
  bool get isEmpty => this == Subtask.empty;

  /// Check if subtask is not empty
  bool get isNotEmpty => this != Subtask.empty;

  /// JSON serialization
  factory Subtask.fromJson(Map<String, dynamic> json) =>
      _$SubtaskFromJson(json);
  Map<String, dynamic> toJson() => _$SubtaskToJson(this);

  /// Firestore serialization
  factory Subtask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subtask(
      id: doc.id,
      taskId: data['taskId'] as String,
      title: data['title'] as String,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    };
  }

  /// Copy with method for immutability
  Subtask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
  }) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    taskId,
    title,
    isCompleted,
    createdAt,
    updatedAt,
    dueDate,
  ];
}
