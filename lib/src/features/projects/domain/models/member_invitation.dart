import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'invitation_status.dart';
import 'project_role.dart';

part 'member_invitation.g.dart';

/// Represents an invitation to join a project
@JsonSerializable()
class MemberInvitation extends Equatable {
  /// Unique invitation ID
  final String id;

  /// ID of the project
  final String projectId;

  /// Name of the project
  final String projectName;

  /// User ID of who sent the invitation
  final String invitedByUserId;

  /// Display name of who sent the invitation
  final String invitedByUserName;

  /// Email address of the invitee
  final String invitedEmail;

  /// User ID of invitee (if they have an account)
  final String? invitedUserId;

  /// Current status of the invitation
  final InvitationStatus status;

  /// When the invitation was created
  final DateTime createdAt;

  /// When the invitation was responded to
  final DateTime? respondedAt;

  /// Role being offered
  final ProjectRole role;

  /// Optional personal message
  final String? message;

  const MemberInvitation({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.invitedByUserId,
    required this.invitedByUserName,
    required this.invitedEmail,
    this.invitedUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.role,
    this.message,
  });

  /// Create from JSON
  factory MemberInvitation.fromJson(Map<String, dynamic> json) =>
      _$MemberInvitationFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$MemberInvitationToJson(this);

  /// Create from Firestore document
  factory MemberInvitation.fromFirestore(String id, Map<String, dynamic> data) {
    // Parse createdAt - handle both Timestamp and String formats
    DateTime createdAt = DateTime.now();
    final createdAtValue = data['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.parse(createdAtValue);
    }

    // Parse respondedAt - handle both Timestamp and String formats
    DateTime? respondedAt;
    final respondedAtValue = data['respondedAt'];
    if (respondedAtValue is Timestamp) {
      respondedAt = respondedAtValue.toDate();
    } else if (respondedAtValue is String) {
      respondedAt = DateTime.parse(respondedAtValue);
    }

    return MemberInvitation(
      id: id,
      projectId: data['projectId'] as String,
      projectName: data['projectName'] as String,
      invitedByUserId: data['invitedByUserId'] as String,
      invitedByUserName: data['invitedByUserName'] as String,
      invitedEmail: data['invitedEmail'] as String,
      invitedUserId: data['invitedUserId'] as String?,
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: createdAt,
      respondedAt: respondedAt,
      role: ProjectRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => ProjectRole.viewer,
      ),
      message: data['message'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'invitedByUserId': invitedByUserId,
      'invitedByUserName': invitedByUserName,
      'invitedEmail': invitedEmail,
      'invitedUserId': invitedUserId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'role': role.name,
      'message': message,
    };
  }

  /// Check if invitation is pending
  bool get isPending => status == InvitationStatus.pending;

  /// Check if invitation is accepted
  bool get isAccepted => status == InvitationStatus.accepted;

  /// Check if invitation is declined
  bool get isDeclined => status == InvitationStatus.declined;

  /// Check if invitation is cancelled
  bool get isCancelled => status == InvitationStatus.cancelled;

  /// Create a copy with updated fields
  MemberInvitation copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? invitedByUserId,
    String? invitedByUserName,
    String? invitedEmail,
    String? invitedUserId,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    ProjectRole? role,
    String? message,
  }) {
    return MemberInvitation(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      invitedByUserName: invitedByUserName ?? this.invitedByUserName,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      role: role ?? this.role,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    projectName,
    invitedByUserId,
    invitedByUserName,
    invitedEmail,
    invitedUserId,
    status,
    createdAt,
    respondedAt,
    role,
    message,
  ];
}
