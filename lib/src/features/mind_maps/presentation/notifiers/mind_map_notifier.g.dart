// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mind_map_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing mind map state and operations

@ProviderFor(MindMapNotifier)
const mindMapProvider = MindMapNotifierProvider._();

/// Notifier for managing mind map state and operations
final class MindMapNotifierProvider
    extends $NotifierProvider<MindMapNotifier, MindMapState> {
  /// Notifier for managing mind map state and operations
  const MindMapNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mindMapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mindMapNotifierHash();

  @$internal
  @override
  MindMapNotifier create() => MindMapNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MindMapState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MindMapState>(value),
    );
  }
}

String _$mindMapNotifierHash() => r'3347fbff44e003c91b0822ae69b68881a302afd8';

/// Notifier for managing mind map state and operations

abstract class _$MindMapNotifier extends $Notifier<MindMapState> {
  MindMapState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MindMapState, MindMapState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MindMapState, MindMapState>,
              MindMapState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for streaming mind maps for a user

@ProviderFor(userMindMaps)
const userMindMapsProvider = UserMindMapsFamily._();

/// Provider for streaming mind maps for a user

final class UserMindMapsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MindMap>>,
          List<MindMap>,
          Stream<List<MindMap>>
        >
    with $FutureModifier<List<MindMap>>, $StreamProvider<List<MindMap>> {
  /// Provider for streaming mind maps for a user
  const UserMindMapsProvider._({
    required UserMindMapsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userMindMapsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userMindMapsHash();

  @override
  String toString() {
    return r'userMindMapsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MindMap>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MindMap>> create(Ref ref) {
    final argument = this.argument as String;
    return userMindMaps(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserMindMapsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userMindMapsHash() => r'b3b6590aa12a15ba7c14f638534dae1fa93143fd';

/// Provider for streaming mind maps for a user

final class UserMindMapsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MindMap>>, String> {
  const UserMindMapsFamily._()
    : super(
        retry: null,
        name: r'userMindMapsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for streaming mind maps for a user

  UserMindMapsProvider call(String userId) =>
      UserMindMapsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userMindMapsProvider';
}
