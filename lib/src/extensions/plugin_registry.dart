import 'dart:collection';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'tasker_plugin.dart';
import 'plugins/quick_task_plugin.dart';

part 'plugin_registry.g.dart';

typedef PluginFactory = TaskerPlugin Function();

@riverpod
List<PluginFactory> pluginBootstrapper(Ref ref) {
  // TODO: Re-enable QuickTaskPlugin when feature is ready
  return [QuickTaskPlugin.new];
}

@Riverpod(keepAlive: true)
class PluginRegistry extends _$PluginRegistry {
  final Map<String, TaskerPlugin> _plugins = {};
  bool _bootstrapped = false;

  @override
  UnmodifiableListView<TaskerPlugin> build() {
    _bootstrapBuiltIns();
    ref.onDispose(_disposeAll);
    return UnmodifiableListView(_plugins.values);
  }

  void register(TaskerPlugin plugin) {
    _registerInternal(plugin);
  }

  void unregister(String pluginId) {
    final plugin = _plugins.remove(pluginId);
    if (plugin == null) {
      throw ArgumentError('Plugin $pluginId not found');
    }
    plugin.onDispose();
    state = UnmodifiableListView(_plugins.values);
  }

  List<PluginAction> get actions => [
    for (final plugin in state) ...plugin.actions,
  ];

  PluginThemeExtension? get mergedThemeExtension {
    PluginThemeExtension? merged;
    for (final plugin in state) {
      final ext = plugin.themeExtension;
      if (ext == null) continue;
      merged = merged?.lerp(ext, 0.5) ?? ext;
    }
    return merged;
  }

  void _bootstrapBuiltIns() {
    if (_bootstrapped) return;
    final factories = ref.read(pluginBootstrapperProvider);
    for (final factory in factories) {
      _registerInternal(factory(), allowReplace: true);
    }
    _bootstrapped = true;
  }

  void _registerInternal(TaskerPlugin plugin, {bool allowReplace = false}) {
    final id = plugin.metadata.id;
    final existing = _plugins[id];
    if (existing != null && !allowReplace) {
      throw ArgumentError('Plugin $id is already registered');
    }

    existing?.onDispose();
    plugin.onRegister(PluginContext(ref: ref));
    _plugins[id] = plugin;
    state = UnmodifiableListView(_plugins.values);
  }

  void _disposeAll() {
    for (final plugin in _plugins.values) {
      plugin.onDispose();
    }
    _plugins.clear();
  }
}

@riverpod
List<PluginAction> pluginActions(Ref ref) {
  final plugins = ref.watch(pluginRegistryProvider);
  return [for (final plugin in plugins) ...plugin.actions];
}

@riverpod
PluginThemeExtension? pluginThemeExtension(Ref ref) {
  final plugins = ref.watch(pluginRegistryProvider);
  PluginThemeExtension? merged;
  for (final plugin in plugins) {
    final ext = plugin.themeExtension;
    if (ext == null) continue;
    merged = merged?.lerp(ext, 0.5) ?? ext;
  }
  return merged;
}
