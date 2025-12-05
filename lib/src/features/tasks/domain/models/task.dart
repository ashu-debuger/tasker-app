import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

/// Recurrence pattern for recurring tasks
enum RecurrencePattern {
  @JsonValue('none')
  none,
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly;

  /// Display name for the recurrence pattern
  String get displayName {
    switch (this) {
      case RecurrencePattern.none:
        return 'Does not repeat';
      case RecurrencePattern.daily:
        return 'Daily';
      case RecurrencePattern.weekly:
        return 'Weekly';
      case RecurrencePattern.monthly:
        return 'Monthly';
    }
  }
}

/// Task status enumeration
enum TaskStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed;

  /// Display name for the status
  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }
}

/// Task priority enumeration
enum TaskPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent;

  /// Display name for the priority
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  /// Color for priority badge
  String get colorName {
    switch (this) {
      case TaskPriority.low:
        return 'grey';
      case TaskPriority.medium:
        return 'blue';
      case TaskPriority.high:
        return 'orange';
      case TaskPriority.urgent:
        return 'red';
    }
  }
}

/// Task model representing a work item within a project
@JsonSerializable(explicitToJson: true)
class Task extends Equatable {
  /// Unique task identifier
  final String id;

  /// Parent project ID (null for personal tasks)
  final String? projectId;

  /// Task title
  final String title;

  /// Optional task description
  final String? description;

  /// Whether the description is encrypted
  final bool isDescriptionEncrypted;

  /// Optional due date
  final DateTime? dueDate;

  /// Current task status
  @JsonKey(defaultValue: TaskStatus.pending)
  final TaskStatus status;

  /// Task priority level
  @JsonKey(defaultValue: TaskPriority.medium)
  final TaskPriority priority;

  /// Tags for categorizing and filtering tasks
  @JsonKey(defaultValue: <String>[])
  final List<String> tags;

  /// Whether reminders are enabled for this task
  @JsonKey(defaultValue: true)
  final bool reminderEnabled;

  /// List of user IDs assigned to this task
  final List<String> assignees;

  /// User ID who assigned the task (for tracking)
  final String? assignedBy;

  /// When the task was assigned to current assignee(s)
  final DateTime? assignedAt;

  /// Task creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;

  /// Recurrence pattern for this task
  @JsonKey(defaultValue: RecurrencePattern.none)
  final RecurrencePattern recurrencePattern;

  /// Recurrence interval (e.g., every 2 days, every 3 weeks)
  /// Defaults to 1 (every day/week/month)
  @JsonKey(defaultValue: 1)
  final int recurrenceInterval;

  /// Optional end date for recurrence
  final DateTime? recurrenceEndDate;

  /// ID of the parent recurring task (if this is a generated instance)
  /// Null if this is the original recurring task or not recurring
  final String? parentRecurringTaskId;

  const Task({
    required this.id,
    this.projectId,
    required this.title,
    this.description,
    this.isDescriptionEncrypted = false,
    this.dueDate,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.tags = const [],
    this.reminderEnabled = true,
    required this.assignees,
    this.assignedBy,
    this.assignedAt,
    required this.createdAt,
    this.updatedAt,
    this.recurrencePattern = RecurrencePattern.none,
    this.recurrenceInterval = 1,
    this.recurrenceEndDate,
    this.parentRecurringTaskId,
  });

  /// Empty task instance for initial state
  static final empty = Task(
    id: '',
    projectId: null,
    title: '',
    assignees: const [],
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    reminderEnabled: true,
  );

  /// Check if task is empty
  bool get isEmpty => this == Task.empty;

  /// Check if task is not empty
  bool get isNotEmpty => this != Task.empty;

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Check if task is a recurring task (not an instance)
  bool get isRecurring =>
      recurrencePattern != RecurrencePattern.none &&
      parentRecurringTaskId == null;

  /// Check if task is an instance of a recurring task
  bool get isRecurringInstance => parentRecurringTaskId != null;

  /// Calculate the next occurrence date based on recurrence pattern
  DateTime? getNextOccurrence() {
    if (!isRecurring || dueDate == null) return null;

    DateTime? nextDate;

    switch (recurrencePattern) {
      case RecurrencePattern.none:
        return null;
      case RecurrencePattern.daily:
        nextDate = dueDate!.add(Duration(days: recurrenceInterval));
        break;
      case RecurrencePattern.weekly:
        nextDate = dueDate!.add(Duration(days: 7 * recurrenceInterval));
        break;
      case RecurrencePattern.monthly:
        // Add months while preserving day of month
        final year =
            dueDate!.year + ((dueDate!.month + recurrenceInterval - 1) ~/ 12);
        final month = ((dueDate!.month + recurrenceInterval - 1) % 12) + 1;
        nextDate = DateTime(year, month, dueDate!.day);
        break;
    }

    // Check if next occurrence is past the end date
    if (recurrenceEndDate != null) {
      // Compare dates only (ignore time component)
      final endDateOnly = DateTime(
        recurrenceEndDate!.year,
        recurrenceEndDate!.month,
        recurrenceEndDate!.day,
      );
      final nextDateOnly = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
      );

      if (nextDateOnly.isAfter(endDateOnly)) {
        return null;
      }
    }

    return nextDate;
  }

  /// JSON serialization
  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  /// Helper to parse date from Firestore (handles both Timestamp and ISO String)
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Helper to parse required date (throws if null after parsing)
  static DateTime _parseRequiredDate(dynamic value, String fieldName) {
    final date = _parseDate(value);
    if (date == null) {
      throw FormatException(
        'Required date field "$fieldName" is null or invalid',
      );
    }
    return date;
  }

  /// Firestore serialization
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      projectId: data['projectId'] as String?,
      title: data['title'] as String,
      description: data['description'] as String?,
      isDescriptionEncrypted: data['isDescriptionEncrypted'] as bool? ?? false,
      dueDate: _parseDate(data['dueDate']),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: data['priority'] != null
          ? TaskPriority.values.firstWhere(
              (e) => e.name == data['priority'],
              orElse: () => TaskPriority.medium,
            )
          : TaskPriority.medium,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      reminderEnabled: data['reminderEnabled'] as bool? ?? true,
      assignees: (data['assignees'] as List<dynamic>?)?.cast<String>() ?? [],
      assignedBy: data['assignedBy'] as String?,
      assignedAt: _parseDate(data['assignedAt']),
      createdAt: _parseRequiredDate(data['createdAt'], 'createdAt'),
      updatedAt: _parseDate(data['updatedAt']),
      recurrencePattern: data['recurrencePattern'] != null
          ? RecurrencePattern.values.firstWhere(
              (e) => e.name == data['recurrencePattern'],
              orElse: () => RecurrencePattern.none,
            )
          : RecurrencePattern.none,
      recurrenceInterval: (data['recurrenceInterval'] as int? ?? 1).clamp(
        1,
        999999,
      ),
      recurrenceEndDate: _parseDate(data['recurrenceEndDate']),
      parentRecurringTaskId: data['parentRecurringTaskId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'isDescriptionEncrypted': isDescriptionEncrypted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status.name,
      'priority': priority.name,
      'tags': tags,
      'reminderEnabled': reminderEnabled,
      'assignees': assignees,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'recurrencePattern': recurrencePattern.name,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndDate': recurrenceEndDate != null
          ? Timestamp.fromDate(recurrenceEndDate!)
          : null,
      'parentRecurringTaskId': parentRecurringTaskId,
    };
  }

  /// Copy with method for immutability
  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    bool? isDescriptionEncrypted,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    List<String>? tags,
    bool? reminderEnabled,
    List<String>? assignees,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    RecurrencePattern? recurrencePattern,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    String? parentRecurringTaskId,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      isDescriptionEncrypted:
          isDescriptionEncrypted ?? this.isDescriptionEncrypted,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      assignees: assignees ?? this.assignees,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      parentRecurringTaskId:
          parentRecurringTaskId ?? this.parentRecurringTaskId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    title,
    description,
    isDescriptionEncrypted,
    dueDate,
    status,
    priority,
    tags,
    reminderEnabled,
    assignees,
    assignedBy,
    assignedAt,
    createdAt,
    updatedAt,
    recurrencePattern,
    recurrenceInterval,
    recurrenceEndDate,
    parentRecurringTaskId,
  ];
}
