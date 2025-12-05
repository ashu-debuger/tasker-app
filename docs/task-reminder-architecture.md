# Task & Reminder Architecture

**Last Updated:** November 16, 2025  
**Status:** Implementation in progress

## 1. Overview

Tasks and subtasks are core work items inside a project in Tasker. The system provides:

- **Tasks**: Work items with title, optional description, due dates with optional times, status tracking, and optional recurrence.
- **Subtasks**: Child work items that belong to a parent task, with optional due dates.
- **Reminders**: Local notifications scheduled for tasks (not subtasks) based on global lead time settings.

**Key Points:**

- Reminders are currently **only attached to tasks**, not subtasks.
- Persistence uses Firestore for tasks/subtasks/projects.
- Local notifications via `flutter_local_notifications` with timezone support.
- State management via Riverpod with code generation.

---

## 2. Data Models

### 2.1 `Task`

**Location:** `lib/src/features/tasks/domain/models/task.dart`

**Fields:**

- `id` (String): Unique task identifier
- `projectId` (String): Parent project
- `title` (String): Task name
- `description` (String?): Optional details
- `isDescriptionEncrypted` (bool): Whether description is encrypted
- `dueDate` (DateTime?): Optional due date with time
- `status` (TaskStatus): `pending`, `inProgress`, or `completed`
- `reminderEnabled` (bool): Whether to schedule notification (default: true)
- `assignees` (List<String>): User IDs assigned to this task
- `createdAt` (DateTime): Creation timestamp
- `updatedAt` (DateTime?): Last modification timestamp

**Recurrence Fields:**

- `recurrencePattern` (RecurrencePattern): `none`, `daily`, `weekly`, `monthly`, `yearly`
- `recurrenceInterval` (int): Repeat every N cycles (expected >= 1)
- `recurrenceEndDate` (DateTime?): Optional end date for recurrence
- `parentRecurringTaskId` (String?): ID of parent recurring task if this is an instance

**Computed Properties:**

- `isOverdue`: Returns `true` if `dueDate < DateTime.now()` and status is not completed
- `isRecurring`: Returns `true` if `recurrencePattern != RecurrencePattern.none`
- `isRecurringInstance`: Returns `true` if `parentRecurringTaskId != null`
- `getNextOccurrence()`: Computes next occurrence based on pattern/interval

**Persistence:**

- Firestore mapping via `fromFirestore` and `toFirestore` methods
- Supports JSON serialization

### 2.2 `Subtask`

**Location:** `lib/src/features/tasks/domain/models/subtask.dart`

**Fields:**

- `id` (String): Unique subtask identifier
- `taskId` (String): Parent task ID
- `title` (String): Subtask name
- `isCompleted` (bool): Completion status
- `createdAt` (DateTime): Creation timestamp
- `updatedAt` (DateTime?): Last modification timestamp
- `dueDate` (DateTime?): Optional due date with time (added recently)

**Behavior:**

- A subtask is overdue if `dueDate < DateTime.now()` and `isCompleted == false`
- Currently **no reminders** are scheduled for subtasks

**Persistence:**

- Firestore via `fromFirestore` / `toFirestore`

### 2.3 Reminder Settings

**Location:** `lib/src/features/settings/domain/models/reminder_settings.dart`

**Model: `ReminderSettings`**

- `taskLeadMinutes` (int): Global lead time for task reminders (e.g., 5, 10, 15, 30, 60)
- Static list of supported lead time options

**Repository & Notifier:**

- `ReminderSettingsRepository`: Persists and retrieves settings
- `ReminderSettingsNotifier`: Riverpod notifier exposing current settings and update methods
- `ReminderSettingsScreen`: UI for configuring lead times

---

## 3. Persistence and Repositories

### 3.1 `TaskRepository`

**Location:** `lib/src/features/tasks/domain/repositories/task_repository.dart`

**Responsibilities:**

**Streaming:**

- `streamTaskById(taskId)`: Stream a single task
- `streamTasksForProject(projectId)`: Stream all tasks in a project
- `streamTasksForUser(userId)`: Stream tasks assigned to user
- `streamRecurringTaskInstances(parentTaskId)`: Stream instances of recurring task
- `streamSubtasksForTask(taskId)`: Stream subtasks for a task

**CRUD Operations:**

- `createTask(Task task)`: Create new task
- `updateTask(Task task)`: Update existing task
- `deleteTask(taskId)`: Delete single task
- `deleteTasksForProject(projectId)`: Bulk delete all tasks in project

**Subtask Operations:**

- `createSubtask(Subtask subtask)`
- `updateSubtask(Subtask subtask)`
- `deleteSubtask(subtaskId)`
- `toggleSubtaskCompletion(taskId, subtaskId, isCompleted)`

### 3.2 `ProjectRepository`

**Responsibilities:**

- Get project by ID
- Create, update, delete projects
- Coordinated with `TaskRepository` via `ProjectDetailNotifier`

### 3.3 Firestore Schema

**Collections:**

- `projects/{projectId}`: Project documents
- `projects/{projectId}/tasks/{taskId}` or flat `tasks` collection with `projectId` field
- `tasks/{taskId}/subtasks/{subtaskId}`: Subtask subcollection

**Task Document Fields:**

- All fields from `Task` model including `dueDate`, `reminderEnabled`, recurrence fields

**Subtask Document Fields:**

- All fields from `Subtask` model including optional `dueDate`

---

## 4. Reminder and Notification Flow

### 4.1 `NotificationService`

**Location:** `lib/src/core/notifications/notification_service.dart`

**Purpose:** Wraps `FlutterLocalNotificationsPlugin` for cross-platform local notifications

**Key Methods:**

- `initialize()`: Set up notification channels and permissions
- `requestPermissions()`: Request notification permissions (including exact alarms on Android 12+)
- `scheduleNotification(id, title, body, scheduledDateTime)`: Schedule one-time notification
- `scheduleDailyNotification(...)`: Schedule recurring daily notification
- `cancelNotification(id)`: Cancel specific notification
- `cancelAllNotifications()`: Cancel all scheduled notifications

**Implementation Notes:**

- Uses `timezone` package for correct local time handling
- Uses `zonedSchedule` for precise scheduling
- Android: Requires exact alarm permission for API 31+

### 4.2 `TaskReminderHelper`

**Location:** `lib/src/features/tasks/application/task_reminder_helper.dart`

**Dependencies:**

- `NotificationService`: For scheduling/cancelling notifications
- `ReminderSettingsRepository`: For reading global lead time

**Notification ID Mapping:**

- Deterministic ID per task: `int.parse(task.id.hashCode.toString())` or similar

**Main Methods:**

#### `scheduleTaskReminder(Task task)`

Schedules a reminder notification for a task.

**Logic:**

1. If any of the following, cancel existing and return:
   - `task.reminderEnabled == false`
   - `task.dueDate == null`
   - `task.status == TaskStatus.completed`
2. Load `taskLeadMinutes` from `ReminderSettings`
3. Compute `scheduledDate = task.dueDate - Duration(minutes: taskLeadMinutes)`
4. If `scheduledDate.isAfter(DateTime.now())`:
   - Call `NotificationService.scheduleNotification(...)`
5. Otherwise:
   - **Currently:** Just return (no scheduling, no feedback)
   - **Known Issue:** User gets no reminder if lead time pushes schedule into past

#### `rescheduleTaskReminder(Task task)`

Convenience method: cancels then calls `scheduleTaskReminder(task)`

#### `cancelTaskReminder(String taskId)`

Cancels notification for given task ID

### 4.3 Reminder Settings Integration

**Flow:**

1. `ReminderSettingsNotifier` exposes `ReminderSettings` via Riverpod
2. `TaskReminderHelper` reads `taskLeadMinutes` from repository
3. Task create/update flows set only `reminderEnabled`; helper uses global lead time for scheduling
4. UI shows "Uses global reminder lead time settings" to clarify behavior

---

## 5. State Management and Providers

### 5.1 `ProjectDetailNotifier`

**Location:** `lib/src/features/projects/presentation/notifiers/project_detail_notifier.dart`

**Provider:**

- `projectDetailProvider(projectId)` → `AsyncValue<ProjectDetailState>`

**State:**

- `ProjectDetailState(Project? project, List<Task> tasks)`

**Build Logic:**

1. Load project once via `ProjectRepository.getProjectById(projectId)`
2. Stream tasks via `TaskRepository.streamTasksForProject(projectId)`
3. Combine into state

**Key Methods:**

#### `createTask(...)`

Creates a new task with all parameters including due date, recurrence, and reminder settings.

**Flow:**

1. Build `Task` object from parameters
2. Call `_taskRepository.createTask(task)`
3. Call `_reminderHelper.scheduleTaskReminder(task)`

#### `updateTask(Task task)`

Updates existing task and reschedules reminder.

**Flow:**

1. Call `_taskRepository.updateTask(task)`
2. Call `_reminderHelper.rescheduleTaskReminder(task)`

#### `deleteTask(taskId)`

Deletes task and cancels its reminder.

**Flow:**

1. Call `_taskRepository.deleteTask(taskId)`
2. Call `_reminderHelper.cancelTaskReminder(taskId)`

#### `deleteProject()`

Deletes entire project and all its tasks.

**Current Flow:**

1. Call `_taskRepository.deleteTasksForProject(_projectId)`
2. Call `_projectRepository.deleteProject(_projectId)`

**Known Issue:** Does not cancel reminders for tasks being deleted

### 5.2 `TaskDetailNotifier`

**Location:** `lib/src/features/tasks/presentation/notifiers/task_detail_notifier.dart`

**Provider:**

- `taskDetailProvider(taskId)` → `AsyncValue<TaskDetailState>`

**State:**

- `TaskDetailState(Task? task, List<Subtask> subtasks, String? error)`

**Build Logic:**

1. Stream task via `TaskRepository.streamTaskById(taskId)`
2. Stream subtasks via `TaskRepository.streamSubtasksForTask(taskId)`
3. Combine into state

**Key Methods:**

#### `updateTask(Task task)`

1. Call `_repository.updateTask(task)`
2. Call `_reminderHelper.rescheduleTaskReminder(task)`

#### `updateTaskStatus(TaskStatus status)`

1. Copy current task with new status
2. Update via repository
3. Reschedule reminder

#### `deleteTask()`

1. Call `_repository.deleteTask(_taskId)`
2. Call `_reminderHelper.cancelTaskReminder(_taskId)`

#### Subtask Methods

- `createSubtask(id, title, dueDate)`
- `updateSubtask(Subtask subtask)`
- `deleteSubtask(subtaskId)`
- `toggleSubtaskCompletion(subtaskId, isCompleted)`

**Note:** No reminder logic for subtasks

### 5.3 `TaskSubtaskSummary` Provider

**Location:** `lib/src/features/tasks/presentation/providers/task_progress_provider.dart`

**Provider:**

- `taskSubtaskSummaryProvider(taskId)` → Stream-based summary

**Computed Fields:**

- `total`: Total number of subtasks
- `completed`: Number of completed subtasks
- `remaining`: Number of incomplete subtasks
- `progress`: Completion percentage (0.0–1.0)
- `hasSubtasks`: Whether task has any subtasks
- `allComplete`: Whether all subtasks are complete

**Usage:**

- Used in `ProjectDetailScreen` to show subtask progress bars
- Drives auto-sync logic between subtask completion and task status

---

## 6. UI Flows

### 6.1 Task Creation – `ProjectDetailScreen`

**Location:** `lib/src/features/projects/presentation/screens/project_detail_screen.dart`

**Entry Point:**

- Floating action button → `_showCreateTaskDialog()`

**Dialog State Fields:**

- `_taskTitleController` / `_taskDescriptionController`
- `_encryptDescription` (bool)
- `_selectedDueDate` (DateTime?)
- `_selectedDueTime` (TimeOfDay?)
- `_recurrencePattern` (RecurrencePattern)
- `_recurrenceInterval` (int)
- `_recurrenceEndDate` (DateTime?)
- `_reminderEnabled` (bool, default: true)

**Due Date/Time Controls:**

**Date Picker:**

- `showDatePicker` with:
  - `firstDate: DateTime.now()`
  - `lastDate: DateTime.now() + 365 days`
- On select: Store date-only `DateTime(year, month, day)`, clear time
- Clear button: Removes both date and time

**Time Picker:**

- `showTimePicker`, enabled only when date is selected
- Clear button: Clears time, keeps date

**Date/Time Combination:**

```dart
_combineDateAndTime(date, time):
  if date == null: return null
  if time == null: return DateTime(date.year, date.month, date.day, 23, 59, 59)
  return DateTime(date.year, date.month, date.day, time.hour, time.minute)
```

**Recurrence Controls:**

- Dropdown for `RecurrencePattern` (none, daily, weekly, monthly, yearly)
- When changed to `none`: Reset interval to 1, clear end date
- If not `none`:
  - "Repeat every" numeric field (must be positive integer)
  - "Repeat until" date picker (optional)

**Reminder Toggle:**

- `SwitchListTile` "Enable Reminder"
- Subtitle: "Uses global reminder lead time settings"

**Validation on Submit:**

1. Validate title (non-empty, >= 2 chars)
2. Combine due date/time
3. Validate: `if (dueDateTime != null && !dueDateTime.isAfter(DateTime.now()))`
   - Show snackbar "Due date must be in the future."
   - Block creation
4. Call `projectDetailNotifier.createTask(...)` with all parameters

### 6.2 Task Editing – `TaskDetailScreen`

**Location:** `lib/src/features/tasks/presentation/screens/task_detail_screen.dart`

**Entry Point:**

- App bar edit icon → `_showEditTaskDialog(task)`

**Dialog Behavior:**

- Similar to create dialog, pre-populated from existing `task`
- Due date/time split from `task.dueDate`
- Same `_combineDateAndTime` logic (end of day when time omitted)

**Recurrence Normalization:**

- If pattern changed to `none`:
  - Set interval to 1, clear end date in UI
- On save:
  - Additional normalization: If pattern is `none`, force `recurrenceInterval = 1`, `recurrenceEndDate = null`

**Validation on Save:**

1. After combining date/time, validate:
   - `if (updatedDueDate != null && !updatedDueDate.isAfter(DateTime.now()))`
   - Show snackbar, block save
2. Build `updatedTask` with `copyWith`
3. Call `taskDetailNotifier.updateTask(updatedTask)`

### 6.3 Task Status and Subtasks – Project View

**Location:** `ProjectDetailScreen`

**Auto-Sync Logic:**

- `_syncTaskStatusWithSubtasks(task, summary)`:
  - If no subtasks: no-op
  - If all subtasks complete and task not completed:
    - Auto-update task status to `completed`
  - If not all complete and task is completed:
    - Auto-downgrade to `pending` or `inProgress` based on completed count
  - Uses `_autoSyncingTasks` set to prevent loops

**Checkbox Handling:**

- `_handleTaskCompletionToggle(task, summary, isChecked)`:
  - If checking (marking complete):
    - If has incomplete subtasks:
      - Show `_confirmIncompleteSubtasks(remaining)` dialog
      - If user cancels, abort
    - Set status to `completed`
  - If unchecking:
    - Set to `inProgress` if some subtasks complete, else `pending`
  - Updates via `projectDetailNotifier.updateTask(...)`

### 6.4 Task Status – Task Detail View

**App Bar Status Menu:**

- User can select `pending`, `inProgress`, or `completed`
- Calls `_updateTaskStatus(status)` → `TaskDetailNotifier.updateTaskStatus(status)`
- **Known Issue:** No confirm dialog for incomplete subtasks (inconsistent with project view)

### 6.5 Subtask Creation – `TaskDetailScreen`

**Entry Point:**

- "Add" button in subtask list → `_showCreateSubtaskDialog()`

**Dialog State:**

- Title controller
- `selectedDate` (DateTime?)
- `selectedTime` (TimeOfDay?)

**Due Date/Time:**

- Date picker: `firstDate: DateTime.now()`
- Time picker: Similar to task creation
- Combination: Same `_combineDateAndTime` logic

**Validation:**

- Title validated (non-empty)
- **Known Issue:** No validation that combined due date/time is in future

**On Save:**

- `dueDate = _combineDateAndTime(selectedDate, selectedTime)`
- Call `taskDetailNotifier.createSubtask(id, title, dueDate)`

**Subtask Display:**

- Shows due date with "Due ..."
- Overdue style if `dueDate < now` and not completed
- Checkbox toggles completion
- Delete button removes subtask

---

## 7. Validation Rules and Current Gaps

### 7.1 Implemented Rules

**Task Creation/Edit:**

- Title: Non-empty, >= 2 characters
- Due date/time: Must be strictly in future (`!dueDateTime.isAfter(DateTime.now())` is invalid)
- Default time: End-of-day (23:59:59) when time omitted
- Recurrence interval: UI enforces positive integer
- Edit recurrence: Pattern `none` forces interval=1, endDate=null

**Subtask Creation:**

- Title validated
- Date picker disallows past dates

### 7.2 Known Issues and Gaps

#### **Issue 1: Subtasks lack future-date validation** ⚠️ CRITICAL

- **Location:** `TaskDetailScreen._showCreateSubtaskDialog`, `_createSubtask`
- **Problem:** User can pick today with a past time → immediately overdue subtask
- **Fix:** Add validation after `_combineDateAndTime`: reject if not in future

#### **Issue 2: Recurrence end date vs due date** ⚠️ HIGH

- **Location:** Task create/edit in both screens
- **Problem:** No validation that `recurrenceEndDate >= dueDate`; invalid combos break recurrence
- **Fix:** On save, when `recurrencePattern != none` and both dates exist, enforce `recurrenceEndDate >= dueDate.date`

#### **Issue 3: Project deletion doesn't cancel reminders** ⚠️ HIGH

- **Location:** `ProjectDetailNotifier.deleteProject`
- **Problem:** Scheduled notifications remain after project/tasks deleted
- **Fix:** Stream tasks before deletion, call `_reminderHelper.cancelTaskReminder` for each

#### **Issue 4: Reminder lead time can push schedule into past** ⚠️ MEDIUM

- **Location:** `TaskReminderHelper.scheduleTaskReminder`
- **Problem:** If `dueDate - leadTime < now`, no reminder scheduled; user gets no notification
- **Fix:** Clamp schedule to `now + 1 minute` instead of silently dropping

#### **Issue 5: Recurrence interval not enforced at model level** 📝 MEDIUM

- **Location:** `Task.fromFirestore`
- **Problem:** Invalid data (e.g., 0) from Firestore breaks assumptions
- **Fix:** Clamp `recurrenceInterval` to `>= 1` in `fromFirestore`

#### **Issue 6: Create vs edit recurrence normalization asymmetry** 📝 LOW

- **Location:** `ProjectDetailScreen._createTask` vs edit dialog
- **Problem:** Edit normalizes fields; create relies on UI state
- **Fix:** Add explicit normalization in `_createTask` for consistency

#### **Issue 7: Task vs subtask reminder expectations** 📝 UX

- **Location:** Task dialogs vs subtask dialogs
- **Problem:** Users may expect subtask reminders; no UI indication they don't exist
- **Fix:** Add hint text or implement subtask reminders

#### **Issue 8: Project vs task-detail status inconsistency** 📝 UX

- **Location:** `ProjectDetailScreen` vs `TaskDetailScreen` status handling
- **Problem:** Project view confirms before completing task with incomplete subtasks; task detail doesn't
- **Fix:** Add confirm dialog in task detail view for consistency

#### **Issue 9: Duplicated date/time helpers** 📝 TECH DEBT

- **Location:** Multiple screens implement `_combineDateAndTime`, `_formatDueDateTime`
- **Problem:** Duplicated logic; changes must be made in multiple places
- **Fix:** Extract to `lib/src/shared/date_time_utils.dart`

#### **Issue 10: Updated timestamps not clearly managed** 📝 TECH DEBT

- **Location:** Various notifier update methods
- **Problem:** Unclear whether `updatedAt` is set consistently
- **Fix:** Clarify responsibility (repository vs notifier) and enforce

#### **Issue 11: Reminder defaults ignore global preference** 📝 ENHANCEMENT

- **Location:** Task creation dialogs
- **Problem:** All tasks default to `reminderEnabled=true`; no global preference
- **Fix:** Optionally add "defaultTaskReminderEnabled" to `ReminderSettings`

---

## 8. Recurring Tasks

### 8.1 Model Design

**Fields:**

- `recurrencePattern`: Defines cycle type (daily, weekly, monthly, yearly)
- `recurrenceInterval`: Repeat every N cycles (e.g., every 2 weeks)
- `recurrenceEndDate`: Optional cutoff date
- `parentRecurringTaskId`: Links instances to parent

### 8.2 Next Occurrence Calculation

**Method:** `Task.getNextOccurrence()`

**Logic:**

- Based on `recurrencePattern` and `recurrenceInterval`
- Adds interval to current due date:
  - Daily: Add days
  - Weekly: Add weeks
  - Monthly: Add months (same day-of-month)
  - Yearly: Add years
- Returns `null` if beyond `recurrenceEndDate`

### 8.3 Reminder Integration

**Current State:**

- `TaskReminderHelper` works on individual tasks
- Recurring instance generation service must call `scheduleTaskReminder` for each new instance
- **Gap:** No explicit documentation/tests for recurring instance reminders

### 8.4 Known Gaps

- No validation tying `recurrenceEndDate` to initial `dueDate`
- No dedicated recurring task service implementation documented
- Unclear how reminders behave across recurring instances in practice

---

## 9. Future Improvements & Design Decisions

### 9.1 Planned Improvements

**High Priority:**

1. **Shared date/time utilities**: Extract to `lib/src/shared/date_time_utils.dart`
2. **Consistent validation helpers**: Centralize "must be in future" logic
3. **Reminder cleanup on bulk operations**: Ensure notifications cancelled on project/task deletion
4. **Subtask future-date validation**: Match task-level validation strictness

**Medium Priority:** 5. **Reminder scheduling fallback**: Clamp to near-future instead of dropping when lead time causes past schedule 6. **Recurrence validation**: Enforce `recurrenceEndDate >= dueDate` 7. **Status change consistency**: Confirm dialog in task detail view for incomplete subtasks 8. **Model-level guards**: Clamp `recurrenceInterval` in `fromFirestore`

**Low Priority / Enhancements:** 9. **Subtask reminders**: Decide whether to implement; if yes, design fields and UI 10. **Global reminder defaults**: Allow users to set default `reminderEnabled` state 11. **Per-project settings**: Consider project-level defaults for reminders/recurrence 12. **Recurring instance service**: Document/test how recurring tasks generate instances and schedule reminders

### 9.2 Design Trade-offs

**Why tasks but not subtasks have reminders:**

- Simplifies notification management
- Subtasks are typically short-term, granular work items
- Could be reconsidered if user feedback shows strong need

**Why strict future-date validation:**

- Prevents confusion from immediately overdue tasks
- Encourages users to plan ahead
- Could be relaxed to allow "current moment" if needed

**Why global lead time vs per-task:**

- Reduces cognitive load on users
- Simpler UI and fewer decisions per task
- Could add per-task override if users request more control

### 9.3 Open Questions

1. Should subtasks support reminders? If yes, with what UI/UX?
2. Should recurrence end date be required or optional?
3. Should we allow tasks/subtasks due "right now" or require strictly future?
4. Should recurring task instances inherit reminder settings from parent?
5. How should we handle timezone changes for scheduled reminders?
6. Should we add "smart" lead times based on task priority/complexity?

---

## 10. Testing Strategy

### 10.1 Unit Tests

**Models:**

- `Task.isOverdue` with various date/status combinations
- `Task.getNextOccurrence()` for all recurrence patterns
- `_combineDateAndTime` helper (once extracted)
- `_formatDueDateTime` helper

**Business Logic:**

- `TaskReminderHelper.scheduleTaskReminder` with various edge cases
- Recurrence end date validation
- Subtask future-date validation

### 10.2 Widget Tests

**Screens:**

- Task creation dialog: all fields, validation, submission
- Task edit dialog: pre-population, recurrence normalization
- Subtask creation dialog: date/time handling
- Task status changes with/without subtasks

### 10.3 Integration Tests

**Flows:**

- Create task → verify reminder scheduled
- Update task due date → verify reminder rescheduled
- Complete task → verify reminder cancelled
- Delete project → verify all task reminders cancelled
- Create recurring task → verify instances generated with reminders

### 10.4 Manual Testing Checklist

- [ ] Create task with due date in past (should reject)
- [ ] Create task with due date = now (should reject per current rules)
- [ ] Create task with recurrence end date before due date (should reject after fix)
- [ ] Create subtask with past time (should reject after fix)
- [ ] Delete project, verify no orphaned notifications
- [ ] Set short lead time with nearby due date (should schedule or clamp after fix)
- [ ] Complete task with incomplete subtasks from both views (should confirm after fix)
- [ ] Toggle reminder on/off, verify notification scheduled/cancelled
- [ ] Change recurrence pattern, verify next occurrence calculated correctly

---

## 11. Migration Notes

### 11.1 Breaking Changes

**None currently planned**, but potential future changes:

- If subtask reminders added: New fields in `Subtask` model
- If global reminder default added: New field in `ReminderSettings`
- If per-task lead time added: New field in `Task` model

### 11.2 Data Migration Scenarios

**Existing tasks with invalid recurrence:**

- Run one-time migration to clamp `recurrenceInterval` to >= 1
- Clear `recurrenceEndDate` if pattern is `none`

**Existing projects being deleted:**

- No historical data to fix, but ensure future deletions clean up

---

## 12. Related Documentation

- [Phase 1 Core Functionality](./phase-1-core-functionality.md): Original planning doc
- [Task Board](./task-board.md): Active tasks and priorities
- [Overview](./overview.md): High-level roadmap

---

## 13. Revision History

| Date       | Author         | Changes                                                       |
| ---------- | -------------- | ------------------------------------------------------------- |
| 2025-11-16 | GitHub Copilot | Initial architecture documentation based on codebase analysis |

---

## 14. Quick Reference

### Key Files

**Models:**

- `lib/src/features/tasks/domain/models/task.dart`
- `lib/src/features/tasks/domain/models/subtask.dart`
- `lib/src/features/settings/domain/models/reminder_settings.dart`

**Repositories:**

- `lib/src/features/tasks/domain/repositories/task_repository.dart`

**Business Logic:**

- `lib/src/features/tasks/application/task_reminder_helper.dart`
- `lib/src/core/notifications/notification_service.dart`

**State Management:**

- `lib/src/features/projects/presentation/notifiers/project_detail_notifier.dart`
- `lib/src/features/tasks/presentation/notifiers/task_detail_notifier.dart`
- `lib/src/features/tasks/presentation/providers/task_progress_provider.dart`

**UI:**

- `lib/src/features/projects/presentation/screens/project_detail_screen.dart`
- `lib/src/features/tasks/presentation/screens/task_detail_screen.dart`

### Common Code Patterns

**Scheduling a reminder:**

```dart
await _reminderHelper.scheduleTaskReminder(task);
```

**Rescheduling after update:**

```dart
await _taskRepository.updateTask(task);
await _reminderHelper.rescheduleTaskReminder(task);
```

**Cancelling on delete:**

```dart
await _taskRepository.deleteTask(taskId);
await _reminderHelper.cancelTaskReminder(taskId);
```

**Combining date and time:**

```dart
DateTime? _combineDateAndTime(DateTime? date, TimeOfDay? time) {
  if (date == null) return null;
  if (time == null) return DateTime(date.year, date.month, date.day, 23, 59, 59);
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
```
