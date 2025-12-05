# Reminder Time Display & Scheduled Reminders Feature

## Overview

Implemented two major enhancements to the reminder system:

1. **Real-time reminder time display** in task creation dialog
2. **Scheduled Reminders screen** accessible from navigation drawer

## Changes Made

### 1. Task Creation - Reminder Time Display

**File:** `lib/src/features/projects/presentation/screens/project_detail_screen.dart`

**What was added:**

- Real-time display of calculated reminder time below the "Enable Reminder" switch
- Uses user's reminder settings (default: 30 mins before due date)
- Shows format: "Reminder: MMM d, yyyy at h:mm a"
- Updates automatically when due date/time or reminder settings change
- Only visible when reminder is enabled AND due date is set

**Implementation:**

- Added `Consumer` widget to watch `reminderSettingsProvider`
- Calculates reminder time by subtracting lead minutes from due date/time
- Formats display using `intl` package date/time formatters
- Blue icon and text for clear visual indication

**Example Display:**

```
✓ Enable Reminder
  Uses global reminder lead time settings

🔔 Reminder: Nov 16, 2025 at 2:30 PM
```

### 2. Scheduled Reminders Screen

**New Files Created:**

#### Domain Model

`lib/src/features/reminders/domain/models/scheduled_reminder.dart`

- Model representing a scheduled reminder with task information
- Properties: id, taskId, projectId, taskTitle, scheduledDate, projectName, taskDueDate

#### Provider

`lib/src/features/reminders/presentation/providers/scheduled_reminders_provider.dart`

- Riverpod AsyncNotifier that fetches pending notifications
- Enriches notification data with task and project information
- Queries Firestore to get full task details
- Handles invalid/orphaned notifications gracefully
- Provides `refresh()` method to reload data

#### Screen

`lib/src/features/reminders/presentation/screens/scheduled_reminders_screen.dart`

- Full-featured screen listing all scheduled reminders
- Empty state when no reminders exist
- Card-based UI showing:
  - Task title
  - Project name (if available)
  - Due date and time
  - Actions menu (Edit Task / Cancel Reminder)
- Tap to open task detail screen
- Cancel reminder with confirmation dialog
- Refresh button in app bar
- Error handling with retry option

### 3. Navigation Integration

**File:** `lib/src/features/projects/presentation/screens/projects_list_screen.dart`

**What was added:**

- New drawer item: "Scheduled Reminders"
- Icon: `notification_add`
- Positioned above "Reminder Settings" in drawer
- Routes to `/reminders/scheduled`

**Drawer Structure:**

```
─ Projects
─ Sticky Notes
─ Routines
─ Calendar
─ Mind Maps
──────────────
─ Scheduled Reminders  ← NEW
─ Reminder Settings
─ Encryption Settings
```

### 4. Routing

**File:** `lib/src/core/routing/app_router.dart`

**What was added:**

- Route constant: `AppRoutes.scheduledReminders = '/reminders/scheduled'`
- Route definition pointing to `ScheduledRemindersScreen`

## User Experience Improvements

### For Task Creation:

1. User sets due date and time
2. If reminder is enabled, they see exactly when the reminder will fire
3. Can adjust due date/time and see reminder time update in real-time
4. Transparency helps users schedule tasks more effectively

### For Managing Reminders:

1. Access via drawer: Projects List → Scheduled Reminders
2. See all upcoming reminders in one place
3. Quick access to edit task (changes due date/reminder automatically)
4. Cancel individual reminders without deleting the task
5. Visual feedback for task due dates and project context

## Technical Details

### Reminder Time Calculation

```dart
// Get reminder settings (e.g., 30 minutes)
final leadMinutes = reminderSettings.taskLeadMinutes;

// Build full due DateTime
DateTime reminderDateTime = DateTime(
  dueDate.year, dueDate.month, dueDate.day,
  dueTime.hour, dueTime.minute,
);

// Subtract lead time
final reminderTime = reminderDateTime.subtract(Duration(minutes: leadMinutes));
```

### Notification Enrichment Flow

```
1. Fetch pending notifications from NotificationService
2. Parse payload: "task:projectId:taskId"
3. Query Firestore for task data
4. Query Firestore for project name
5. Build ScheduledReminder model
6. Display in list
```

### Error Handling

- Invalid notification payloads → skipped
- Deleted tasks → skipped
- Firestore errors → caught and displayed with retry option
- Empty state for zero reminders

## Testing Checklist

- [x] Code passes `flutter analyze` with zero issues
- [x] Build runner generated provider code successfully
- [ ] Create task with due date shows reminder time
- [ ] Changing due date updates reminder time display
- [ ] Changing reminder settings (30→15 mins) updates display
- [ ] Scheduled Reminders accessible from drawer
- [ ] List shows all pending reminders correctly
- [ ] Tap reminder opens task detail screen
- [ ] Edit task updates reminder automatically
- [ ] Cancel reminder removes it from list
- [ ] Empty state appears when no reminders exist
- [ ] Refresh button reloads data

## Files Modified

1. `lib/src/features/projects/presentation/screens/project_detail_screen.dart`
2. `lib/src/features/projects/presentation/screens/projects_list_screen.dart`
3. `lib/src/core/routing/app_router.dart`

## Files Created

1. `lib/src/features/reminders/domain/models/scheduled_reminder.dart`
2. `lib/src/features/reminders/presentation/providers/scheduled_reminders_provider.dart`
3. `lib/src/features/reminders/presentation/providers/scheduled_reminders_provider.g.dart` (generated)
4. `lib/src/features/reminders/presentation/screens/scheduled_reminders_screen.dart`

## Dependencies Used

- `flutter_riverpod` - State management
- `riverpod_annotation` - Code generation
- `intl` - Date/time formatting
- `go_router` - Navigation
- `flutter_local_notifications` - Pending notifications API
- `cloud_firestore` - Task/project data

## Future Enhancements

1. **Snooze Functionality**: Add snooze button in Scheduled Reminders
2. **Bulk Actions**: Select multiple reminders to cancel at once
3. **Filter/Sort**: Filter by project, sort by date
4. **Notification Details**: Show more info about notification (sound, vibration)
5. **Edit Reminder Time**: Allow changing reminder time without changing task due date
6. **Calendar View**: Show reminders on calendar
7. **Statistics**: Show reminder firing success rate
8. **Smart Suggestions**: Suggest optimal reminder times based on user patterns

## Known Limitations

1. **Scheduled Time**: `flutter_local_notifications` API doesn't expose exact scheduled time, only pending notification ID
2. **Real-time Updates**: List doesn't auto-refresh when reminders fire (requires manual refresh)
3. **Timezone**: Uses device local timezone only
4. **Platform**: Notification details may vary between Android/iOS

## Migration Notes

- No database schema changes
- No breaking changes to existing functionality
- Backward compatible with existing tasks and reminders
- New feature is purely additive
