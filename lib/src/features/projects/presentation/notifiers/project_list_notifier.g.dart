// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing the list of projects

@ProviderFor(ProjectListNotifier)
const projectListProvider = ProjectListNotifierProvider._();

/// Notifier for managing the list of projects
final class ProjectListNotifierProvider
    extends $StreamNotifierProvider<ProjectListNotifier, List<Project>> {
  /// Notifier for managing the list of projects
  const ProjectListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectListNotifierHash();

  @$internal
  @override
  ProjectListNotifier create() => ProjectListNotifier();
}

String _$projectListNotifierHash() =>
    r'258b7c00c27099aded573e0a8f1ba86e519c4709';

/// Notifier for managing the list of projects

abstract class _$ProjectListNotifier extends $StreamNotifier<List<Project>> {
  Stream<List<Project>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Project>>, List<Project>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Project>>, List<Project>>,
              AsyncValue<List<Project>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
