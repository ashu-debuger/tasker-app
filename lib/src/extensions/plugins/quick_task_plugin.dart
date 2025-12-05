import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tasker_plugin.dart';

/// A simple built-in plugin that demonstrates the quick capture action.
class QuickTaskPlugin extends TaskerPlugin {
  QuickTaskPlugin();

  static const _metadata = TaskerPluginMetadata(
    id: 'tasker.quick_task',
    name: 'Quick Task Capture',
    description: 'Adds a shortcut for capturing lightweight tasks.',
    version: '1.0.0',
    author: 'Tasker Team',
  );

  @override
  TaskerPluginMetadata get metadata => _metadata;

  @override
  List<PluginAction> get actions => [
    PluginAction(
      id: 'tasker.quick_task.capture',
      label: 'Quick capture task',
      description: 'Open a lightweight dialog to capture a task idea.',
      icon: Icons.flash_on,
      onSelected: _showComingSoon,
    ),
  ];

  @override
  PluginThemeExtension? get themeExtension => const PluginThemeExtension(
    accentColor: Colors.deepOrangeAccent,
    cardRadius: 20,
  );

  Future<void> _showComingSoon(WidgetRef ref, BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick task capture coming soon!')),
    );
  }
}
