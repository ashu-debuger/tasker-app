import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../extensions/plugin_registry.dart';

class PluginActionBar extends ConsumerWidget {
  const PluginActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Re-enable when quick capture feature is ready
    return const SizedBox.shrink();

    // ignore: dead_code
    final actions = ref.watch(pluginActionsProvider);
    final visibleActions = actions.where((action) {
      final predicate = action.isVisible;
      if (predicate == null) return true;
      return predicate(ref, context);
    }).toList();

    if (visibleActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final action in visibleActions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton.icon(
                onPressed: () async {
                  await action.onSelected(ref, context);
                },
                icon: Icon(action.icon ?? Icons.extension),
                label: Text(action.label),
              ),
            ),
        ],
      ),
    );
  }
}
