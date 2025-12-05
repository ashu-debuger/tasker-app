# 🔄 State Management

Riverpod patterns and best practices in Tasker.

---

## Overview

Tasker uses **Riverpod** with code generation for type-safe, testable state management.

### Why Riverpod?

- ✅ Compile-time safety
- ✅ Dependency injection
- ✅ Easy testing
- ✅ Code generation reduces boilerplate
- ✅ Great DevTools support

---

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

dev_dependencies:
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
```

---

## Provider Types

### @riverpod (Auto-dispose)

Most common. Automatically disposes when no longer used.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_providers.g.dart';

@riverpod
Future<List<Task>> taskList(TaskListRef ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTasks();
}
```

### @Riverpod(keepAlive: true)

For state that should persist throughout app lifecycle.

```dart
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  User? build() => null;
  
  void setUser(User user) => state = user;
  void logout() => state = null;
}
```

---

## Notifier Pattern

For mutable state with actions:

```dart
@riverpod
class TaskList extends _$TaskList {
  @override
  Future<List<Task>> build() async {
    final repository = ref.watch(taskRepositoryProvider);
    return repository.getTasks();
  }
  
  Future<void> addTask(Task task) async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.addTask(task);
    ref.invalidateSelf();
  }
  
  Future<void> deleteTask(String id) async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.deleteTask(id);
    ref.invalidateSelf();
  }
}
```

---

## Consuming State

### ConsumerWidget

```dart
class TaskListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    
    return tasksAsync.when(
      data: (tasks) => ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (_, i) => TaskCard(task: tasks[i]),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => ErrorWidget(error: e),
    );
  }
}
```

### ConsumerStatefulWidget

When you need StatefulWidget lifecycle:

```dart
class TaskEditScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  
  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskProvider(widget.taskId));
    // ...
  }
}
```

---

## Family Providers

For parameterized providers:

```dart
@riverpod
Future<Task?> task(TaskRef ref, String taskId) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTask(taskId);
}

// Usage
final task = ref.watch(taskProvider('task-123'));
```

---

## Repository Providers

```dart
@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  return TaskRepository(
    firestore: FirebaseFirestore.instance,
    hiveBox: Hive.box<Task>('tasks'),
  );
}
```

---

## Common Patterns

### Invalidate and Refresh

```dart
// Invalidate to rebuild
ref.invalidate(taskListProvider);

// Refresh to get new value
final tasks = await ref.refresh(taskListProvider.future);
```

### Watching Multiple Providers

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final tasks = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);
  final user = ref.watch(currentUserProvider);
  
  // Combine data...
}
```

### Side Effects

Use `ref.listen` for side effects:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(authStateProvider, (previous, next) {
    if (next == null) {
      context.go('/login');
    }
  });
  
  return // ...
}
```

---

## Code Generation

After modifying providers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or watch mode:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## Testing

```dart
void main() {
  test('TaskList loads tasks', () async {
    final container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(
          MockTaskRepository(),
        ),
      ],
    );
    
    final tasks = await container.read(taskListProvider.future);
    expect(tasks, hasLength(3));
  });
}
```

---

## Best Practices

### ✅ Do

- Use `ref.watch` for reactive updates
- Use `ref.read` for one-time reads in callbacks
- Use `@riverpod` annotation for all providers
- Keep providers focused and small
- Use `.family` for parameterized providers

### ❌ Don't

- Use `ref.read` for reactive updates
- Create providers without code generation
- Put business logic in widgets
- Forget to run build_runner after changes

---

## Related Docs

- [Overview](./overview.md) - Architecture overview
- [Data Layer](./data-layer.md) - Repositories and models
- [Folder Structure](./folder-structure.md) - Code organization

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Data Layer →](./data-layer.md)**

</div>
