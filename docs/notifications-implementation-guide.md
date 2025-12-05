# Task Notification System - Implementation Guide

## Overview

The Tasker app implements a comprehensive notification system for task reminders. This document explains how it works and what was fixed.

## Architecture

### Components

1. **NotificationService** (`lib/src/core/notifications/notification_service.dart`)

   - Core service managing all notification operations
   - Handles permission requests, scheduling, and cancellation
   - Uses `flutter_local_notifications` plugin with timezone support

2. **TaskReminderHelper** (`lib/src/features/tasks/domain/helpers/task_reminder_helper.dart`)

   - Domain-level helper that schedules/cancels task reminders
   - Calculates reminder times based on task due dates and lead time settings
   - Automatically triggered when tasks are created/updated/deleted

3. **NotificationPermissionScreen** (`lib/src/features/settings/presentation/screens/notification_permission_screen.dart`)

   - First-launch UI to request notification permissions
   - Shown once after user signs in for the first time
   - Explains benefits and allows skipping

4. **NotificationPermissionState** (`lib/src/core/providers/notification_permission_state.dart`)
   - Riverpod provider tracking whether user has been asked for permissions
   - Persists state in Hive local storage

## How Task Reminders Work

### 1. Task Creation Flow

When a user creates a task with a due date:

```
User creates task → Task saved to Firestore → TaskReminderHelper.scheduleTaskReminder()
→ NotificationService.scheduleNotification() → OS schedules notification
```

### 2. Reminder Calculation

The reminder time is calculated as:

```
Reminder Time = Task Due Date - Lead Time (from settings)
```

Default lead time: 15 minutes (configurable in Settings > Reminders)

### 3. Notification Scheduling

- Uses `zonedSchedule()` with `AndroidScheduleMode.exactAllowWhileIdle`
- Ensures notifications fire even when device is in Doze mode
- Properly handles timezone conversions using `timezone` package

### 4. Task Updates

When a task is updated:

- Old reminder is cancelled
- If task still has a due date and reminder enabled, new reminder is scheduled
- If task is completed or reminder disabled, no new reminder is scheduled

## Fixed Issues

### Issue 1: Timezone Not Initialized ✅

**Problem:** Notifications weren't firing because local timezone wasn't set
**Fix:** Added `_getLocalTimezoneName()` helper that detects device timezone and calls `tz.setLocalLocation()`

### Issue 2: Missing Permission Request Flow ✅

**Problem:** App never asked users for notification permissions
**Fix:**

- Created `NotificationPermissionScreen` shown on first launch
- Added `NotificationPermissionState` provider to track if user was asked
- Modified `SplashScreen` to redirect to permission screen for new users

### Issue 3: Permissions Not Requested Before Scheduling ✅

**Problem:** Trying to schedule notifications without first requesting runtime permissions
**Fix:** `scheduleNotification()` now calls `requestPermissions()` and checks exact alarm permission before scheduling

### Issue 4: Missing Past Date Validation ✅

**Problem:** App tried to schedule notifications for past dates
**Fix:** Added validation in `scheduleNotification()` to skip if trigger date is in the past

### Issue 5: Missing AndroidManifest Permissions ✅

**Problem:** Required Android permissions weren't declared
**Fix:** Already present in AndroidManifest.xml:

- `POST_NOTIFICATIONS` (Android 13+)
- `SCHEDULE_EXACT_ALARM` (Android 12+)
- `RECEIVE_BOOT_COMPLETED` (reschedule after reboot)

## Testing the Notification System

### Manual Test Steps

1. **First Launch Test**

   ```
   - Sign up/Sign in as new user
   - Should see "Stay on Track with Reminders" screen
   - Tap "Enable Notifications"
   - Grant permissions when prompted
   - Create a task with due date 2 minutes from now
   - Wait 2 minutes - notification should appear
   ```

2. **Permission Denied Test**

   ```
   - Clear app data
   - Sign in
   - Tap "Skip for now" on permission screen
   - Create task → Should see warning about permissions
   - Go to Settings > Reminders → Can request again
   ```

3. **Task Update Test**

   ```
   - Create task with due date in 5 minutes
   - Edit task to change due date to 10 minutes
   - Old notification should be cancelled
   - New notification should be scheduled for new time
   ```

4. **Task Completion Test**
   ```
   - Create task with due date
   - Mark task as completed
   - Notification should be cancelled
   ```

### Debugging Notifications

To see notification logs in console:

```dart
// Check pending notifications
final service = NotificationService();
final pending = await service.getPendingNotifications();
print('Pending notifications: ${pending.length}');
for (final p in pending) {
  print('ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
}
```

All notification operations are logged with the tag `[NotificationService]` and can be viewed in:

- Android Studio Logcat
- VS Code Debug Console
- Using `flutter logs` command

## Configuration

### Reminder Settings

Users can configure:

- **Task Lead Time**: How many minutes before due date to show reminder (default: 15)
- **Routine Reminder Time**: Time of day for daily routine reminders

Access via: Projects List → Settings Icon → Reminder Settings

### Android Exact Alarm Permission

For Android 12+ devices, exact alarms require special permission:

- App automatically requests this when scheduling first notification
- If denied, user sees error message with instructions
- Can be granted in: Settings > Apps > Tasker > Alarms & reminders

## Known Limitations

1. **iOS Background Notifications**: iOS may delay notifications if app is terminated
2. **Android Battery Optimization**: Some manufacturers aggressively kill background processes
3. **Timezone Changes**: If user changes timezone, existing notifications maintain original time
4. **Maximum Notifications**: Android limits ~500 pending notifications per app

## Future Enhancements

1. **Snooze Functionality**: Allow snoozing reminders for X minutes
2. **Multiple Reminders**: Support multiple reminders per task (e.g., 1 day before, 1 hour before)
3. **Sound/Vibration Customization**: Let users choose notification sound
4. **Notification Actions**: Add "Mark Complete" action button to notification
5. **Smart Scheduling**: ML-based optimal reminder times based on user behavior

## Troubleshooting

### Notifications Not Appearing

1. **Check Permissions**

   ```dart
   final service = NotificationService();
   final enabled = await service.areNotificationsEnabled();
   print('Notifications enabled: $enabled');
   ```

2. **Check Pending Notifications**

   ```dart
   final pending = await service.getPendingNotifications();
   print('Pending: ${pending.map((p) => p.id).toList()}');
   ```

3. **Verify Timezone**

   ```dart
   print('Local timezone: ${tz.local.name}');
   print('Current time: ${tz.TZDateTime.now(tz.local)}');
   ```

4. **Check Android Settings**
   - Settings > Apps > Tasker > Notifications → Should be ON
   - Settings > Apps > Tasker > Alarms & reminders → Should be ALLOWED

### Notifications Appearing at Wrong Time

1. Check device timezone matches app timezone
2. Verify lead time setting in app
3. Check logs for scheduled trigger time
4. Test with a notification 1-2 minutes in future

## API Reference

### NotificationService

```dart
// Initialize (call once in main.dart)
await NotificationService().initialize();

// Request permissions
final granted = await service.requestPermissions();

// Schedule notification
await service.scheduleNotification(
  id: 123,
  title: 'Task Reminder',
  body: 'Your task is due soon',
  scheduledDate: DateTime.now().add(Duration(minutes: 5)),
  payload: 'task:abc123',
);

// Cancel notification
await service.cancelNotification(123);

// Cancel all
await service.cancelAllNotifications();
```

### TaskReminderHelper

```dart
// Schedule task reminder (uses task due date & settings)
await helper.scheduleTaskReminder(task);

// Cancel task reminder
await helper.cancelTaskReminder(taskId);

// Reschedule (cancel + schedule if conditions met)
await helper.rescheduleTaskReminder(task);
```

## References

- [flutter_local_notifications plugin](https://pub.dev/packages/flutter_local_notifications)
- [Android Notification Documentation](https://developer.android.com/develop/ui/views/notifications)
- [iOS Local Notifications](https://developer.apple.com/documentation/usernotifications)
