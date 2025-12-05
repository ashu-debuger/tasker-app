// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_suggestion_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(taskSuggestionRepository)
const taskSuggestionRepositoryProvider = TaskSuggestionRepositoryProvider._();

final class TaskSuggestionRepositoryProvider
    extends
        $FunctionalProvider<
          TaskSuggestionRepository,
          TaskSuggestionRepository,
          TaskSuggestionRepository
        >
    with $Provider<TaskSuggestionRepository> {
  const TaskSuggestionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskSuggestionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskSuggestionRepositoryHash();

  @$internal
  @override
  $ProviderElement<TaskSuggestionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TaskSuggestionRepository create(Ref ref) {
    return taskSuggestionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskSuggestionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskSuggestionRepository>(value),
    );
  }
}

String _$taskSuggestionRepositoryHash() =>
    r'7e5acf1297b14ac1cbd2454a18a167be3a4fa3b2';

/// Async controller that fetches suggestions for a specific context.

@ProviderFor(TaskSuggestionController)
const taskSuggestionControllerProvider = TaskSuggestionControllerFamily._();

/// Async controller that fetches suggestions for a specific context.
final class TaskSuggestionControllerProvider
    extends
        $AsyncNotifierProvider<TaskSuggestionController, List<TaskSuggestion>> {
  /// Async controller that fetches suggestions for a specific context.
  const TaskSuggestionControllerProvider._({
    required TaskSuggestionControllerFamily super.from,
    required TaskSuggestionRequest super.argument,
  }) : super(
         retry: null,
         name: r'taskSuggestionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskSuggestionControllerHash();

  @override
  String toString() {
    return r'taskSuggestionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TaskSuggestionController create() => TaskSuggestionController();

  @override
  bool operator ==(Object other) {
    return other is TaskSuggestionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskSuggestionControllerHash() =>
    r'ad9d0b90938f24b5927beb05367bf5f6a07ce3a3';

/// Async controller that fetches suggestions for a specific context.

final class TaskSuggestionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TaskSuggestionController,
          AsyncValue<List<TaskSuggestion>>,
          List<TaskSuggestion>,
          FutureOr<List<TaskSuggestion>>,
          TaskSuggestionRequest
        > {
  const TaskSuggestionControllerFamily._()
    : super(
        retry: null,
        name: r'taskSuggestionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Async controller that fetches suggestions for a specific context.

  TaskSuggestionControllerProvider call(TaskSuggestionRequest request) =>
      TaskSuggestionControllerProvider._(argument: request, from: this);

  @override
  String toString() => r'taskSuggestionControllerProvider';
}

/// Async controller that fetches suggestions for a specific context.

abstract class _$TaskSuggestionController
    extends $AsyncNotifier<List<TaskSuggestion>> {
  late final _$args = ref.$arg as TaskSuggestionRequest;
  TaskSuggestionRequest get request => _$args;

  FutureOr<List<TaskSuggestion>> build(TaskSuggestionRequest request);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<AsyncValue<List<TaskSuggestion>>, List<TaskSuggestion>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TaskSuggestion>>,
                List<TaskSuggestion>
              >,
              AsyncValue<List<TaskSuggestion>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
