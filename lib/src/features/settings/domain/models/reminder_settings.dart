import 'package:equatable/equatable.dart';

/// User-configurable reminder lead times for tasks and routines.
class ReminderSettings extends Equatable {
  const ReminderSettings({
    this.taskLeadMinutes = defaultTaskLeadMinutes,
    this.routineLeadMinutes = defaultRoutineLeadMinutes,
  });

  /// Allowed reminder offsets presented in the UI.
  static const List<int> supportedLeadTimes = [5, 10, 15, 30, 60];

  /// Default reminder offset before a task due date.
  static const int defaultTaskLeadMinutes = 30;

  /// Default reminder offset before a routine start time.
  static const int defaultRoutineLeadMinutes = 15;

  /// Current reminder offset for tasks (minutes before the due date).
  final int taskLeadMinutes;

  /// Current reminder offset for routines (minutes before the routine time).
  final int routineLeadMinutes;

  /// Baseline reminder settings instance.
  static const ReminderSettings defaults = ReminderSettings();

  ReminderSettings copyWith({int? taskLeadMinutes, int? routineLeadMinutes}) {
    return ReminderSettings(
      taskLeadMinutes: _normalizeLeadMinutes(
        taskLeadMinutes,
        fallback: this.taskLeadMinutes,
      ),
      routineLeadMinutes: _normalizeLeadMinutes(
        routineLeadMinutes,
        fallback: this.routineLeadMinutes,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskLeadMinutes': taskLeadMinutes,
      'routineLeadMinutes': routineLeadMinutes,
    };
  }

  factory ReminderSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return defaults;
    }

    return ReminderSettings(
      taskLeadMinutes: _normalizeLeadMinutes(
        map['taskLeadMinutes'] as int?,
        fallback: defaultTaskLeadMinutes,
      ),
      routineLeadMinutes: _normalizeLeadMinutes(
        map['routineLeadMinutes'] as int?,
        fallback: defaultRoutineLeadMinutes,
      ),
    );
  }

  ReminderSettings merge(ReminderSettings? other) {
    if (other == null) return this;
    return copyWith(
      taskLeadMinutes: other.taskLeadMinutes,
      routineLeadMinutes: other.routineLeadMinutes,
    );
  }

  static int _normalizeLeadMinutes(int? value, {required int fallback}) {
    if (value == null || value <= 0) return fallback;
    if (supportedLeadTimes.contains(value)) return value;
    return fallback;
  }

  @override
  List<Object?> get props => [taskLeadMinutes, routineLeadMinutes];
}
