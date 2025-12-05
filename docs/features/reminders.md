# ⏰ Reminders

Task reminders and notification system in Tasker.

---

## Overview

The Reminders feature provides:
- ⏰ Due date reminders for tasks
- 🔔 Push notifications
- 🔄 Recurring reminders
- 📱 Platform-specific notifications

---

## Features

### Task Due Dates
- Set due dates on tasks
- Optional reminder time
- Multiple reminders per task

### Notification Types
| Type      | Description       |
| --------- | ----------------- |
| Due Today | Tasks due today   |
| Upcoming  | Tasks due soon    |
| Overdue   | Past due date     |
| Custom    | User-defined time |

### Recurring Options
- Daily
- Weekly
- Monthly
- Custom intervals

---

## Usage

### Set Reminder on Task
```dart
final task = Task(
  title: 'Review code',
  dueDate: DateTime(2025, 1, 15),
  reminderTime: DateTime(2025, 1, 15, 9, 0),
);
```

### Schedule Notification
```dart
final notificationService = ref.read(notificationServiceProvider);
await notificationService.scheduleReminder(
  id: task.id,
  title: 'Task Due',
  body: task.title,
  scheduledTime: task.reminderTime,
);
```

---

## Architecture

```
┌────────────────────────────────────────────┐
│              Task with Due Date             │
└──────────────────────┬─────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────┐
│           NotificationService               │
│    (flutter_local_notifications)            │
└──────────────────────┬─────────────────────┘
                       │
           ┌───────────┴───────────┐
           ▼                       ▼
┌──────────────────┐    ┌──────────────────┐
│  Android Alarm   │    │   iOS UNNotif    │
│    Manager       │    │    Framework     │
└──────────────────┘    └──────────────────┘
```

---

## Platform Setup

### Android
Permissions in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

### iOS
Request notification permission:
```dart
await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
    ?.requestPermissions(alert: true, badge: true, sound: true);
```

---

## Notification Service

Key methods:
```dart
class NotificationService {
  // Schedule a reminder
  Future<void> scheduleReminder({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  });
  
  // Cancel a reminder
  Future<void> cancelReminder(String id);
  
  // Update existing reminder
  Future<void> updateReminder({...});
  
  // Get pending reminders
  Future<List<PendingNotification>> getPendingReminders();
}
```

---

## Related Docs

- [Tasks Guide](./tasks.md) - Task management
- [Notifications Guide](./notifications.md) - Push notification system
- [Notification System](../development/notifications-guide.md) - Implementation details

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Features Index](../README.md#-features)**

</div>
