// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_progress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(taskSubtaskSummary)
const taskSubtaskSummaryProvider = TaskSubtaskSummaryFamily._();

final class TaskSubtaskSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<TaskSubtaskSummary>,
          TaskSubtaskSummary,
          Stream<TaskSubtaskSummary>
        >
    with
        $FutureModifier<TaskSubtaskSummary>,
        $StreamProvider<TaskSubtaskSummary> {
  const TaskSubtaskSummaryProvider._({
    required TaskSubtaskSummaryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'taskSubtaskSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskSubtaskSummaryHash();

  @override
  String toString() {
    return r'taskSubtaskSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<TaskSubtaskSummary> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TaskSubtaskSummary> create(Ref ref) {
    final argument = this.argument as String;
    return taskSubtaskSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskSubtaskSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskSubtaskSummaryHash() =>
    r'0bffa61c97a459e0f0b2f0d8e40768feeab57619';

final class TaskSubtaskSummaryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<TaskSubtaskSummary>, String> {
  const TaskSubtaskSummaryFamily._()
    : super(
        retry: null,
        name: r'taskSubtaskSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TaskSubtaskSummaryProvider call(String taskId) =>
      TaskSubtaskSummaryProvider._(argument: taskId, from: this);

  @override
  String toString() => r'taskSubtaskSummaryProvider';
}
