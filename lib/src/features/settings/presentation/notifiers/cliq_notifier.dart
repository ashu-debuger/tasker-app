import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tasker/src/features/settings/data/models/cliq_notification_settings.dart';
import 'package:tasker/src/features/settings/data/models/cliq_user_mapping.dart';
import 'package:tasker/src/features/settings/data/repositories/cliq_repository.dart';

part 'cliq_notifier.g.dart';

/// Provider for CliqRepository
@riverpod
CliqRepository cliqRepository(Ref ref) {
  return CliqRepository();
}

/// State for Cliq integration
class CliqState {
  final bool isLoading;
  final bool isLinked;
  final bool isAuthenticated; // Password verification passed
  final CliqUserMapping? mapping;
  final CliqNotificationSettings settings;
  final String? linkingCode;
  final int? challengeNumber; // 4-digit number for verification
  final bool isPendingVerification; // Waiting for Cliq user to verify
  final String? error;

  const CliqState({
    this.isLoading = false,
    this.isLinked = false,
    this.isAuthenticated = false,
    this.mapping,
    this.settings = const CliqNotificationSettings(),
    this.linkingCode,
    this.challengeNumber,
    this.isPendingVerification = false,
    this.error,
  });

  CliqState copyWith({
    bool? isLoading,
    bool? isLinked,
    bool? isAuthenticated,
    CliqUserMapping? mapping,
    CliqNotificationSettings? settings,
    String? linkingCode,
    int? challengeNumber,
    bool? isPendingVerification,
    String? error,
    bool clearMapping = false,
    bool clearLinkingCode = false,
    bool clearChallengeNumber = false,
    bool clearError = false,
  }) {
    return CliqState(
      isLoading: isLoading ?? this.isLoading,
      isLinked: isLinked ?? this.isLinked,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      mapping: clearMapping ? null : (mapping ?? this.mapping),
      settings: settings ?? this.settings,
      linkingCode: clearLinkingCode ? null : (linkingCode ?? this.linkingCode),
      challengeNumber: clearChallengeNumber
          ? null
          : (challengeNumber ?? this.challengeNumber),
      isPendingVerification:
          isPendingVerification ?? this.isPendingVerification,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for managing Cliq integration state
@riverpod
class CliqNotifier extends _$CliqNotifier {
  late CliqRepository _repository;

  @override
  CliqState build(String userId, String userEmail) {
    _repository = ref.watch(cliqRepositoryProvider);
    // Schedule the async load after build completes
    Future.microtask(() => loadCliqStatus());
    return const CliqState(isLoading: true);
  }

  String get _userId => userId;
  String get _userEmail => userEmail;

  /// Set authentication status (after password verification)
  void setAuthenticated(bool authenticated) {
    state = state.copyWith(isAuthenticated: authenticated);
  }

  /// Clear authentication when leaving the screen
  void clearAuthentication() {
    state = state.copyWith(isAuthenticated: false);
  }

  /// Load current Cliq link status and settings
  Future<void> loadCliqStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isLinked = await _repository.isCliqLinked(_userId);
      final mapping = isLinked
          ? await _repository.getCliqMapping(_userId)
          : null;
      final settings = await _repository.getNotificationSettings(_userId);

      state = state.copyWith(
        isLoading: false,
        isLinked: isLinked,
        mapping: mapping,
        settings: settings,
        clearMapping: !isLinked,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load Cliq status: $e',
      );
    }
  }

  /// Generate a linking code for Cliq (with challenge number)
  Future<String?> generateLinkingCode() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.generateLinkingCode(_userId, _userEmail);

      if (result != null) {
        state = state.copyWith(
          isLoading: false,
          linkingCode: result.code,
          challengeNumber: result.challengeNumber,
          isPendingVerification: false,
        );
        return result.code;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to generate linking code',
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to generate linking code: $e',
      );
      return null;
    }
  }

  /// Verify challenge number for secure account linking
  /// Returns true if verification successful
  Future<bool> verifyChallenge(int selectedChallenge) async {
    final code = state.linkingCode;
    if (code == null) {
      state = state.copyWith(error: 'No linking code available');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _repository.verifyChallenge(
        code: code,
        challengeNumber: selectedChallenge,
        userId: _userId,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          isPendingVerification:
              true, // Now waiting for Cliq to complete linking
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Incorrect verification number. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verification failed: $e',
      );
      return false;
    }
  }

  /// Unlink Cliq account
  Future<bool> unlinkCliq() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _repository.unlinkCliq(_userId);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          isLinked: false,
          clearMapping: true,
          clearLinkingCode: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to unlink Cliq account',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to unlink: $e');
      return false;
    }
  }

  /// Update notification settings
  Future<bool> updateNotificationSettings(
    CliqNotificationSettings settings,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _repository.updateNotificationSettings(
        _userId,
        settings,
      );

      if (success) {
        state = state.copyWith(isLoading: false, settings: settings);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update settings',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update settings: $e',
      );
      return false;
    }
  }

  /// Toggle a specific notification type
  Future<bool> toggleNotificationType(String type, bool enabled) async {
    final currentSettings = state.settings;
    CliqNotificationSettings newSettings;

    switch (type) {
      case 'task_assigned':
        newSettings = currentSettings.copyWith(taskAssigned: enabled);
        break;
      case 'task_completed':
        newSettings = currentSettings.copyWith(taskCompleted: enabled);
        break;
      case 'task_due_soon':
        newSettings = currentSettings.copyWith(taskDueSoon: enabled);
        break;
      case 'task_overdue':
        newSettings = currentSettings.copyWith(taskOverdue: enabled);
        break;
      case 'comment_added':
        newSettings = currentSettings.copyWith(commentAdded: enabled);
        break;
      case 'project_invite':
        newSettings = currentSettings.copyWith(projectInvite: enabled);
        break;
      case 'member_joined':
        newSettings = currentSettings.copyWith(memberJoined: enabled);
        break;
      default:
        return false;
    }

    return updateNotificationSettings(newSettings);
  }

  /// Enable Do Not Disturb
  Future<bool> enableDoNotDisturb({int hours = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _repository.enableDoNotDisturb(
        _userId,
        hours: hours,
      );

      if (success) {
        final newDnd = DoNotDisturb(
          enabled: true,
          until: DateTime.now().add(Duration(hours: hours)),
        );
        state = state.copyWith(
          isLoading: false,
          settings: state.settings.copyWith(doNotDisturb: newDnd),
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to enable DND');
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to enable DND: $e',
      );
      return false;
    }
  }

  /// Disable Do Not Disturb
  Future<bool> disableDoNotDisturb() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _repository.disableDoNotDisturb(_userId);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          settings: state.settings.copyWith(
            doNotDisturb: const DoNotDisturb(enabled: false),
          ),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to disable DND',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to disable DND: $e',
      );
      return false;
    }
  }

  /// Update quiet hours
  Future<bool> updateQuietHours({
    required bool enabled,
    int startHour = 22,
    int endHour = 8,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _repository.updateQuietHours(
        _userId,
        enabled: enabled,
        startHour: startHour,
        endHour: endHour,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          settings: state.settings.copyWith(
            quietHours: QuietHours(
              enabled: enabled,
              startHour: startHour,
              endHour: endHour,
            ),
          ),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update quiet hours',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update quiet hours: $e',
      );
      return false;
    }
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Stream provider for watching Cliq link status
@riverpod
Stream<bool> cliqLinkStatus(Ref ref, String userId) {
  final repository = ref.watch(cliqRepositoryProvider);
  return repository.watchCliqLinkStatus(userId);
}

/// Stream provider for watching notification settings
@riverpod
Stream<CliqNotificationSettings> cliqNotificationSettings(
  Ref ref,
  String userId,
) {
  final repository = ref.watch(cliqRepositoryProvider);
  return repository.watchNotificationSettings(userId);
}
