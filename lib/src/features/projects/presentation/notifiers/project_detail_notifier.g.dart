// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_detail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing project details and associated tasks

@ProviderFor(ProjectDetailNotifier)
const projectDetailProvider = ProjectDetailNotifierFamily._();

/// Notifier for managing project details and associated tasks
final class ProjectDetailNotifierProvider
    extends $StreamNotifierProvider<ProjectDetailNotifier, ProjectDetailState> {
  /// Notifier for managing project details and associated tasks
  const ProjectDetailNotifierProvider._({
    required ProjectDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectDetailNotifierHash();

  @override
  String toString() {
    return r'projectDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProjectDetailNotifier create() => ProjectDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is ProjectDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectDetailNotifierHash() =>
    r'6d203190887598f8a4e42fab4c117fff213e8424';

/// Notifier for managing project details and associated tasks

final class ProjectDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ProjectDetailNotifier,
          AsyncValue<ProjectDetailState>,
          ProjectDetailState,
          Stream<ProjectDetailState>,
          String
        > {
  const ProjectDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'projectDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for managing project details and associated tasks

  ProjectDetailNotifierProvider call(String projectId) =>
      ProjectDetailNotifierProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectDetailProvider';
}

/// Notifier for managing project details and associated tasks

abstract class _$ProjectDetailNotifier
    extends $StreamNotifier<ProjectDetailState> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  Stream<ProjectDetailState> build(String projectId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<ProjectDetailState>, ProjectDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ProjectDetailState>, ProjectDetailState>,
              AsyncValue<ProjectDetailState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
