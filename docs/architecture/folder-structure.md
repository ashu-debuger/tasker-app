# 📂 Folder Structure

Complete guide to the Tasker codebase organization.

---

## Root Structure

```
tasker/
├── android/                    # Android-specific code
├── ios/                        # iOS-specific code
├── lib/                        # Main Dart source code
├── test/                       # Unit and widget tests
├── integration_test/           # Integration tests
├── docs/                       # Documentation
├── pubspec.yaml                # Dependencies
├── firebase.json               # Firebase configuration
├── firestore.rules             # Firestore security rules
├── firestore.indexes.json      # Firestore indexes
└── .env                        # Environment variables (not in git)
```

---

## Lib Structure

```
lib/
├── main.dart                   # App entry point
└── src/
    ├── core/                   # Shared utilities and services
    │   ├── config/             # Configuration (EnvConfig)
    │   ├── routing/            # GoRouter setup
    │   ├── services/           # Core services
    │   ├── theme/              # App theming
    │   ├── utils/              # Utility functions
    │   └── widgets/            # Shared widgets
    │
    ├── features/               # Feature modules
    │   ├── auth/               # Authentication
    │   ├── tasks/              # Task management
    │   ├── projects/           # Project management
    │   ├── diary/              # Personal diary
    │   ├── chat/               # Real-time messaging
    │   ├── calendar/           # Calendar view
    │   ├── mind_maps/          # Mind mapping
    │   ├── sticky_notes/       # Sticky notes
    │   ├── routines/           # Daily routines
    │   ├── reminders/          # Reminder system
    │   ├── notifications/      # Push notifications
    │   └── settings/           # App settings
    │
    └── extensions/             # Plugin system
```

---

## Feature Module Structure

Each feature follows a consistent structure:

```
features/
└── {feature_name}/
    ├── presentation/           # UI layer
    │   ├── screens/            # Full screens
    │   ├── widgets/            # Feature-specific widgets
    │   └── dialogs/            # Dialogs and modals
    │
    ├── application/            # Business logic
    │   ├── {feature}_notifier.dart    # State notifier
    │   └── {feature}_provider.dart    # Riverpod providers
    │
    ├── data/                   # Data layer
    │   ├── repositories/       # Data access
    │   └── adapters/           # Hive type adapters
    │
    └── domain/                 # Domain layer
        └── models/             # Data models
```

### Example: Tasks Feature

```
features/tasks/
├── presentation/
│   ├── screens/
│   │   ├── task_list_screen.dart
│   │   ├── task_detail_screen.dart
│   │   └── task_edit_screen.dart
│   └── widgets/
│       ├── task_card.dart
│       ├── task_form.dart
│       └── subtask_list.dart
│
├── application/
│   ├── task_notifier.dart
│   ├── task_notifier.g.dart      # Generated
│   └── task_providers.dart
│
├── data/
│   ├── repositories/
│   │   └── task_repository.dart
│   └── adapters/
│       └── task_adapter.dart
│
└── domain/
    └── models/
        ├── task.dart
        ├── task.freezed.dart     # Generated
        └── task.g.dart           # Generated
```

---

## Core Module

```
core/
├── config/
│   └── env_config.dart         # Environment variable access
│
├── routing/
│   └── app_router.dart         # GoRouter configuration
│
├── services/
│   ├── notification_service.dart
│   ├── encryption_service.dart
│   └── hive_service.dart
│
├── theme/
│   ├── app_theme.dart
│   └── color_schemes.dart
│
├── utils/
│   ├── date_utils.dart
│   ├── string_utils.dart
│   └── validators.dart
│
└── widgets/
    ├── loading_indicator.dart
    ├── error_widget.dart
    └── empty_state.dart
```

---

## Generated Files

Files ending with these suffixes are auto-generated:

| Suffix          | Generator      | Purpose                      |
| --------------- | -------------- | ---------------------------- |
| `.g.dart`       | `build_runner` | JSON serialization, Riverpod |
| `.freezed.dart` | `freezed`      | Immutable data classes       |

> ⚠️ **Never edit generated files manually!**

Regenerate with:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Key Files

| File                                   | Purpose                   |
| -------------------------------------- | ------------------------- |
| `lib/main.dart`                        | App entry, initialization |
| `lib/src/core/routing/app_router.dart` | Route definitions         |
| `lib/src/core/config/env_config.dart`  | Environment configuration |
| `pubspec.yaml`                         | Dependencies              |
| `firestore.rules`                      | Database security rules   |

---

## Naming Conventions

| Type      | Convention           | Example                |
| --------- | -------------------- | ---------------------- |
| Files     | snake_case           | `task_repository.dart` |
| Classes   | PascalCase           | `TaskRepository`       |
| Variables | camelCase            | `taskList`             |
| Constants | camelCase            | `defaultPriority`      |
| Providers | camelCase + Provider | `taskListProvider`     |
| Notifiers | PascalCase           | `TaskListNotifier`     |

---

## Related Docs

- [Overview](./overview.md) - Architecture overview
- [State Management](./state-management.md) - Riverpod patterns
- [Data Layer](./data-layer.md) - Repositories and models

---

<div align="center">

**[← Back to Docs](../README.md)** | **[State Management →](./state-management.md)**

</div>
