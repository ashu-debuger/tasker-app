import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing the mapping between a Tasker user and their Zoho Cliq account
class CliqUserMapping extends Equatable {
  final String cliqUserId;
  final String cliqUserName;
  final String taskerUserId;
  final String? taskerEmail;
  final DateTime linkedAt;
  final bool isActive;

  const CliqUserMapping({
    required this.cliqUserId,
    required this.cliqUserName,
    required this.taskerUserId,
    this.taskerEmail,
    required this.linkedAt,
    this.isActive = true,
  });

  factory CliqUserMapping.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CliqUserMapping(
      cliqUserId: data['cliq_user_id'] ?? doc.id,
      cliqUserName: data['cliq_user_name'] ?? '',
      taskerUserId: data['tasker_user_id'] ?? '',
      taskerEmail: data['tasker_email'],
      linkedAt: (data['linked_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['is_active'] ?? true,
    );
  }

  factory CliqUserMapping.fromJson(Map<String, dynamic> json) {
    return CliqUserMapping(
      cliqUserId: json['cliq_user_id'] ?? '',
      cliqUserName: json['cliq_user_name'] ?? '',
      taskerUserId: json['tasker_user_id'] ?? '',
      taskerEmail: json['tasker_email'],
      linkedAt: json['linked_at'] != null
          ? DateTime.parse(json['linked_at'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cliq_user_id': cliqUserId,
      'cliq_user_name': cliqUserName,
      'tasker_user_id': taskerUserId,
      'tasker_email': taskerEmail,
      'linked_at': linkedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cliq_user_id': cliqUserId,
      'cliq_user_name': cliqUserName,
      'tasker_user_id': taskerUserId,
      'tasker_email': taskerEmail,
      'linked_at': Timestamp.fromDate(linkedAt),
      'is_active': isActive,
    };
  }

  CliqUserMapping copyWith({
    String? cliqUserId,
    String? cliqUserName,
    String? taskerUserId,
    String? taskerEmail,
    DateTime? linkedAt,
    bool? isActive,
  }) {
    return CliqUserMapping(
      cliqUserId: cliqUserId ?? this.cliqUserId,
      cliqUserName: cliqUserName ?? this.cliqUserName,
      taskerUserId: taskerUserId ?? this.taskerUserId,
      taskerEmail: taskerEmail ?? this.taskerEmail,
      linkedAt: linkedAt ?? this.linkedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        cliqUserId,
        cliqUserName,
        taskerUserId,
        taskerEmail,
        linkedAt,
        isActive,
      ];
}
