import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'project_role.dart';

part 'project_member.g.dart';

/// Represents a member of a project
@JsonSerializable()
class ProjectMember extends Equatable {
  /// User ID of the member
  final String userId;

  /// Email of the member
  final String email;

  /// Display name of the member
  final String displayName;

  /// Photo URL of the member
  final String? photoUrl;

  /// Role of the member in the project
  final ProjectRole role;

  /// When the member was added to the project
  final DateTime addedAt;

  /// User ID of who added this member
  final String addedBy;

  const ProjectMember({
    required this.userId,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.addedAt,
    required this.addedBy,
  });

  /// Create from JSON
  factory ProjectMember.fromJson(Map<String, dynamic> json) =>
      _$ProjectMemberFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ProjectMemberToJson(this);

  /// Create from Firestore document
  factory ProjectMember.fromFirestore(Map<String, dynamic> data) {
    // Parse addedAt - handle both Timestamp and String formats
    DateTime addedAt;
    final addedAtValue = data['addedAt'];
    if (addedAtValue is Timestamp) {
      addedAt = addedAtValue.toDate();
    } else if (addedAtValue is String) {
      addedAt = DateTime.parse(addedAtValue);
    } else {
      addedAt = DateTime.now();
    }

    return ProjectMember(
      userId: data['userId'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      role: ProjectRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => ProjectRole.viewer,
      ),
      addedAt: addedAt,
      addedBy: data['addedBy'] as String,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'addedAt': addedAt.toIso8601String(),
      'addedBy': addedBy,
    };
  }

  /// Create a copy with updated fields
  ProjectMember copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? photoUrl,
    ProjectRole? role,
    DateTime? addedAt,
    String? addedBy,
  }) {
    return ProjectMember(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
      addedBy: addedBy ?? this.addedBy,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    email,
    displayName,
    photoUrl,
    role,
    addedAt,
    addedBy,
  ];
}
