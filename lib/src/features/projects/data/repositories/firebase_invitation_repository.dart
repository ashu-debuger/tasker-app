import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../../domain/models/invitation_status.dart';
import '../../domain/models/member_invitation.dart';
import '../../domain/models/project_role.dart';
import '../../domain/repositories/invitation_repository.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../../core/notifications/repositories/notification_repository.dart';
import '../../../../core/notifications/models/notification_type.dart';
import '../../../../core/utils/app_logger.dart';

/// Firebase implementation of InvitationRepository
class FirebaseInvitationRepository implements InvitationRepository {
  final FirebaseFirestore _firestore;
  final NotificationRepository? _notificationRepository;
  static const _logTag = '[Invitation:Repo]';

  FirebaseInvitationRepository({
    FirebaseFirestore? firestore,
    NotificationRepository? notificationRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationRepository = notificationRepository;

  /// Collection reference for invitations
  CollectionReference get _invitationsCollection =>
      _firestore.collection('invitations');

  @override
  Future<String> sendInvitation({
    required String projectId,
    required String email,
    required ProjectRole role,
    String? message,
  }) async {
    appLogger.i(
      '$_logTag sendInvitation projectId=$projectId email=${maskEmail(email)} role=${role.name}',
    );
    try {
      // Get current user info
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        appLogger.e('$_logTag sendInvitation failed: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Get project info
      appLogger.d('$_logTag Fetching project info projectId=$projectId');
      final projectDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .get();
      if (!projectDoc.exists) {
        appLogger.e(
          '$_logTag sendInvitation failed: Project not found projectId=$projectId',
        );
        throw Exception('Project not found');
      }
      final projectName =
          projectDoc.data()?['name'] as String? ?? 'Unknown Project';
      appLogger.d('$_logTag Project found: $projectName');

      // Check if invitation already exists
      appLogger.d('$_logTag Checking for existing invitation');
      final existing = await _invitationsCollection
          .where('projectId', isEqualTo: projectId)
          .where('invitedEmail', isEqualTo: email.toLowerCase())
          .where('status', isEqualTo: InvitationStatus.pending.name)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        appLogger.w(
          '$_logTag Duplicate invitation projectId=$projectId email=${maskEmail(email)}',
        );
        throw Exception('Invitation already sent to this email');
      }

      // Check if user with this email exists
      appLogger.d('$_logTag Looking up user by email');
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      final String? invitedUserId = usersQuery.docs.isNotEmpty
          ? usersQuery.docs.first.id
          : null;
      appLogger.d(
        '$_logTag User lookup result: ${invitedUserId != null ? "found userId=$invitedUserId" : "not found"}',
      );

      // Create invitation
      final invitationData = {
        'projectId': projectId,
        'projectName': projectName,
        'invitedByUserId': currentUser.id,
        'invitedByUserName': currentUser.displayName ?? currentUser.email,
        'invitedEmail': email.toLowerCase(),
        'invitedUserId': invitedUserId,
        'status': InvitationStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
        'role': role.name,
        'message': message,
      };

      final docRef = await logTimedAsync(
        '$_logTag sendInvitation write invitation',
        () => _invitationsCollection.add(invitationData),
        level: Level.debug,
      );
      appLogger.d('$_logTag Invitation created invitationId=${docRef.id}');

      // If user exists, add to their pending invitations
      if (invitedUserId != null) {
        appLogger.d(
          '$_logTag Adding to user pending invitations userId=$invitedUserId',
        );
        await _firestore
            .collection('users')
            .doc(invitedUserId)
            .collection('pendingInvitations')
            .doc(docRef.id)
            .set({
              'invitationId': docRef.id,
              'projectId': projectId,
              'projectName': projectName,
              'invitedBy': currentUser.displayName ?? currentUser.email,
              'createdAt': FieldValue.serverTimestamp(),
            });

        // Send notification to invited user
        appLogger.d('$_logTag Sending notification to invited user');
        try {
          await _notificationRepository?.sendNotification(
            userId: invitedUserId,
            type: NotificationType.invitationReceived,
            title: 'Project Invitation',
            body:
                '${currentUser.displayName ?? currentUser.email} invited you to \'$projectName\'',
            imageUrl: currentUser.photoUrl,
            data: {
              'invitationId': docRef.id,
              'projectId': projectId,
              'projectName': projectName,
              'invitedBy': currentUser.displayName ?? currentUser.email,
              'role': role.name,
            },
            actionUrl: '/invitations',
          );
        } catch (e, stackTrace) {
          appLogger.e(
            '$_logTag Failed to send invitation notification',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      appLogger.i('$_logTag sendInvitation success invitationId=${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag sendInvitation failed projectId=$projectId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<MemberInvitation>> getUserInvitations({
    String? userId,
    String? email,
  }) {
    appLogger.d(
      '$_logTag getUserInvitations userId=$userId email=${email != null ? maskEmail(email) : 'null'}',
    );
    if (userId == null && email == null) {
      appLogger.e(
        '$_logTag getUserInvitations failed: Both userId and email are null',
      );
      throw ArgumentError('Either userId or email must be provided');
    }

    Query query = _invitationsCollection;

    if (userId != null) {
      query = query.where('invitedUserId', isEqualTo: userId);
    } else if (email != null) {
      query = query.where('invitedEmail', isEqualTo: email.toLowerCase());
    }

    return query
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          appLogger.d(
            '$_logTag getUserInvitations snapshot count=${snapshot.docs.length}',
          );
          return snapshot.docs
              .map(
                (doc) => MemberInvitation.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  @override
  Stream<List<MemberInvitation>> getProjectInvitations(String projectId) {
    appLogger.d(
      '$_logTag getProjectInvitations subscribed projectId=$projectId',
    );
    return _invitationsCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          appLogger.d(
            '$_logTag getProjectInvitations snapshot count=${snapshot.docs.length}',
          );
          return snapshot.docs
              .map(
                (doc) => MemberInvitation.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  @override
  Future<MemberInvitation?> getInvitation(String invitationId) async {
    appLogger.d('$_logTag getInvitation invitationId=$invitationId');
    try {
      final doc = await logTimedAsync(
        '$_logTag getInvitation query',
        () => _invitationsCollection.doc(invitationId).get(),
        level: Level.debug,
      );
      if (!doc.exists) {
        appLogger.d('$_logTag getInvitation: Invitation not found');
        return null;
      }

      appLogger.d('$_logTag getInvitation success invitationId=$invitationId');
      return MemberInvitation.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getInvitation failed invitationId=$invitationId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    appLogger.i('$_logTag acceptInvitation invitationId=$invitationId');
    try {
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        appLogger.e('$_logTag acceptInvitation failed: User not authenticated');
        throw Exception('User not authenticated');
      }

      final invitation = await getInvitation(invitationId);
      if (invitation == null) {
        appLogger.e('$_logTag acceptInvitation failed: Invitation not found');
        throw Exception('Invitation not found');
      }

      appLogger.d(
        '$_logTag Checking permissions - currentUser.email=${maskEmail(currentUser.email)}, '
        'invitation.invitedEmail=${maskEmail(invitation.invitedEmail)}, '
        'invitation.invitedUserId=${invitation.invitedUserId ?? "null"}',
      );

      if (invitation.status != InvitationStatus.pending) {
        appLogger.w(
          '$_logTag Invitation no longer pending status=${invitation.status}',
        );
        throw Exception('Invitation is no longer pending');
      }

      // Start a batch write
      final batch = _firestore.batch();

      // Update invitation status
      batch.update(_invitationsCollection.doc(invitationId), {
        'status': InvitationStatus.accepted.name,
        'respondedAt': FieldValue.serverTimestamp(),
        'invitedUserId': currentUser.id,
      });

      // Add user to project members subcollection
      final memberRef = _firestore
          .collection('projects')
          .doc(invitation.projectId)
          .collection('members')
          .doc(currentUser.id);

      batch.set(memberRef, {
        'userId': currentUser.id,
        'email': currentUser.email,
        'displayName': currentUser.displayName ?? currentUser.email,
        'photoUrl': currentUser.photoUrl,
        'role': invitation.role.name,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': invitation.invitedByUserId,
      });

      // Update project document with new member
      final projectRef = _firestore
          .collection('projects')
          .doc(invitation.projectId);
      batch.update(projectRef, {
        'members': FieldValue.arrayUnion([currentUser.id]),
        'memberRoles.${currentUser.id}': invitation.role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from pending invitations
      batch.delete(
        _firestore
            .collection('users')
            .doc(currentUser.id)
            .collection('pendingInvitations')
            .doc(invitationId),
      );

      await batch.commit();

      // Send notification to inviter
      try {
        await _notificationRepository?.sendNotification(
          userId: invitation.invitedByUserId,
          type: NotificationType.invitationAccepted,
          title: 'Invitation Accepted',
          body:
              '${currentUser.displayName ?? currentUser.email} accepted your invitation to \'${invitation.projectName}\'',
          imageUrl: currentUser.photoUrl,
          data: {
            'projectId': invitation.projectId,
            'projectName': invitation.projectName,
            'userId': currentUser.id,
            'userName': currentUser.displayName ?? currentUser.email,
          },
          actionUrl: '/projects/${invitation.projectId}',
        );

        // Notify other project members
        final membersSnapshot = await _firestore
            .collection('projects')
            .doc(invitation.projectId)
            .collection('members')
            .get();

        for (final memberDoc in membersSnapshot.docs) {
          final memberId = memberDoc.id;
          if (memberId != currentUser.id &&
              memberId != invitation.invitedByUserId) {
            await _notificationRepository?.sendNotification(
              userId: memberId,
              type: NotificationType.memberAdded,
              title: 'New Team Member',
              body:
                  '${currentUser.displayName ?? currentUser.email} joined \'${invitation.projectName}\'',
              imageUrl: currentUser.photoUrl,
              data: {
                'projectId': invitation.projectId,
                'projectName': invitation.projectName,
                'userId': currentUser.id,
                'userName': currentUser.displayName ?? currentUser.email,
              },
              actionUrl: '/projects/${invitation.projectId}/members',
            );
          }
        }
      } catch (e, stackTrace) {
        appLogger.e(
          '$_logTag Failed to send acceptance notifications',
          error: e,
          stackTrace: stackTrace,
        );
      }
      appLogger.i(
        '$_logTag acceptInvitation success invitationId=$invitationId',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag acceptInvitation failed invitationId=$invitationId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    appLogger.i('$_logTag declineInvitation invitationId=$invitationId');
    try {
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        appLogger.e(
          '$_logTag declineInvitation failed: User not authenticated',
        );
        throw Exception('User not authenticated');
      }

      final invitation = await getInvitation(invitationId);
      if (invitation == null) {
        throw Exception('Invitation not found');
      }

      final batch = _firestore.batch();

      // Update invitation status
      batch.update(_invitationsCollection.doc(invitationId), {
        'status': InvitationStatus.declined.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Remove from pending invitations if user exists
      if (invitation.invitedUserId != null) {
        batch.delete(
          _firestore
              .collection('users')
              .doc(invitation.invitedUserId)
              .collection('pendingInvitations')
              .doc(invitationId),
        );
      }

      await batch.commit();

      // Send notification to inviter
      try {
        await _notificationRepository?.sendNotification(
          userId: invitation.invitedByUserId,
          type: NotificationType.invitationDeclined,
          title: 'Invitation Declined',
          body:
              '${currentUser.displayName ?? currentUser.email} declined your invitation to \'${invitation.projectName}\'',
          imageUrl: currentUser.photoUrl,
          data: {
            'projectId': invitation.projectId,
            'projectName': invitation.projectName,
            'userId': currentUser.id,
            'userName': currentUser.displayName ?? currentUser.email,
          },
          actionUrl: '/projects/${invitation.projectId}/members',
        );
      } catch (e, stackTrace) {
        appLogger.e(
          '$_logTag Failed to send decline notification',
          error: e,
          stackTrace: stackTrace,
        );
      }
      appLogger.i(
        '$_logTag declineInvitation success invitationId=$invitationId',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag declineInvitation failed invitationId=$invitationId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    appLogger.i('$_logTag cancelInvitation invitationId=$invitationId');
    try {
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        appLogger.e('$_logTag cancelInvitation failed: User not authenticated');
        throw Exception('User not authenticated');
      }

      final invitation = await getInvitation(invitationId);
      if (invitation == null) {
        appLogger.e('$_logTag cancelInvitation failed: Invitation not found');
        throw Exception('Invitation not found');
      }

      if (invitation.invitedByUserId != currentUser.id) {
        appLogger.w(
          '$_logTag cancelInvitation failed: Permission denied currentUserId=${currentUser.id}',
        );
        throw Exception('Only the sender can cancel an invitation');
      }

      final batch = _firestore.batch();

      // Update invitation status
      batch.update(_invitationsCollection.doc(invitationId), {
        'status': InvitationStatus.cancelled.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Remove from pending invitations if user exists
      if (invitation.invitedUserId != null) {
        batch.delete(
          _firestore
              .collection('users')
              .doc(invitation.invitedUserId)
              .collection('pendingInvitations')
              .doc(invitationId),
        );
      }

      await logTimedAsync(
        '$_logTag cancelInvitation batch commit',
        () => batch.commit(),
      );
      appLogger.i(
        '$_logTag cancelInvitation success invitationId=$invitationId',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag cancelInvitation failed invitationId=$invitationId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteInvitation(String invitationId) async {
    appLogger.i('$_logTag deleteInvitation invitationId=$invitationId');
    try {
      final invitation = await getInvitation(invitationId);
      if (invitation == null) {
        appLogger.w(
          '$_logTag deleteInvitation: Invitation not found invitationId=$invitationId',
        );
        return;
      }

      final batch = _firestore.batch();

      // Delete invitation
      batch.delete(_invitationsCollection.doc(invitationId));

      // Remove from pending invitations if user exists
      if (invitation.invitedUserId != null) {
        batch.delete(
          _firestore
              .collection('users')
              .doc(invitation.invitedUserId)
              .collection('pendingInvitations')
              .doc(invitationId),
        );
      }

      await logTimedAsync(
        '$_logTag deleteInvitation batch commit',
        () => batch.commit(),
      );
      appLogger.i(
        '$_logTag deleteInvitation success invitationId=$invitationId',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteInvitation failed invitationId=$invitationId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<bool> hasPendingInvitation({
    required String projectId,
    required String email,
  }) async {
    appLogger.d(
      '$_logTag hasPendingInvitation projectId=$projectId email=${maskEmail(email)}',
    );
    try {
      final query = await logTimedAsync(
        '$_logTag hasPendingInvitation query',
        () => _invitationsCollection
            .where('projectId', isEqualTo: projectId)
            .where('invitedEmail', isEqualTo: email.toLowerCase())
            .where('status', isEqualTo: InvitationStatus.pending.name)
            .limit(1)
            .get(),
        level: Level.debug,
      );

      final hasPending = query.docs.isNotEmpty;
      appLogger.d('$_logTag hasPendingInvitation result=$hasPending');
      return hasPending;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag hasPendingInvitation failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Helper method to get current user
  Future<AppUser?> _getCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        appLogger.w('$_logTag _getCurrentUser: No authenticated Firebase user');
        return null;
      }

      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        appLogger.w(
          '$_logTag _getCurrentUser: User document not found userId=${firebaseUser.uid}',
        );
        return null;
      }

      final userData = userDoc.data()!;

      // Parse createdAt - handle both Timestamp and String formats
      DateTime createdAt = DateTime.now();
      final createdAtValue = userData['createdAt'];
      if (createdAtValue is Timestamp) {
        createdAt = createdAtValue.toDate();
      } else if (createdAtValue is String) {
        try {
          createdAt = DateTime.parse(createdAtValue);
        } catch (e) {
          appLogger.w(
            '$_logTag Failed to parse createdAt string: $createdAtValue',
          );
        }
      }

      return AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: userData['displayName'] as String?,
        photoUrl: userData['photoUrl'] as String?,
        createdAt: createdAt,
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag _getCurrentUser failed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
