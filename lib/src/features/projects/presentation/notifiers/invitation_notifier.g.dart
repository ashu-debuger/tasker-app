// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing project invitations

@ProviderFor(InvitationNotifier)
const invitationProvider = InvitationNotifierProvider._();

/// Notifier for managing project invitations
final class InvitationNotifierProvider
    extends $NotifierProvider<InvitationNotifier, InvitationState> {
  /// Notifier for managing project invitations
  const InvitationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invitationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invitationNotifierHash();

  @$internal
  @override
  InvitationNotifier create() => InvitationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvitationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvitationState>(value),
    );
  }
}

String _$invitationNotifierHash() =>
    r'55af06f9a2d158cd457850b8aabdff83a51fce1b';

/// Notifier for managing project invitations

abstract class _$InvitationNotifier extends $Notifier<InvitationState> {
  InvitationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<InvitationState, InvitationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InvitationState, InvitationState>,
              InvitationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Stream provider for user's pending invitations

@ProviderFor(userInvitations)
const userInvitationsProvider = UserInvitationsProvider._();

/// Stream provider for user's pending invitations

final class UserInvitationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemberInvitation>>,
          List<MemberInvitation>,
          Stream<List<MemberInvitation>>
        >
    with
        $FutureModifier<List<MemberInvitation>>,
        $StreamProvider<List<MemberInvitation>> {
  /// Stream provider for user's pending invitations
  const UserInvitationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userInvitationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userInvitationsHash();

  @$internal
  @override
  $StreamProviderElement<List<MemberInvitation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MemberInvitation>> create(Ref ref) {
    return userInvitations(ref);
  }
}

String _$userInvitationsHash() => r'39be91c5cc80d8756fce12678d82e4b3dc24bd36';

/// Stream provider for project invitations

@ProviderFor(projectInvitations)
const projectInvitationsProvider = ProjectInvitationsFamily._();

/// Stream provider for project invitations

final class ProjectInvitationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemberInvitation>>,
          List<MemberInvitation>,
          Stream<List<MemberInvitation>>
        >
    with
        $FutureModifier<List<MemberInvitation>>,
        $StreamProvider<List<MemberInvitation>> {
  /// Stream provider for project invitations
  const ProjectInvitationsProvider._({
    required ProjectInvitationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectInvitationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectInvitationsHash();

  @override
  String toString() {
    return r'projectInvitationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MemberInvitation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MemberInvitation>> create(Ref ref) {
    final argument = this.argument as String;
    return projectInvitations(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectInvitationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectInvitationsHash() =>
    r'3cf3d6a281677fb155ae236864f2f1dab3755e5f';

/// Stream provider for project invitations

final class ProjectInvitationsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MemberInvitation>>, String> {
  const ProjectInvitationsFamily._()
    : super(
        retry: null,
        name: r'projectInvitationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for project invitations

  ProjectInvitationsProvider call(String projectId) =>
      ProjectInvitationsProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectInvitationsProvider';
}
