import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing Cliq notification preferences
class CliqNotificationSettings extends Equatable {
  final bool enabled;
  final bool taskAssigned;
  final bool taskCompleted;
  final bool taskDueSoon;
  final bool taskOverdue;
  final bool commentAdded;
  final bool projectInvite;
  final bool memberJoined;
  final QuietHours? quietHours;
  final DoNotDisturb? doNotDisturb;

  const CliqNotificationSettings({
    this.enabled = true,
    this.taskAssigned = true,
    this.taskCompleted = true,
    this.taskDueSoon = true,
    this.taskOverdue = true,
    this.commentAdded = true,
    this.projectInvite = true,
    this.memberJoined = true,
    this.quietHours,
    this.doNotDisturb,
  });

  factory CliqNotificationSettings.defaults() {
    return const CliqNotificationSettings();
  }

  factory CliqNotificationSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return CliqNotificationSettings.defaults();
    return CliqNotificationSettings.fromJson(data);
  }

  factory CliqNotificationSettings.fromJson(Map<String, dynamic> json) {
    return CliqNotificationSettings(
      enabled: json['enabled'] ?? true,
      taskAssigned: json['task_assigned'] ?? true,
      taskCompleted: json['task_completed'] ?? true,
      taskDueSoon: json['task_due_soon'] ?? true,
      taskOverdue: json['task_overdue'] ?? true,
      commentAdded: json['comment_added'] ?? true,
      projectInvite: json['project_invite'] ?? true,
      memberJoined: json['member_joined'] ?? true,
      quietHours: json['quiet_hours'] != null
          ? QuietHours.fromJson(json['quiet_hours'])
          : null,
      doNotDisturb: json['doNotDisturb'] != null
          ? DoNotDisturb.fromJson(json['doNotDisturb'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'task_assigned': taskAssigned,
      'task_completed': taskCompleted,
      'task_due_soon': taskDueSoon,
      'task_overdue': taskOverdue,
      'comment_added': commentAdded,
      'project_invite': projectInvite,
      'member_joined': memberJoined,
      if (quietHours != null) 'quiet_hours': quietHours!.toJson(),
      if (doNotDisturb != null) 'doNotDisturb': doNotDisturb!.toJson(),
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  CliqNotificationSettings copyWith({
    bool? enabled,
    bool? taskAssigned,
    bool? taskCompleted,
    bool? taskDueSoon,
    bool? taskOverdue,
    bool? commentAdded,
    bool? projectInvite,
    bool? memberJoined,
    QuietHours? quietHours,
    DoNotDisturb? doNotDisturb,
    bool clearQuietHours = false,
    bool clearDoNotDisturb = false,
  }) {
    return CliqNotificationSettings(
      enabled: enabled ?? this.enabled,
      taskAssigned: taskAssigned ?? this.taskAssigned,
      taskCompleted: taskCompleted ?? this.taskCompleted,
      taskDueSoon: taskDueSoon ?? this.taskDueSoon,
      taskOverdue: taskOverdue ?? this.taskOverdue,
      commentAdded: commentAdded ?? this.commentAdded,
      projectInvite: projectInvite ?? this.projectInvite,
      memberJoined: memberJoined ?? this.memberJoined,
      quietHours: clearQuietHours ? null : (quietHours ?? this.quietHours),
      doNotDisturb:
          clearDoNotDisturb ? null : (doNotDisturb ?? this.doNotDisturb),
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        taskAssigned,
        taskCompleted,
        taskDueSoon,
        taskOverdue,
        commentAdded,
        projectInvite,
        memberJoined,
        quietHours,
        doNotDisturb,
      ];
}

/// Quiet hours configuration
class QuietHours extends Equatable {
  final bool enabled;
  final int startHour; // 0-23
  final int endHour; // 0-23

  const QuietHours({
    this.enabled = false,
    this.startHour = 22, // 10 PM
    this.endHour = 8, // 8 AM
  });

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      enabled: json['enabled'] ?? false,
      startHour: json['start'] ?? 22,
      endHour: json['end'] ?? 8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'start': startHour,
      'end': endHour,
    };
  }

  QuietHours copyWith({
    bool? enabled,
    int? startHour,
    int? endHour,
  }) {
    return QuietHours(
      enabled: enabled ?? this.enabled,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
    );
  }

  @override
  List<Object?> get props => [enabled, startHour, endHour];
}

/// Do Not Disturb configuration
class DoNotDisturb extends Equatable {
  final bool enabled;
  final DateTime? until;

  const DoNotDisturb({
    this.enabled = false,
    this.until,
  });

  factory DoNotDisturb.fromJson(Map<String, dynamic> json) {
    return DoNotDisturb(
      enabled: json['enabled'] ?? false,
      until: json['until'] != null
          ? (json['until'] is Timestamp
              ? (json['until'] as Timestamp).toDate()
              : DateTime.parse(json['until']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      if (until != null) 'until': until!.toIso8601String(),
    };
  }

  DoNotDisturb copyWith({
    bool? enabled,
    DateTime? until,
    bool clearUntil = false,
  }) {
    return DoNotDisturb(
      enabled: enabled ?? this.enabled,
      until: clearUntil ? null : (until ?? this.until),
    );
  }

  /// Check if DND is currently active
  bool get isActive {
    if (!enabled) return false;
    if (until == null) return true; // Indefinite DND
    return DateTime.now().isBefore(until!);
  }

  @override
  List<Object?> get props => [enabled, until];
}
