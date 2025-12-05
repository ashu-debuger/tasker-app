import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'routine.g.dart';

/// Frequency type for routines
enum RoutineFrequency {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('custom')
  custom;

  String get displayName {
    switch (this) {
      case RoutineFrequency.daily:
        return 'Daily';
      case RoutineFrequency.weekly:
        return 'Weekly';
      case RoutineFrequency.custom:
        return 'Custom';
    }
  }
}

/// Routine model for recurring tasks and habits
@JsonSerializable(explicitToJson: true)
class Routine extends Equatable {
  /// Unique routine identifier
  final String id;

  /// User ID who owns this routine
  final String userId;

  /// Routine title
  final String title;

  /// Optional routine description
  final String? description;

  /// How often the routine repeats
  @JsonKey(defaultValue: RoutineFrequency.daily)
  final RoutineFrequency frequency;

  /// Days of week for weekly/custom routines (1=Monday, 7=Sunday)
  /// Empty for daily routines
  final List<int> daysOfWeek;

  /// Time of day for the routine (24-hour format: HH:mm)
  final String? timeOfDay;

  /// Whether the routine is currently active
  final bool isActive;

  /// Whether reminder notifications are enabled for this routine
  @JsonKey(defaultValue: false)
  final bool reminderEnabled;

  /// Minutes before the routine time to send reminder (if reminderEnabled)
  /// Defaults to 15 minutes before
  @JsonKey(defaultValue: 15)
  final int reminderMinutesBefore;

  /// Routine creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;

  const Routine({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.frequency = RoutineFrequency.daily,
    this.daysOfWeek = const [],
    this.timeOfDay,
    this.isActive = true,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 15,
    required this.createdAt,
    this.updatedAt,
  });

  /// Empty routine instance for initial state
  static final empty = Routine(
    id: '',
    userId: '',
    title: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Check if routine is empty
  bool get isEmpty => this == Routine.empty;

  /// Check if routine is not empty
  bool get isNotEmpty => this != Routine.empty;

  /// Check if routine should run today
  bool shouldRunToday() {
    return occursOn(DateTime.now());
  }

  /// Check if routine should run on a specific day
  bool occursOn(DateTime day) {
    if (!isActive) return false;

    final weekday = day.weekday; // 1=Monday, 7=Sunday

    switch (frequency) {
      case RoutineFrequency.daily:
        return true;
      case RoutineFrequency.weekly:
      case RoutineFrequency.custom:
        if (daysOfWeek.isEmpty) return false;
        return daysOfWeek.contains(weekday);
    }
  }

  /// JSON serialization
  factory Routine.fromJson(Map<String, dynamic> json) =>
      _$RoutineFromJson(json);
  Map<String, dynamic> toJson() => _$RoutineToJson(this);

  /// Firestore serialization
  factory Routine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Routine(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      frequency: RoutineFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => RoutineFrequency.daily,
      ),
      daysOfWeek: (data['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? [],
      timeOfDay: data['timeOfDay'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      reminderEnabled: data['reminderEnabled'] as bool? ?? false,
      reminderMinutesBefore: data['reminderMinutesBefore'] as int? ?? 15,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'frequency': frequency.name,
      'daysOfWeek': daysOfWeek,
      'timeOfDay': timeOfDay,
      'isActive': isActive,
      'reminderEnabled': reminderEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Copy with method for immutability
  Routine copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    RoutineFrequency? frequency,
    List<int>? daysOfWeek,
    String? timeOfDay,
    bool? isActive,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isActive: isActive ?? this.isActive,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    description,
    frequency,
    daysOfWeek,
    timeOfDay,
    isActive,
    reminderEnabled,
    reminderMinutesBefore,
    createdAt,
    updatedAt,
  ];
}
