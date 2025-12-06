import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/providers.dart';
import '../../domain/models/member_invitation.dart';
import '../../domain/models/project_role.dart';
import '../notifiers/project_list_notifier.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../../core/utils/app_logger.dart';

part 'invitation_notifier.g.dart';

/// State for invitation operations
class InvitationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const InvitationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  InvitationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return InvitationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Notifier for managing project invitations
@riverpod
class InvitationNotifier extends _$InvitationNotifier {
  @override
  InvitationState build() {
    return const InvitationState();
  }

  /// Send an invitation to join a project
  Future<void> sendInvitation({
    required String projectId,
    required String email,
    required ProjectRole role,
    String? message,
  }) async {
    appLogger.i(
      '[InvitationNotifier] sendInvitation started '
      'projectId=$projectId email=${maskEmail(email)} role=${role.name}',
    );
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final repository = ref.read(invitationRepositoryProvider);

      // Validate email format
      if (!_isValidEmail(email)) {
        appLogger.w(
          '[InvitationNotifier] Invalid email format: ${maskEmail(email)}',
        );
        throw Exception('Invalid email address');
      }

      // Check if invitation already exists
      appLogger.d('[InvitationNotifier] Checking for pending invitation');
      final hasPending = await repository.hasPendingInvitation(
        projectId: projectId,
        email: email,
      );

      if (hasPending) {
        appLogger.w(
          '[InvitationNotifier] Duplicate invitation detected '
          'projectId=$projectId email=${maskEmail(email)}',
        );
        throw Exception('An invitation has already been sent to this email');
      }

      await repository.sendInvitation(
        projectId: projectId,
        email: email,
        role: role,
        message: message,
      );

      appLogger.i(
        '[InvitationNotifier] sendInvitation success '
        'projectId=$projectId email=${maskEmail(email)}',
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invitation sent successfully',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '[InvitationNotifier] sendInvitation failed '
        'projectId=$projectId email=${maskEmail(email)}',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Accept an invitation
  Future<void> acceptInvitation(String invitationId) async {
    appLogger.i(
      '[InvitationNotifier] acceptInvitation invitationId=$invitationId',
    );
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final repository = ref.read(invitationRepositoryProvider);
      await repository.acceptInvitation(invitationId);

      // Refresh projects and invitations after accepting
      ref.invalidate(projectListProvider);
      ref.invalidate(userInvitationsProvider);

      appLogger.i(
        '[InvitationNotifier] acceptInvitation success invitationId=$invitationId',
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invitation accepted! Welcome to the project',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '[InvitationNotifier] acceptInvitation failed invitationId=$invitationId',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Decline an invitation
  Future<void> declineInvitation(String invitationId) async {
    appLogger.i(
      '[InvitationNotifier] declineInvitation invitationId=$invitationId',
    );
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final repository = ref.read(invitationRepositoryProvider);
      await repository.declineInvitation(invitationId);

      appLogger.i(
        '[InvitationNotifier] declineInvitation success invitationId=$invitationId',
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invitation declined',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '[InvitationNotifier] declineInvitation failed invitationId=$invitationId',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Cancel an invitation (by sender)
  Future<void> cancelInvitation(String invitationId) async {
    appLogger.i(
      '[InvitationNotifier] cancelInvitation invitationId=$invitationId',
    );
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final repository = ref.read(invitationRepositoryProvider);
      await repository.cancelInvitation(invitationId);

      appLogger.i(
        '[InvitationNotifier] cancelInvitation success invitationId=$invitationId',
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invitation cancelled',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '[InvitationNotifier] cancelInvitation failed invitationId=$invitationId',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Clear any error or success messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Email validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}

/// Stream provider for user's pending invitations
@riverpod
Stream<List<MemberInvitation>> userInvitations(Ref ref) {
  final authState = ref.watch(authProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(invitationRepositoryProvider);
  return repository.getUserInvitations(userId: user.id, email: user.email);
}

/// Stream provider for project invitations
@riverpod
Stream<List<MemberInvitation>> projectInvitations(Ref ref, String projectId) {
  final repository = ref.watch(invitationRepositoryProvider);
  return repository.getProjectInvitations(projectId);
}
