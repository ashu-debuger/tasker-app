import '../models/member_invitation.dart';
import '../models/project_role.dart';

/// Repository for managing project invitations
abstract class InvitationRepository {
  /// Send an invitation to join a project
  ///
  /// [projectId] - ID of the project
  /// [email] - Email address of the invitee
  /// [role] - Role being offered
  /// [message] - Optional personal message
  ///
  /// Returns the invitation ID
  Future<String> sendInvitation({
    required String projectId,
    required String email,
    required ProjectRole role,
    String? message,
  });

  /// Get all invitations for a user (by email or userId)
  ///
  /// [userId] - User ID to fetch invitations for
  /// [email] - Email address to fetch invitations for
  ///
  /// Returns stream of invitations
  Stream<List<MemberInvitation>> getUserInvitations({
    String? userId,
    String? email,
  });

  /// Get pending invitations for a project
  ///
  /// [projectId] - Project ID
  ///
  /// Returns stream of pending invitations
  Stream<List<MemberInvitation>> getProjectInvitations(String projectId);

  /// Get a specific invitation by ID
  ///
  /// [invitationId] - Invitation ID
  ///
  /// Returns the invitation or null if not found
  Future<MemberInvitation?> getInvitation(String invitationId);

  /// Accept an invitation
  ///
  /// [invitationId] - Invitation ID to accept
  ///
  /// Throws exception if invitation is invalid or expired
  Future<void> acceptInvitation(String invitationId);

  /// Decline an invitation
  ///
  /// [invitationId] - Invitation ID to decline
  Future<void> declineInvitation(String invitationId);

  /// Cancel an invitation (by sender)
  ///
  /// [invitationId] - Invitation ID to cancel
  ///
  /// Only the sender can cancel an invitation
  Future<void> cancelInvitation(String invitationId);

  /// Delete an invitation record
  ///
  /// [invitationId] - Invitation ID to delete
  Future<void> deleteInvitation(String invitationId);

  /// Check if an email has a pending invitation for a project
  ///
  /// [projectId] - Project ID
  /// [email] - Email address
  ///
  /// Returns true if pending invitation exists
  Future<bool> hasPendingInvitation({
    required String projectId,
    required String email,
  });
}
