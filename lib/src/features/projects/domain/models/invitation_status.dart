/// Status of a project invitation
enum InvitationStatus {
  /// Invitation sent, waiting for response
  pending,

  /// Invitation accepted by invitee
  accepted,

  /// Invitation declined by invitee
  declined,

  /// Invitation cancelled by inviter
  cancelled;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.declined:
        return 'Declined';
      case InvitationStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Color for status indicator
  String get colorHex {
    switch (this) {
      case InvitationStatus.pending:
        return '#FF9800'; // Orange
      case InvitationStatus.accepted:
        return '#4CAF50'; // Green
      case InvitationStatus.declined:
        return '#F44336'; // Red
      case InvitationStatus.cancelled:
        return '#9E9E9E'; // Gray
    }
  }
}
