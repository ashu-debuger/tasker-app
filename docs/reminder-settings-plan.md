# Reminder Settings & Routine Visibility Plan

Purpose: Track the work required to unify reminders and improve routine visibility in Tasker.

## Goals

1. Provide a single place for users to configure default lead times for task and routine reminders.
2. Ensure Task and Routine helpers respect the global settings.
3. Improve visibility of routines (today view and calendar interactions).
4. Validate via analyzer/tests.

## Tasks

| ID   | Task                                                                            | Status   | Notes                                        |
| ---- | ------------------------------------------------------------------------------- | -------- | -------------------------------------------- |
| RS-1 | Add `ReminderSettings` model + Hive storage                                     | Complete | Model + Hive adapter/box registered          |
| RS-2 | Expose settings via Riverpod (`ReminderSettingsRepository`, notifier, provider) | Complete | Hive repo, notifier, providers wired         |
| RS-3 | Update `TaskReminderHelper` to use provider-supplied settings                   | Complete | Helper now reads lead minutes via DI         |
| RS-4 | Update `RoutineNotificationHelper` to share same configuration                  | Complete | Uses shared ReminderSettings fallback        |
| RS-5 | Build `ReminderSettingsScreen` under settings route                             | Complete | Screen + route + drawer entry added          |
| RS-6 | Add "Today's routines" emphasis in routines list + calendar tap nav             | Complete | Highlight card + calendar taps live          |
| RS-7 | Tests/analyzer pass & docs update (`task-board.md`, README snippet)             | Complete | Analyzer + `flutter test` green; docs synced |

## Notes

- Lead time options: 5, 10, 15, 30, 60 minutes (expandable later).
- Reminder settings should persist locally per device; future work could sync to Firestore if needed.
- Routine visibility improvements are lightweight (UI-only) but make routines feel first-class.
