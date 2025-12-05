// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_detail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing task details and associated subtasks

@ProviderFor(TaskDetailNotifier)
const taskDetailProvider = TaskDetailNotifierFamily._();

/// Notifier for managing task details and associated subtasks
final class TaskDetailNotifierProvider
    extends $StreamNotifierProvider<TaskDetailNotifier, TaskDetailState> {
  /// Notifier for managing task details and associated subtasks
  const TaskDetailNotifierProvider._({
    required TaskDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'taskDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskDetailNotifierHash();

  @override
  String toString() {
    return r'taskDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TaskDetailNotifier create() => TaskDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is TaskDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskDetailNotifierHash() =>
    r'0c61415df4a28d5bedb677a5aa6c7c2273122be8';

/// Notifier for managing task details and associated subtasks

final class TaskDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TaskDetailNotifier,
          AsyncValue<TaskDetailState>,
          TaskDetailState,
          Stream<TaskDetailState>,
          String
        > {
  const TaskDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'taskDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for managing task details and associated subtasks

  TaskDetailNotifierProvider call(String taskId) =>
      TaskDetailNotifierProvider._(argument: taskId, from: this);

  @override
  String toString() => r'taskDetailProvider';
}

/// Notifier for managing task details and associated subtasks

abstract class _$TaskDetailNotifier extends $StreamNotifier<TaskDetailState> {
  late final _$args = ref.$arg as String;
  String get taskId => _$args;

  Stream<TaskDetailState> build(String taskId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<TaskDetailState>, TaskDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TaskDetailState>, TaskDetailState>,
              AsyncValue<TaskDetailState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
