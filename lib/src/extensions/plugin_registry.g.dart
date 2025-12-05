// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_registry.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pluginBootstrapper)
const pluginBootstrapperProvider = PluginBootstrapperProvider._();

final class PluginBootstrapperProvider
    extends
        $FunctionalProvider<
          List<PluginFactory>,
          List<PluginFactory>,
          List<PluginFactory>
        >
    with $Provider<List<PluginFactory>> {
  const PluginBootstrapperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginBootstrapperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginBootstrapperHash();

  @$internal
  @override
  $ProviderElement<List<PluginFactory>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<PluginFactory> create(Ref ref) {
    return pluginBootstrapper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PluginFactory> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PluginFactory>>(value),
    );
  }
}

String _$pluginBootstrapperHash() =>
    r'3426fd572dad89c599df33e3b589ee4b6a988715';

@ProviderFor(PluginRegistry)
const pluginRegistryProvider = PluginRegistryProvider._();

final class PluginRegistryProvider
    extends
        $NotifierProvider<PluginRegistry, UnmodifiableListView<TaskerPlugin>> {
  const PluginRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginRegistryHash();

  @$internal
  @override
  PluginRegistry create() => PluginRegistry();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnmodifiableListView<TaskerPlugin> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnmodifiableListView<TaskerPlugin>>(
        value,
      ),
    );
  }
}

String _$pluginRegistryHash() => r'44d7270705957c3063cfc06095132473a749b990';

abstract class _$PluginRegistry
    extends $Notifier<UnmodifiableListView<TaskerPlugin>> {
  UnmodifiableListView<TaskerPlugin> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              UnmodifiableListView<TaskerPlugin>,
              UnmodifiableListView<TaskerPlugin>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                UnmodifiableListView<TaskerPlugin>,
                UnmodifiableListView<TaskerPlugin>
              >,
              UnmodifiableListView<TaskerPlugin>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(pluginActions)
const pluginActionsProvider = PluginActionsProvider._();

final class PluginActionsProvider
    extends
        $FunctionalProvider<
          List<PluginAction>,
          List<PluginAction>,
          List<PluginAction>
        >
    with $Provider<List<PluginAction>> {
  const PluginActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginActionsHash();

  @$internal
  @override
  $ProviderElement<List<PluginAction>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<PluginAction> create(Ref ref) {
    return pluginActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PluginAction> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PluginAction>>(value),
    );
  }
}

String _$pluginActionsHash() => r'778a22b35f62240a6e08016ad4ed3bf88b3973bf';

@ProviderFor(pluginThemeExtension)
const pluginThemeExtensionProvider = PluginThemeExtensionProvider._();

final class PluginThemeExtensionProvider
    extends
        $FunctionalProvider<
          PluginThemeExtension?,
          PluginThemeExtension?,
          PluginThemeExtension?
        >
    with $Provider<PluginThemeExtension?> {
  const PluginThemeExtensionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginThemeExtensionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginThemeExtensionHash();

  @$internal
  @override
  $ProviderElement<PluginThemeExtension?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PluginThemeExtension? create(Ref ref) {
    return pluginThemeExtension(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PluginThemeExtension? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PluginThemeExtension?>(value),
    );
  }
}

String _$pluginThemeExtensionHash() =>
    r'0c7a551d3062998b9140bce38a7b5713270f3e30';
