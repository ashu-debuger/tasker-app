// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_members_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing project members

@ProviderFor(ProjectMembersNotifier)
const projectMembersProvider = ProjectMembersNotifierProvider._();

/// Notifier for managing project members
final class ProjectMembersNotifierProvider
    extends $NotifierProvider<ProjectMembersNotifier, ProjectMembersState> {
  /// Notifier for managing project members
  const ProjectMembersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectMembersNotifierHash();

  @$internal
  @override
  ProjectMembersNotifier create() => ProjectMembersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectMembersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectMembersState>(value),
    );
  }
}

String _$projectMembersNotifierHash() =>
    r'429ae54ddeb5cce7f448bcea53680094366803cf';

/// Notifier for managing project members

abstract class _$ProjectMembersNotifier extends $Notifier<ProjectMembersState> {
  ProjectMembersState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ProjectMembersState, ProjectMembersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProjectMembersState, ProjectMembersState>,
              ProjectMembersState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Stream provider for project members

@ProviderFor(projectMembersList)
const projectMembersListProvider = ProjectMembersListFamily._();

/// Stream provider for project members

final class ProjectMembersListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProjectMember>>,
          List<ProjectMember>,
          Stream<List<ProjectMember>>
        >
    with
        $FutureModifier<List<ProjectMember>>,
        $StreamProvider<List<ProjectMember>> {
  /// Stream provider for project members
  const ProjectMembersListProvider._({
    required ProjectMembersListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectMembersListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectMembersListHash();

  @override
  String toString() {
    return r'projectMembersListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ProjectMember>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProjectMember>> create(Ref ref) {
    final argument = this.argument as String;
    return projectMembersList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectMembersListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectMembersListHash() =>
    r'9b63a611d6710b740c310bfec3272f0fcc3c6e94';

/// Stream provider for project members

final class ProjectMembersListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ProjectMember>>, String> {
  const ProjectMembersListFamily._()
    : super(
        retry: null,
        name: r'projectMembersListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for project members

  ProjectMembersListProvider call(String projectId) =>
      ProjectMembersListProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectMembersListProvider';
}

/// Provider to get a specific member's role

@ProviderFor(memberRole)
const memberRoleProvider = MemberRoleFamily._();

/// Provider to get a specific member's role

final class MemberRoleProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProjectRole?>,
          ProjectRole?,
          FutureOr<ProjectRole?>
        >
    with $FutureModifier<ProjectRole?>, $FutureProvider<ProjectRole?> {
  /// Provider to get a specific member's role
  const MemberRoleProvider._({
    required MemberRoleFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'memberRoleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberRoleHash();

  @override
  String toString() {
    return r'memberRoleProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ProjectRole?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProjectRole?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return memberRole(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberRoleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberRoleHash() => r'd128e34d77ebf94a3d9e7aef2f8fb4e36645ef86';

/// Provider to get a specific member's role

final class MemberRoleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProjectRole?>, (String, String)> {
  const MemberRoleFamily._()
    : super(
        retry: null,
        name: r'memberRoleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get a specific member's role

  MemberRoleProvider call(String projectId, String userId) =>
      MemberRoleProvider._(argument: (projectId, userId), from: this);

  @override
  String toString() => r'memberRoleProvider';
}

/// Provider to check if a user is a member of a project

@ProviderFor(isMember)
const isMemberProvider = IsMemberFamily._();

/// Provider to check if a user is a member of a project

final class IsMemberProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider to check if a user is a member of a project
  const IsMemberProvider._({
    required IsMemberFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'isMemberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isMemberHash();

  @override
  String toString() {
    return r'isMemberProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (String, String);
    return isMember(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is IsMemberProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isMemberHash() => r'3e3bbe4931104719d0b48c1853b81827ecea4f44';

/// Provider to check if a user is a member of a project

final class IsMemberFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, (String, String)> {
  const IsMemberFamily._()
    : super(
        retry: null,
        name: r'isMemberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to check if a user is a member of a project

  IsMemberProvider call(String projectId, String userId) =>
      IsMemberProvider._(argument: (projectId, userId), from: this);

  @override
  String toString() => r'isMemberProvider';
}

/// Stream provider for user's projects (where they are a member)

@ProviderFor(userProjectIds)
const userProjectIdsProvider = UserProjectIdsFamily._();

/// Stream provider for user's projects (where they are a member)

final class UserProjectIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  /// Stream provider for user's projects (where they are a member)
  const UserProjectIdsProvider._({
    required UserProjectIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userProjectIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userProjectIdsHash();

  @override
  String toString() {
    return r'userProjectIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return userProjectIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProjectIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userProjectIdsHash() => r'5d43301114d125e9ed51c42f7570332a253fbd64';

/// Stream provider for user's projects (where they are a member)

final class UserProjectIdsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<String>>, String> {
  const UserProjectIdsFamily._()
    : super(
        retry: null,
        name: r'userProjectIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for user's projects (where they are a member)

  UserProjectIdsProvider call(String userId) =>
      UserProjectIdsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userProjectIdsProvider';
}
