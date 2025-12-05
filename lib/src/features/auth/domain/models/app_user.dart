import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_user.g.dart';

/// User model representing authenticated user data
@JsonSerializable()
class AppUser extends Equatable {
  /// Unique user identifier (Firebase UID)
  final String id;

  /// User's email address
  final String email;

  /// User's display name
  final String? displayName;

  /// URL to user's profile photo
  final String? photoUrl;

  /// Timestamp when user was created
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;

  /// Timestamp when user data was last updated
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates an empty user (for initial/uninitialized state)
  static const AppUser empty = AppUser(
    id: '',
    email: '',
    displayName: null,
    photoUrl: null,
    createdAt: null,
    updatedAt: null,
  );

  /// Check if user is empty/uninitialized
  bool get isEmpty => id.isEmpty;

  /// Check if user is authenticated
  bool get isNotEmpty => id.isNotEmpty;

  /// Creates a copy of this user with updated fields
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this user to a JSON map for Firestore
  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  /// Creates a user from a JSON map from Firestore
  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  /// Converts to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Creates user from Firestore document data
  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    // Parse createdAt - handle both Timestamp and String formats
    DateTime? createdAt;
    final createdAtValue = data['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.parse(createdAtValue);
    }

    // Parse updatedAt - handle both Timestamp and String formats
    DateTime? updatedAt;
    final updatedAtValue = data['updatedAt'];
    if (updatedAtValue is Timestamp) {
      updatedAt = updatedAtValue.toDate();
    } else if (updatedAtValue is String) {
      updatedAt = DateTime.parse(updatedAtValue);
    }

    return AppUser(
      id: data['id'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, displayName: $displayName)';
  }
}

/// Helper functions for DateTime serialization
DateTime? _dateTimeFromJson(String? json) =>
    json != null ? DateTime.parse(json) : null;

String? _dateTimeToJson(DateTime? dateTime) => dateTime?.toIso8601String();
