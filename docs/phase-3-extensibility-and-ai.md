# Phase 3: Extensibility and AI

This phase focuses on extending the app's capabilities with plugins and integrating artificial intelligence.

## 1. Plugin System (Complete)

- **Runtime plugin registry**: `lib/src/extensions/plugin_registry.dart` exposes a registry provider and plugin interface that allows feature bundles (actions, themes, quick actions) to register themselves at startup.
- **UI integration**: `PluginActionBar` renders plugin-defined quick widgets in the projects dashboard, and plugin themes can extend the base Material theme via `pluginThemeExtensionProvider`.
- **Authoring guidelines**: New plugins should live under `lib/src/plugins/<plugin_name>/` and implement `TaskerPlugin` with optional theme + action definitions.

## 2. AI Task Suggestions (Heuristic Prototype)

- `TaskSuggestionController` (Riverpod) now powers offline heuristics based on recent project activity. The UI entry point lives on the Project Detail screen (magic-wand icon) and opens a sheet that can pre-fill the task composer.
- The current implementation uses `HeuristicTaskSuggestionRepository`, which emits deterministic suggestions without calling an LLM. Swap this repository for a Gemini-backed client once credentials and networking are ready, keeping the provider interface stable.
- Feature flags are still recommended before rolling out real AI responses; wire them up alongside the future remote repository.

## 3. Platform-Specific Features (Complete)

### Quick Actions

- **Service**: `QuickActionService` initializes the `quick_actions` shortcuts (`Quick Task`, `Sticky Notes`, `Mind Maps`) on supported platforms.
- **State flow**: `quickActionServiceProvider` pushes selections into `QuickActionSelection`, while `QuickActionNavigator` listens and routes users to the relevant screens with auth checks.
- **Usage**: Long-press the Tasker launcher icon and choose one of the shortcuts. The app navigates immediately (or prompts sign-in if needed) and displays contextual guidance via SnackBars.

### Android Quick Settings Tiles

- **Tile services**: `QuickTaskTileService` and `QuickNoteTileService` (Android/Kotlin) expose two QS tiles. Android 14+ devices launch via `PendingIntent` to comply with `TileService.startActivityAndCollapse` restrictions.
- **Flutter bridge**: `TileActionService` listens to the `in.devmantra.tasker/tiles` MethodChannel, normalizes intents into the same `QuickActionSelection` flow, and clears consumed actions.
- **Setup**: Pin the desired tiles from the Android Quick Settings editor. Tapping a tile routes to the Tasker dashboard (Quick Task) or opens a blank sticky note editor (Quick Note). Authentication is required for note creation.

---

**Remaining Work**

- Replace the heuristic repository with a true AI-backed implementation and add telemetry/feedback loops.
- Expand plugin samples (e.g., integrations, automation) as new requirements arise.
