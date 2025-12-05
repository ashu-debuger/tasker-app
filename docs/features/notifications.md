# 🔔 Notifications

Push notification system in Tasker.

---

## Overview

Tasker uses **flutter_local_notifications** for:
- 📅 Task reminders
- 📨 Project updates
- 💬 Chat messages
- 🔄 Routine reminders

---

## Setup

### Dependencies
```yaml
dependencies:
  flutter_local_notifications: ^19.2.0
  timezone: ^0.10.0
```

### Platform Configuration

#### Android

In `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### iOS

In `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## Notification Types

| Type           | Icon | Channel         |
| -------------- | ---- | --------------- |
| Task Due       | ✅    | task_reminders  |
| Chat Message   | 💬    | chat_messages   |
| Project Update | 📁    | project_updates |
| Routine        | 🔄    | daily_routines  |

---

## Usage

### Initialize Service
```dart
// In main.dart
final notificationService = NotificationService();
await notificationService.initialize();
```

### Show Immediate Notification
```dart
await notificationService.showNotification(
  id: 1,
  title: 'Task Complete',
  body: 'You completed "Review PR"',
);
```

### Schedule Notification
```dart
await notificationService.scheduleNotification(
  id: 2,
  title: 'Task Due',
  body: 'Review code is due in 1 hour',
  scheduledTime: DateTime.now().add(Duration(hours: 1)),
);
```

### Cancel Notification
```dart
await notificationService.cancel(2);
// or cancel all
await notificationService.cancelAll();
```

---

## Notification Channels

Android 8.0+ requires notification channels:

```dart
const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
  'task_reminders',
  'Task Reminders',
  description: 'Notifications for task due dates',
  importance: Importance.high,
);
```

---

## Handling Taps

```dart
void onNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload != null) {
    final data = jsonDecode(payload);
    // Navigate based on notification type
    if (data['type'] == 'task') {
      context.go('/tasks/${data['taskId']}');
    }
  }
}
```

---

## Notification Payload

```dart
final payload = jsonEncode({
  'type': 'task',
  'taskId': 'abc123',
  'action': 'due_reminder',
});

await notificationService.showNotification(
  id: 1,
  title: 'Task Due',
  body: 'Check in meeting in 15 minutes',
  payload: payload,
);
```

---

## Best Practices

### ✅ Do
- Request permissions on first relevant action
- Provide notification settings in app
- Use appropriate importance levels
- Group related notifications

### ❌ Don't
- Spam users with notifications
- Request permissions at app launch
- Use high importance for non-urgent items

---

## Related Docs

- [Reminders Guide](./reminders.md) - Task reminders
- [Notification System](../development/notifications-guide.md) - Implementation details

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Features Index](../README.md#-features)**

</div>
