# Tasker (Flutter): Copilot Instructions

Purpose: Provide concise, repo-specific guidance for AI agents working on the Tasker Flutter App.

## Big Picture

- **App**: Single codebase Flutter app for Android and iOS.
- **State Management**: **Riverpod** (Code generation variant `riverpod_generator` + `riverpod_annotation`).
- **Backend**: Firebase (Auth, Firestore) + Local Storage (Hive).
- **Navigation**: **GoRouter**.

## Project Structure

- `lib/main.dart`: Entry point. Sets up `ProviderScope`, `Firebase`, `Hive`, and `NotificationService`.
- `lib/src/features/`: Feature-based architecture (e.g., `auth`, `tasks`, `projects`).
  - Each feature contains: `presentation/` (Widgets), `data/` (Repositories), `domain/` (Models), `application/` (Services/Notifiers).
- `lib/src/core/`: Shared utilities, routing, theme, and core services.
- `lib/src/extensions/`: Plugin system extensions.

## Key Patterns & Conventions

### 1. State Management (Riverpod)
- Use `@riverpod` annotations for providers.
- Prefer `ConsumerWidget` or `ConsumerStatefulWidget` to consume state.
- *Example*:
  ```dart
  @riverpod
  class TaskList extends _$TaskList { ... }
  ```

### 2. Navigation
- Use `GoRouter` defined in `lib/src/core/routing/app_router.dart`.
- Navigate using `context.go('/path')` or `context.push('/path')`.

### 3. Data Layer
- **Repositories**: Handle data fetching (Firestore/Hive).
- **Models**: Use `freezed` or `json_serializable` for immutable data classes.
- **Firestore**: Access via repositories, not directly in UI.

### 4. Theming
- Theme is defined in `main.dart` and supports Light/Dark modes.
- Use `Theme.of(context)` or `ref.watch(pluginThemeExtensionProvider)` for dynamic styling.

## Common Workflows

- **Run App**: `flutter run`
- **Code Generation**: Run this after changing models or providers:
  ```powershell
  dart run build_runner build --delete-conflicting-outputs
  ```
  *Tip*: Use `watch` for continuous generation during dev.
- **Analyze**: `flutter analyze`

## Critical Files

- `lib/main.dart`: App initialization.
- `lib/src/core/routing/app_router.dart`: Route definitions.
- `pubspec.yaml`: Dependencies (Riverpod, Firebase, GoRouter).

## Constraints

- **Private App**: `publish_to: 'none'`.
- **Platform**: Android & iOS. Avoid web-only libraries unless necessary.
- **Generated Files**: Do not edit `.g.dart` or `.freezed.dart` files manually.

