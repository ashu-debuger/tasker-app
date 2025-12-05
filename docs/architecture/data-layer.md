# 📦 Data Layer

Repositories, models, and data flow in Tasker.

---

## Overview

The data layer handles:
- Data models (Freezed)
- Repositories (Firebase + Hive)
- Type adapters (Hive)
- Data serialization

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                     │
│                    (Notifiers/Providers)                 │
└─────────────────────────────────┬───────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────┐
│                      Repository                          │
│            (Abstraction over data sources)               │
└──────────────┬──────────────────────────┬───────────────┘
               │                          │
               ▼                          ▼
┌──────────────────────┐    ┌──────────────────────┐
│    Cloud Firestore   │    │    Local Hive Box    │
│   (Remote Storage)   │    │   (Offline Cache)    │
└──────────────────────┘    └──────────────────────┘
```

---

## Models with Freezed

### Basic Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    String? description,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueDate,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
```

### With Default Values

```dart
@freezed
class DiaryEntry with _$DiaryEntry {
  const factory DiaryEntry({
    required String id,
    required String content,
    @Default(Mood.neutral) Mood mood,
    required DateTime entryDate,
    required DateTime createdAt,
  }) = _DiaryEntry;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => 
      _$DiaryEntryFromJson(json);
}
```

---

## Repository Pattern

### Repository Interface

```dart
abstract class TaskRepository {
  Future<List<Task>> getTasks(String userId);
  Future<Task?> getTask(String id);
  Future<void> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Stream<List<Task>> watchTasks(String userId);
}
```

### Firebase Implementation

```dart
class FirebaseTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;
  
  FirebaseTaskRepository(this._firestore);
  
  @override
  Future<List<Task>> getTasks(String userId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => Task.fromJson({
          'id': doc.id,
          ...doc.data(),
        }))
        .toList();
  }
  
  @override
  Stream<List<Task>> watchTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
            .toList());
  }
  
  @override
  Future<void> addTask(Task task) async {
    await _firestore
        .collection('tasks')
        .doc(task.id)
        .set(task.toJson()..remove('id'));
  }
}
```

---

## Hive Local Storage

### Type Adapter

```dart
import 'package:hive/hive.dart';

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Task.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeMap(obj.toJson());
  }
}
```

### Registration

```dart
void main() async {
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(DiaryEntryAdapter());
  
  // Open boxes
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<DiaryEntry>('diary');
}
```

### Hybrid Repository

```dart
class TaskRepository {
  final FirebaseFirestore _firestore;
  final Box<Task> _localBox;
  
  TaskRepository(this._firestore, this._localBox);
  
  Future<List<Task>> getTasks(String userId) async {
    try {
      // Try cloud first
      final tasks = await _getCloudTasks(userId);
      
      // Cache locally
      await _localBox.clear();
      for (final task in tasks) {
        await _localBox.put(task.id, task);
      }
      
      return tasks;
    } catch (e) {
      // Fallback to local cache
      return _localBox.values.toList();
    }
  }
}
```

---

## Firestore Timestamp Handling

```dart
@freezed
class Task with _$Task {
  const factory Task({
    // ...
    required DateTime createdAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle Firestore Timestamp
    if (json['createdAt'] is Timestamp) {
      json['createdAt'] = (json['createdAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    return _$TaskFromJson(json);
  }
}
```

---

## Provider Integration

```dart
@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  return TaskRepository(
    FirebaseFirestore.instance,
    Hive.box<Task>('tasks'),
  );
}

@riverpod
Future<List<Task>> taskList(TaskListRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTasks(userId);
}
```

---

## Enums

```dart
enum TaskStatus {
  @JsonValue('todo')
  todo,
  @JsonValue('inProgress')
  inProgress,
  @JsonValue('done')
  done,
}

enum TaskPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}
```

---

## Best Practices

### ✅ Do

- Use Freezed for immutable models
- Handle Firestore Timestamps
- Cache data locally with Hive
- Use repository pattern for abstraction
- Stream data for real-time updates

### ❌ Don't

- Access Firestore directly from widgets
- Forget to register Hive adapters
- Ignore offline scenarios
- Hard-code collection names

---

## Related Docs

- [Firestore Structure](./firebase-firestore-structure.md) - Database schema
- [State Management](./state-management.md) - Riverpod providers
- [Firestore Rules](./firestore-rules.md) - Security rules

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Firestore Structure →](./firebase-firestore-structure.md)**

</div>
