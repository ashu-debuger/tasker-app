// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sticky_note_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing sticky notes

@ProviderFor(StickyNoteNotifier)
const stickyNoteProvider = StickyNoteNotifierFamily._();

/// Notifier for managing sticky notes
final class StickyNoteNotifierProvider
    extends $NotifierProvider<StickyNoteNotifier, StickyNoteState> {
  /// Notifier for managing sticky notes
  const StickyNoteNotifierProvider._({
    required StickyNoteNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stickyNoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stickyNoteNotifierHash();

  @override
  String toString() {
    return r'stickyNoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  StickyNoteNotifier create() => StickyNoteNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StickyNoteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StickyNoteState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StickyNoteNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stickyNoteNotifierHash() =>
    r'faf589276161f95a07e83cb4d49d4696800e2c3a';

/// Notifier for managing sticky notes

final class StickyNoteNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          StickyNoteNotifier,
          StickyNoteState,
          StickyNoteState,
          StickyNoteState,
          String
        > {
  const StickyNoteNotifierFamily._()
    : super(
        retry: null,
        name: r'stickyNoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for managing sticky notes

  StickyNoteNotifierProvider call(String userId) =>
      StickyNoteNotifierProvider._(argument: userId, from: this);

  @override
  String toString() => r'stickyNoteProvider';
}

/// Notifier for managing sticky notes

abstract class _$StickyNoteNotifier extends $Notifier<StickyNoteState> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  StickyNoteState build(String userId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<StickyNoteState, StickyNoteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StickyNoteState, StickyNoteState>,
              StickyNoteState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
