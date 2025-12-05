# ✅ Tasks

Task management in Tasker.

---

## Overview

Tasks are the core of Tasker, providing:
- 📝 Create and manage tasks
- 📋 Subtasks for complex work
- ⚡ Priority levels
- 📅 Due dates and reminders
- 📁 Organize by project

---

## Features

### Task Properties
| Property      | Type      | Description               |
| ------------- | --------- | ------------------------- |
| `title`       | String    | Task name                 |
| `description` | String?   | Detailed description      |
| `status`      | Enum      | Todo, In Progress, Done   |
| `priority`    | Enum      | Low, Medium, High, Urgent |
| `dueDate`     | DateTime? | When task is due          |
| `projectId`   | String?   | Parent project            |
| `isEncrypted` | bool      | Optional encryption       |

### Status Flow
```
Todo → In Progress → Done
  ↑         |
  └─────────┘ (reopen)
```

### Priority Levels
| Level  | Color  | Icon |
| ------ | ------ | ---- |
| Low    | Blue   | 🔵    |
| Medium | Yellow | 🟡    |
| High   | Orange | 🟠    |
| Urgent | Red    | 🔴    |

---

## Data Model

```dart
@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    String? description,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueDate,
    String? projectId,
    required String userId,
    @Default(false) bool isEncrypted,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) = _Task;
}

enum TaskStatus { todo, inProgress, done }
enum TaskPriority { low, medium, high, urgent }
```

---

## Subtasks

Break down complex tasks:

```dart
@freezed
class Subtask with _$Subtask {
  const factory Subtask({
    required String id,
    required String taskId,
    required String title,
    @Default(false) bool isCompleted,
    required DateTime createdAt,
  }) = _Subtask;
}
```

### Progress Calculation
```dart
double get completionPercentage {
  if (subtasks.isEmpty) return 0;
  final completed = subtasks.where((s) => s.isCompleted).length;
  return completed / subtasks.length * 100;
}
```

---

## Usage

### Create Task
```dart
final task = Task(
  id: const Uuid().v4(),
  title: 'Review pull request',
  status: TaskStatus.todo,
  priority: TaskPriority.high,
  dueDate: DateTime.now().add(Duration(days: 1)),
  userId: currentUserId,
  createdAt: DateTime.now(),
);

await ref.read(taskListProvider.notifier).addTask(task);
```

### Update Task
```dart
final updated = task.copyWith(
  status: TaskStatus.inProgress,
  updatedAt: DateTime.now(),
);

await ref.read(taskListProvider.notifier).updateTask(updated);
```

### Complete Task
```dart
final completed = task.copyWith(
  status: TaskStatus.done,
  completedAt: DateTime.now(),
);

await ref.read(taskListProvider.notifier).updateTask(completed);
```

---

## Task List Views

### By Status
```dart
final todoTasks = tasks.where((t) => t.status == TaskStatus.todo);
final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress);
final doneTasks = tasks.where((t) => t.status == TaskStatus.done);
```

### By Priority
```dart
final urgentTasks = tasks.where((t) => t.priority == TaskPriority.urgent);
```

### By Due Date
```dart
final overdueTasks = tasks.where((t) => 
  t.dueDate != null && 
  t.dueDate!.isBefore(DateTime.now()) &&
  t.status != TaskStatus.done
);
```

---

## Routes

| Route             | Screen           | Purpose           |
| ----------------- | ---------------- | ----------------- |
| `/tasks`          | TaskListScreen   | View all tasks    |
| `/tasks/:id`      | TaskDetailScreen | View task details |
| `/tasks/new`      | TaskEditScreen   | Create task       |
| `/tasks/:id/edit` | TaskEditScreen   | Edit task         |

---

## Related Docs

- [Projects Guide](./projects.md) - Organize tasks in projects
- [Reminders Guide](./reminders.md) - Task reminders
- [Subtasks](./tasks.md#subtasks) - Break down tasks

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Features Index](../README.md#-features)**

</div>
