import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/models/project_member.dart';
import '../../domain/models/project_role.dart';
import '../../domain/repositories/project_member_repository.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/notifications/repositories/notification_repository.dart';
import '../../../../core/notifications/models/notification_type.dart';

/// Firebase implementation of ProjectMemberRepository
class FirebaseProjectMemberRepository implements ProjectMemberRepository {
  final FirebaseFirestore _firestore;
  final NotificationRepository? _notificationRepository;

  // Backend API configuration from environment
  static String get _backendUrl => EnvConfig.apiBaseUrl;
  static String get _apiKey => EnvConfig.apiKey;

  FirebaseProjectMemberRepository({
    FirebaseFirestore? firestore,
    NotificationRepository? notificationRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationRepository = notificationRepository;

  @override
  Future<void> addMember({
    required String projectId,
    required String userId,
    required ProjectRole role,
  }) async {
    // Get current user from Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('User not authenticated');
    }

    // Get user details
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final userData = userDoc.data()!;

    // Get project details for notification
    final projectDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .get();
    final projectData = projectDoc.data();
    final projectName = projectData?['name'] ?? 'Unknown Project';
    final projectDescription = projectData?['description'] ?? '';

    final batch = _firestore.batch();

    // Add to members subcollection
    final memberRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(userId);

    batch.set(memberRef, {
      'userId': userId,
      'email': userData['email'],
      'displayName': userData['displayName'] ?? userData['email'],
      'photoUrl': userData['photoUrl'],
      'role': role.name,
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': firebaseUser.uid,
    });

    // Update project document
    final projectRef = _firestore.collection('projects').doc(projectId);
    batch.update(projectRef, {
      'members': FieldValue.arrayUnion([userId]),
      'memberRoles.$userId': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Send Cliq notification for project invite
    await _sendCliqNotification(
      targetUserId: userId,
      type: 'project_invite',
      data: {
        'projectId': projectId,
        'projectName': projectName,
        'projectDescription': projectDescription,
        'invitedByName':
            firebaseUser.displayName ?? firebaseUser.email ?? 'A team member',
        'role': role.displayName,
      },
    );

    // Send push notification for project invite
    if (_notificationRepository != null) {
      try {
        await _notificationRepository.sendNotification(
          userId: userId,
          type: NotificationType.invitationReceived,
          title: 'Project Invitation',
          body:
              '${firebaseUser.displayName ?? firebaseUser.email ?? 'Someone'} invited you to $projectName',
          data: {
            'projectId': projectId,
            'projectName': projectName,
            'role': role.name,
            'invitedBy': firebaseUser.uid,
          },
        );
      } catch (e) {
        // Don't fail if push notification fails
        print('Failed to send push notification: $e');
      }
    }
  }

  @override
  Future<void> removeMember({
    required String projectId,
    required String userId,
  }) async {
    // Get member and project info before deletion for notifications
    final memberDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(userId)
        .get();
    final projectDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .get();
    final memberData = memberDoc.exists ? memberDoc.data() : null;
    final projectName = projectDoc.exists
        ? (projectDoc.data()?['name'] as String? ?? 'Unknown Project')
        : 'Unknown Project';
    final memberName = memberData?['displayName'] as String? ?? 'A member';

    final batch = _firestore.batch();

    // Remove from members subcollection
    final memberRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(userId);
    batch.delete(memberRef);

    // Update project document
    final projectRef = _firestore.collection('projects').doc(projectId);
    batch.update(projectRef, {
      'members': FieldValue.arrayRemove([userId]),
      'memberRoles.$userId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Unassign all tasks assigned to this user in the project
    final tasksQuery = await _firestore
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .where('assignees', arrayContains: userId)
        .get();

    for (final taskDoc in tasksQuery.docs) {
      batch.update(taskDoc.reference, {
        'assignees': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // Send notifications
    if (_notificationRepository != null) {
      try {
        // Notify the removed member
        await _notificationRepository.sendNotification(
          userId: userId,
          type: NotificationType.memberRemoved,
          title: 'Removed from Project',
          body: 'You were removed from "$projectName"',
          data: {'projectId': projectId, 'projectName': projectName},
          actionUrl: '/projects',
        );

        // Notify all remaining members
        final remainingMembersSnapshot = await _firestore
            .collection('projects')
            .doc(projectId)
            .collection('members')
            .get();

        for (final doc in remainingMembersSnapshot.docs) {
          final memberId = doc.id;
          await _notificationRepository.sendNotification(
            userId: memberId,
            type: NotificationType.memberRemoved,
            title: 'Member Removed',
            body: '$memberName was removed from "$projectName"',
            data: {
              'projectId': projectId,
              'projectName': projectName,
              'removedUserId': userId,
              'removedUserName': memberName,
            },
            actionUrl: '/projects/$projectId',
          );
        }
      } catch (e) {
        // Don't fail the operation if notification fails
        print('Failed to send member removal notifications: $e');
      }
    }
  }

  @override
  Future<void> updateMemberRole({
    required String projectId,
    required String userId,
    required ProjectRole newRole,
  }) async {
    // Get project and member info for notifications
    final projectDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .get();
    final memberDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(userId)
        .get();
    final projectName = projectDoc.exists
        ? (projectDoc.data()?['name'] as String? ?? 'Unknown Project')
        : 'Unknown Project';
    final oldRole = memberDoc.exists
        ? (memberDoc.data()?['role'] as String?)
        : null;

    final batch = _firestore.batch();

    // Update in members subcollection
    final memberRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(userId);

    batch.update(memberRef, {'role': newRole.name});

    // Update in project document
    final projectRef = _firestore.collection('projects').doc(projectId);
    batch.update(projectRef, {
      'memberRoles.$userId': newRole.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Send notification if role changed
    if (_notificationRepository != null &&
        oldRole != null &&
        oldRole != newRole.name) {
      try {
        await _notificationRepository.sendNotification(
          userId: userId,
          type: NotificationType.memberRoleChanged,
          title: 'Role Changed',
          body:
              'Your role in "$projectName" was changed to ${newRole.displayName}',
          data: {
            'projectId': projectId,
            'projectName': projectName,
            'oldRole': oldRole,
            'newRole': newRole.name,
          },
          actionUrl: '/projects/$projectId',
        );
      } catch (e) {
        // Don't fail the operation if notification fails
        print('Failed to send role change notification: $e');
      }
    }
  }

  @override
  Stream<List<ProjectMember>> getProjectMembers(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .orderBy('addedAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProjectMember.fromFirestore(doc.data()))
              .toList();
        });
  }

  @override
  Future<ProjectMember?> getMember({
    required String projectId,
    required String userId,
  }) async {
    final doc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(userId)
        .get();

    if (!doc.exists) return null;

    return ProjectMember.fromFirestore(doc.data()!);
  }

  @override
  Future<ProjectRole?> getUserRole({
    required String projectId,
    required String userId,
  }) async {
    final projectDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .get();

    if (!projectDoc.exists) return null;

    final data = projectDoc.data()!;

    // Check if user is owner
    if (data['ownerId'] == userId) {
      return ProjectRole.owner;
    }

    // Get role from memberRoles map
    final memberRoles = data['memberRoles'] as Map<String, dynamic>?;
    if (memberRoles == null) return null;

    final roleStr = memberRoles[userId] as String?;
    if (roleStr == null) return null;

    return ProjectRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => ProjectRole.viewer,
    );
  }

  @override
  Future<bool> isMember({
    required String projectId,
    required String userId,
  }) async {
    final doc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(userId)
        .get();

    return doc.exists;
  }

  @override
  Stream<List<String>> getUserProjects(String userId) {
    return _firestore
        .collection('projects')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.id).toList();
        });
  }

  @override
  Future<int> getMemberCount(String projectId) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Send a notification to Cliq via backend
  Future<void> _sendCliqNotification({
    required String targetUserId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/cliq/notifications/send'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: jsonEncode({'userId': targetUserId, 'type': type, 'data': data}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('Cliq notification sent: $type');
        } else {
          print('Cliq notification not sent: ${result['reason']}');
        }
      } else {
        print('Failed to send Cliq notification: ${response.statusCode}');
      }
    } catch (e) {
      // Don't fail the operation if notification fails
      print('Error sending Cliq notification: $e');
    }
  }
}
