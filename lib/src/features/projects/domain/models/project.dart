import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'project_role.dart';

part 'project.g.dart';

/// Project model representing a collaborative workspace
@JsonSerializable(explicitToJson: true)
class Project extends Equatable {
  /// Special ID for the synthetic Personal project
  static const personalProjectId = 'personal';

  /// Unique project identifier
  final String id;

  /// Project name
  final String name;

  /// Optional project description
  final String? description;

  /// List of member user IDs who have access to this project
  final List<String> members;

  /// Owner user ID (creator of the project)
  final String ownerId;

  /// Map of member user IDs to their roles
  @JsonKey(defaultValue: {})
  final Map<String, String> memberRoles;

  /// Project creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;

  /// Whether this is a system project (e.g., Personal) that cannot be deleted
  @JsonKey(defaultValue: false)
  final bool isSystem;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.members,
    required this.ownerId,
    this.memberRoles = const {},
    required this.createdAt,
    this.updatedAt,
    this.isSystem = false,
  });

  /// Factory constructor for the synthetic Personal project
  /// Tasks without a projectId belong to this project
  factory Project.personal(String ownerId) {
    return Project(
      id: personalProjectId,
      name: 'Personal',
      description: 'Tasks without a project',
      members: [ownerId],
      ownerId: ownerId,
      memberRoles: {ownerId: 'owner'},
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      isSystem: true,
    );
  }

  /// Check if this is the Personal project
  bool get isPersonal => id == personalProjectId;

  /// Empty project instance for initial state
  static final empty = Project(
    id: '',
    name: '',
    members: const [],
    ownerId: '',
    memberRoles: const {},
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Check if project is empty
  bool get isEmpty => this == Project.empty;

  /// Check if project is not empty
  bool get isNotEmpty => this != Project.empty;

  /// Get role of a specific user
  ProjectRole? getUserRole(String userId) {
    if (userId == ownerId) return ProjectRole.owner;
    final roleStr = memberRoles[userId];
    if (roleStr == null) return null;
    return ProjectRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => ProjectRole.viewer,
    );
  }

  /// Check if user is owner
  bool isOwner(String userId) => userId == ownerId;

  /// Check if user is admin (owner or admin role)
  bool isAdmin(String userId) {
    final role = getUserRole(userId);
    return role?.isAdmin ?? false;
  }

  /// Check if user can edit
  bool canEdit(String userId) {
    final role = getUserRole(userId);
    return role?.canEdit ?? false;
  }

  /// Check if user is a member
  bool isMember(String userId) => members.contains(userId);

  /// JSON serialization
  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  /// Firestore serialization
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String?,
      members: (data['members'] as List<dynamic>).cast<String>(),
      ownerId: data['ownerId'] as String? ?? '',
      memberRoles:
          (data['memberRoles'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'members': members,
      'ownerId': ownerId,
      'memberRoles': memberRoles,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Copy with method for immutability
  Project copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? members,
    String? ownerId,
    Map<String, String>? memberRoles,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSystem,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      ownerId: ownerId ?? this.ownerId,
      memberRoles: memberRoles ?? this.memberRoles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    members,
    ownerId,
    memberRoles,
    createdAt,
    updatedAt,
    isSystem,
  ];
}
