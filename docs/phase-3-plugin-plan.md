# Phase 3 Plugin System Plan

## Goals

- Allow Tasker to load optional features (commands, shortcuts, themes) as "plugins".
- Provide a clean API surface so internal modules and future external packages can contribute.
- Ensure plugins integrate with existing Riverpod architecture and navigation.

## Architecture Overview

1. **Core Interfaces** (`lib/src/extensions/`)
   - `TaskerPlugin`: metadata (id, name, description, version, author) + lifecycle hooks (`onRegister`, optional `onDispose`).
   - `PluginAction`: describes command/shortcut entries (label, icon, callback).
   - `PluginThemeExtension`: optional theme overrides (colors, typography tweaks).
2. **Plugin Registry / Provider**
   - `PluginRegistry` holds a list of registered plugins.
   - Riverpod provider (`pluginRegistryProvider`) exposes the registry and streams plugin actions/themes to consumers.
3. **Built-in Plugin Examples**
   - `QuickTaskPlugin`: adds a shortcut action to create a task with pre-filled template.
   - `FocusModePlugin`: toggles a "focus" theme variant and exposes a command to enable focus mode.
4. **Integration Points**
   - Navigation drawer / FAB menu: surface `PluginAction`s as extra buttons.
   - Theme layer: merge `PluginThemeExtension`s into `ThemeData` via extension.
   - Future: command palette, automation hooks.

## File Additions

- `lib/src/extensions/tasker_plugin.dart` (interfaces).
- `lib/src/extensions/plugin_registry.dart` (registry + Riverpod provider).
- `lib/src/extensions/plugins/quick_task_plugin.dart` (sample plugin).
- Optional UI hook: `lib/src/features/home/widgets/plugin_action_bar.dart` to render plugin actions in UI.
- Docs update (`docs/phase-3-extensibility-and-ai.md`) and README snippet for plugin usage.

## Testing Strategy

- Unit tests for registry (register/unregister, action aggregation).
- Widget test for `PluginActionBar` ensuring actions render and callbacks fire.

## Open Questions / Next Steps

- External plugin loading (packages or remote config) can follow once internal architecture is stable.
- Permissions/security review when plugins can perform data mutations.
