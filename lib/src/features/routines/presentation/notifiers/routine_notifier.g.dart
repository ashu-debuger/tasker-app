// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoutineNotifier)
const routineProvider = RoutineNotifierFamily._();

final class RoutineNotifierProvider
    extends $StreamNotifierProvider<RoutineNotifier, List<Routine>> {
  const RoutineNotifierProvider._({
    required RoutineNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'routineProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$routineNotifierHash();

  @override
  String toString() {
    return r'routineProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RoutineNotifier create() => RoutineNotifier();

  @override
  bool operator ==(Object other) {
    return other is RoutineNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$routineNotifierHash() => r'aeeb313faf04b4cae26166b966b7b2bfdb8ff612';

final class RoutineNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RoutineNotifier,
          AsyncValue<List<Routine>>,
          List<Routine>,
          Stream<List<Routine>>,
          String
        > {
  const RoutineNotifierFamily._()
    : super(
        retry: null,
        name: r'routineProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RoutineNotifierProvider call(String userId) =>
      RoutineNotifierProvider._(argument: userId, from: this);

  @override
  String toString() => r'routineProvider';
}

abstract class _$RoutineNotifier extends $StreamNotifier<List<Routine>> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  Stream<List<Routine>> build(String userId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<List<Routine>>, List<Routine>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Routine>>, List<Routine>>,
              AsyncValue<List<Routine>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(TodaysRoutines)
const todaysRoutinesProvider = TodaysRoutinesFamily._();

final class TodaysRoutinesProvider
    extends $AsyncNotifierProvider<TodaysRoutines, List<Routine>> {
  const TodaysRoutinesProvider._({
    required TodaysRoutinesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'todaysRoutinesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todaysRoutinesHash();

  @override
  String toString() {
    return r'todaysRoutinesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TodaysRoutines create() => TodaysRoutines();

  @override
  bool operator ==(Object other) {
    return other is TodaysRoutinesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todaysRoutinesHash() => r'6817102a9495ed469267ead91e316cca9ff6adb1';

final class TodaysRoutinesFamily extends $Family
    with
        $ClassFamilyOverride<
          TodaysRoutines,
          AsyncValue<List<Routine>>,
          List<Routine>,
          FutureOr<List<Routine>>,
          String
        > {
  const TodaysRoutinesFamily._()
    : super(
        retry: null,
        name: r'todaysRoutinesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TodaysRoutinesProvider call(String userId) =>
      TodaysRoutinesProvider._(argument: userId, from: this);

  @override
  String toString() => r'todaysRoutinesProvider';
}

abstract class _$TodaysRoutines extends $AsyncNotifier<List<Routine>> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  FutureOr<List<Routine>> build(String userId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<List<Routine>>, List<Routine>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Routine>>, List<Routine>>,
              AsyncValue<List<Routine>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
