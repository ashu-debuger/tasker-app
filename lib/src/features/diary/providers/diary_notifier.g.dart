// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing diary state

@ProviderFor(Diary)
const diaryProvider = DiaryProvider._();

/// Notifier for managing diary state
final class DiaryProvider extends $NotifierProvider<Diary, DiaryState> {
  /// Notifier for managing diary state
  const DiaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryHash();

  @$internal
  @override
  Diary create() => Diary();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryState>(value),
    );
  }
}

String _$diaryHash() => r'12fabe3c6dc7ae89bc28dda739758fd25517b5cf';

/// Notifier for managing diary state

abstract class _$Diary extends $Notifier<DiaryState> {
  DiaryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DiaryState, DiaryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryState, DiaryState>,
              DiaryState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
