// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliq_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for CliqRepository

@ProviderFor(cliqRepository)
const cliqRepositoryProvider = CliqRepositoryProvider._();

/// Provider for CliqRepository

final class CliqRepositoryProvider
    extends $FunctionalProvider<CliqRepository, CliqRepository, CliqRepository>
    with $Provider<CliqRepository> {
  /// Provider for CliqRepository
  const CliqRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cliqRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cliqRepositoryHash();

  @$internal
  @override
  $ProviderElement<CliqRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CliqRepository create(Ref ref) {
    return cliqRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CliqRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CliqRepository>(value),
    );
  }
}

String _$cliqRepositoryHash() => r'093427393b2a4866d53bcc88eb1c1a6d58b694c5';

/// Notifier for managing Cliq integration state

@ProviderFor(CliqNotifier)
const cliqProvider = CliqNotifierFamily._();

/// Notifier for managing Cliq integration state
final class CliqNotifierProvider
    extends $NotifierProvider<CliqNotifier, CliqState> {
  /// Notifier for managing Cliq integration state
  const CliqNotifierProvider._({
    required CliqNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'cliqProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cliqNotifierHash();

  @override
  String toString() {
    return r'cliqProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CliqNotifier create() => CliqNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CliqState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CliqState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CliqNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cliqNotifierHash() => r'6b454d842f479cc655c651d46c10543810bbb1b7';

/// Notifier for managing Cliq integration state

final class CliqNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CliqNotifier,
          CliqState,
          CliqState,
          CliqState,
          (String, String)
        > {
  const CliqNotifierFamily._()
    : super(
        retry: null,
        name: r'cliqProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for managing Cliq integration state

  CliqNotifierProvider call(String userId, String userEmail) =>
      CliqNotifierProvider._(argument: (userId, userEmail), from: this);

  @override
  String toString() => r'cliqProvider';
}

/// Notifier for managing Cliq integration state

abstract class _$CliqNotifier extends $Notifier<CliqState> {
  late final _$args = ref.$arg as (String, String);
  String get userId => _$args.$1;
  String get userEmail => _$args.$2;

  CliqState build(String userId, String userEmail);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2);
    final ref = this.ref as $Ref<CliqState, CliqState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CliqState, CliqState>,
              CliqState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Stream provider for watching Cliq link status

@ProviderFor(cliqLinkStatus)
const cliqLinkStatusProvider = CliqLinkStatusFamily._();

/// Stream provider for watching Cliq link status

final class CliqLinkStatusProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Stream provider for watching Cliq link status
  const CliqLinkStatusProvider._({
    required CliqLinkStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cliqLinkStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cliqLinkStatusHash();

  @override
  String toString() {
    return r'cliqLinkStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as String;
    return cliqLinkStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CliqLinkStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cliqLinkStatusHash() => r'22c7d4d736bc1ab018a75c2d00f445d638849afd';

/// Stream provider for watching Cliq link status

final class CliqLinkStatusFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, String> {
  const CliqLinkStatusFamily._()
    : super(
        retry: null,
        name: r'cliqLinkStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for watching Cliq link status

  CliqLinkStatusProvider call(String userId) =>
      CliqLinkStatusProvider._(argument: userId, from: this);

  @override
  String toString() => r'cliqLinkStatusProvider';
}

/// Stream provider for watching notification settings

@ProviderFor(cliqNotificationSettings)
const cliqNotificationSettingsProvider = CliqNotificationSettingsFamily._();

/// Stream provider for watching notification settings

final class CliqNotificationSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CliqNotificationSettings>,
          CliqNotificationSettings,
          Stream<CliqNotificationSettings>
        >
    with
        $FutureModifier<CliqNotificationSettings>,
        $StreamProvider<CliqNotificationSettings> {
  /// Stream provider for watching notification settings
  const CliqNotificationSettingsProvider._({
    required CliqNotificationSettingsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cliqNotificationSettingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cliqNotificationSettingsHash();

  @override
  String toString() {
    return r'cliqNotificationSettingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<CliqNotificationSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CliqNotificationSettings> create(Ref ref) {
    final argument = this.argument as String;
    return cliqNotificationSettings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CliqNotificationSettingsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cliqNotificationSettingsHash() =>
    r'1cf0272b233e3233527e30e3e00a51e2b956e3e4';

/// Stream provider for watching notification settings

final class CliqNotificationSettingsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<CliqNotificationSettings>, String> {
  const CliqNotificationSettingsFamily._()
    : super(
        retry: null,
        name: r'cliqNotificationSettingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for watching notification settings

  CliqNotificationSettingsProvider call(String userId) =>
      CliqNotificationSettingsProvider._(argument: userId, from: this);

  @override
  String toString() => r'cliqNotificationSettingsProvider';
}
