# 📝 Diary Feature

Personal journaling with mood tracking in Tasker.

---

## Overview

The Diary feature allows users to:
- ✍️ Create journal entries with rich text
- 😊 Track moods with emoji indicators
- 🏷️ Organize with tags
- 🔍 Search and filter entries
- 📤 Export/import entries

---

## Screenshots

*Coming soon*

---

## Features

### Create Entries
- Title and body text
- Auto-timestamping
- Default to current date

### Mood Tracking
Available moods:
| Emoji | Mood       |
| ----- | ---------- |
| 😊     | Happy      |
| 😢     | Sad        |
| 😤     | Angry      |
| 😰     | Anxious    |
| 😌     | Calm       |
| 😐     | Neutral    |
| 🤔     | Reflective |
| 🎉     | Excited    |

### Tags
- Add multiple tags to entries
- Filter by tags
- Quick tag suggestions

### Search & Filter
- Full-text search
- Filter by mood
- Filter by date range
- Filter by tags

### Export/Import
- Export to JSON
- Import from backup
- Cross-device sync

---

## Usage

### Navigate to Diary
```dart
context.go('/diary');
```

### Create New Entry
```dart
context.go('/diary/editor');
```

### Edit Existing Entry
```dart
context.go('/diary/editor', extra: existingEntry);
```

---

## Data Model

```dart
class DiaryEntry {
  final String id;
  final String title;
  final String body;
  final DateTime entryDate;     // Date for the entry
  final DateTime createdAt;     // When created
  final DateTime? updatedAt;    // Last modified
  final List<String> tags;
  final Mood mood;
  final String? linkedTaskId;   // Optional task link
}
```

---

## Local Storage

Diary entries are stored locally using Hive:
- Box name: `diary`
- TypeId: `10`
- Offline-first architecture

---

## Routes

| Route           | Screen            | Purpose           |
| --------------- | ----------------- | ----------------- |
| `/diary`        | DiaryListScreen   | View all entries  |
| `/diary/editor` | DiaryEditorScreen | Create/edit entry |

---

## Related Docs

- [Tasks Guide](./tasks.md) - Link diary entries to tasks
- [Data Layer](../architecture/data-layer.md) - Storage architecture

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Features Index](../README.md#-features)**

</div>
