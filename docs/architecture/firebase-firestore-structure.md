# 🔥 Firestore Structure

Database schema and collections for Tasker.

> 📖 For the complete detailed schema, see the [Full Schema Reference](./firestore-schema-full.md).

---

## Overview

Tasker uses Cloud Firestore with the following structure:

### Root Collections
| Collection     | Description              |
| -------------- | ------------------------ |
| `users`        | User profiles            |
| `projects`     | Collaborative workspaces |
| `tasks`        | Task items               |
| `subtasks`     | Subtasks                 |
| `routines`     | Daily routines           |
| `invitations`  | Project invitations      |
| `mindMaps`     | Mind map documents       |
| `mindMapNodes` | Mind map nodes           |

### Subcollections
| Path                       | Description         |
| -------------------------- | ------------------- |
| `projects/{id}/members`    | Project members     |
| `projects/{id}/messages`   | Chat messages       |
| `users/{id}/sticky_notes`  | User's sticky notes |
| `users/{id}/notifications` | User notifications  |
| `users/{id}/diary_entries` | Diary entries       |

---

## Key Collections

### Users
```
users/{userId}
├── id: string
├── email: string
├── displayName: string?
├── photoUrl: string?
├── createdAt: Timestamp
└── updatedAt: Timestamp?
```

### Projects
```
projects/{projectId}
├── name: string
├── description: string?
├── ownerId: string
├── members: string[]
├── memberRoles: Map<string, Role>
├── createdAt: Timestamp
└── updatedAt: Timestamp?
```

### Tasks
```
tasks/{taskId}
├── projectId: string
├── title: string
├── description: string?
├── status: "pending" | "in_progress" | "completed"
├── priority: "low" | "medium" | "high" | "urgent"
├── dueDate: Timestamp?
├── assignees: string[]
├── createdAt: Timestamp
└── updatedAt: Timestamp?
```

---

## Data Types

### Enums (stored as strings)

**TaskStatus**
```typescript
"pending" | "in_progress" | "completed"
```

**TaskPriority**
```typescript
"low" | "medium" | "high" | "urgent"
```

**ProjectRole**
```typescript
"owner" | "admin" | "editor" | "viewer"
```

### Timestamps

- Firestore: `Timestamp` type
- Dart: Convert to `DateTime`
- JSON: ISO 8601 string

---

## Queries

### User's Projects
```dart
firestore
  .collection('projects')
  .where('members', arrayContains: userId);
```

### User's Tasks
```dart
firestore
  .collection('tasks')
  .where('assignees', arrayContains: userId);
```

### Project Tasks
```dart
firestore
  .collection('tasks')
  .where('projectId', isEqualTo: projectId);
```

---

## Indexes

Required composite indexes are defined in `firestore.indexes.json`.

Deploy with:
```bash
firebase deploy --only firestore:indexes
```

---

## Related Docs

- [Full Firestore Schema](../../docs/firebase-firestore-structure.md) - Complete documentation
- [Security Rules](./firestore-rules.md) - Access control
- [Data Layer](./data-layer.md) - Repository patterns

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Security Rules →](./firestore-rules.md)**

</div>
