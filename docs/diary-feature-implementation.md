# Diary Feature Implementation Guide

## Overview

The Diary feature adds personal journaling capabilities to Tasker, allowing users to create, edit, and manage private diary entries with local persistent storage using Hive.

**Implementation Date:** November 23, 2025  
**Storage:** Local (Hive) with future cloud sync capability  
**Status:** ✅ Core Implementation Complete

---

## Table of Contents

1. [Architecture](#architecture)
2. [Feature Capabilities](#feature-capabilities)
3. [File Structure](#file-structure)
4. [Setup Instructions](#setup-instructions)
5. [Usage Guide](#usage-guide)
6. [Code Examples](#code-examples)
7. [Migration to Cloud](#migration-to-cloud)
8. [Testing](#testing)
9. [Future Enhancements](#future-enhancements)

---

## Architecture

### Technology Stack

- **Local Storage:** Hive (NoSQL database)
- **State Management:** Riverpod (code generation)
- **UI Framework:** Flutter Material 3
- **Data Models:** Equatable for value comparison

### Design Pattern

```
Presentation Layer (UI)
    ↓
Provider Layer (Riverpod)
    ↓
Repository Layer (Data Access)
    ↓
Storage Layer (Hive)
```

### Data Flow

1. User interacts with UI (`DiaryListScreen` or `DiaryEditorScreen`)
2. UI calls methods on `DiaryNotifier` (Riverpod provider)
3. `DiaryNotifier` uses `DiaryRepository` for data operations
4. `DiaryRepository` performs CRUD operations on Hive box
5. State updates trigger UI rebuilds via Riverpod

---

## Feature Capabilities

### ✅ Core Features

- **Create** diary entries with title, body, tags, and mood
- **Read** all entries sorted by creation date (newest first)
- **Update** existing entries
- **Delete** entries with confirmation
- **Search** entries by title or content
- **Filter** by tags, mood, or date range
- **Export** entries to JSON
- **Import** entries from JSON

### 📝 Entry Properties

| Property       | Type         | Required | Description                   |
| -------------- | ------------ | -------- | ----------------------------- |
| `id`           | String       | Yes      | Unique identifier (UUID)      |
| `title`        | String       | No       | Entry title                   |
| `body`         | String       | Yes      | Main content                  |
| `createdAt`    | DateTime     | Yes      | Creation timestamp            |
| `updatedAt`    | DateTime     | Yes      | Last modification timestamp   |
| `tags`         | List<String> | No       | Categorization tags           |
| `mood`         | String       | No       | Emotional state               |
| `linkedTaskId` | String       | No       | Link to related task (future) |

---

## File Structure

```
lib/src/features/diary/
├── models/
│   ├── diary_entry.dart          # Data model with Hive annotations
│   └── diary_entry.g.dart        # Generated Hive adapter
├── data/
│   └── diary_repository.dart     # Data access layer
├── providers/
│   ├── diary_notifier.dart       # State management
│   └── diary_notifier.g.dart     # Generated provider code
└── presentation/
    ├── diary_list_screen.dart    # List view UI
    └── diary_editor_screen.dart  # Create/edit UI
```

---

## Setup Instructions

### Step 1: Install Dependencies

Dependencies are already added to `pubspec.yaml`:

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.5
  uuid: ^4.5.1
  flutter_riverpod: ^3.0.3
  riverpod_annotation: ^3.0.3
  equatable: ^2.0.5
  intl: ^0.20.2

dev_dependencies:
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  riverpod_generator: ^3.0.3
```

Run to install:

```powershell
flutter pub get
```

### Step 2: Generate Code

Generate Hive adapters and Riverpod providers:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

This creates:
- `lib/src/features/diary/models/diary_entry.g.dart`
- `lib/src/features/diary/providers/diary_notifier.g.dart`

### Step 3: Initialize Hive in main.dart

Already added in `lib/main.dart`:

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'src/features/diary/models/diary_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(DiaryEntryAdapter());
  
  // ... rest of initialization
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 4: Add Navigation Route

Add to your router configuration (e.g., `lib/src/core/routing/app_router.dart`):

```dart
import 'package:go_router/go_router.dart';
import '../../features/diary/presentation/diary_list_screen.dart';

final appRouter = GoRouter(
  routes: [
    // ... existing routes
    GoRoute(
      path: '/diary',
      builder: (context, state) => const DiaryListScreen(),
    ),
  ],
);
```

### Step 5: Add Navigation Button

Add diary access to your main navigation (e.g., home screen drawer/bottom nav):

```dart
ListTile(
  leading: const Icon(Icons.book),
  title: const Text('Diary'),
  onTap: () {
    context.go('/diary');
  },
),
```

---

## Usage Guide

### Creating a New Entry

1. Open Diary screen
2. Tap the **"New Entry"** FAB (Floating Action Button)
3. Fill in:
   - **Title** (optional): Short description
   - **Body** (required): Main journal content
   - **Mood** (optional): Select from 8 predefined moods
   - **Tags** (optional): Comma-separated tags
4. Tap **"Save Entry"**

### Editing an Entry

1. Tap on any entry card in the list
2. Modify fields as needed
3. Tap **"Update Entry"**

### Deleting an Entry

**Option 1:** From list
- Tap the three-dot menu on an entry card
- Select "Delete"
- Confirm deletion

**Option 2:** From editor
- Open entry for editing
- Tap trash icon in app bar
- Confirm deletion

### Searching Entries

1. Tap search icon in app bar
2. Enter search term
3. Results filtered by title or body content
4. Tap X to clear search

### Exporting Diary

1. Tap three-dot menu in app bar
2. Select "Export Diary"
3. All entries exported to JSON format
4. *(Future: Save to file or share)*

---

## Code Examples

### Accessing Diary Provider

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasker/src/features/diary/providers/diary_notifier.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state changes
    final diaryState = ref.watch(diaryProvider);
    
    // Read notifier for method calls
    final diaryNotifier = ref.read(diaryProvider.notifier);
    
    return ListView.builder(
      itemCount: diaryState.entries.length,
      itemBuilder: (context, index) {
        final entry = diaryState.entries[index];
        return ListTile(
          title: Text(entry.title),
          subtitle: Text(entry.body),
        );
      },
    );
  }
}
```

### Creating an Entry Programmatically

```dart
final diaryNotifier = ref.read(diaryProvider.notifier);

await diaryNotifier.createEntry(
  title: 'Amazing Day',
  body: 'Today was incredible! I accomplished so much.',
  tags: ['personal', 'achievement'],
  mood: 'Happy',
);
```

### Searching Entries

```dart
final diaryNotifier = ref.read(diaryProvider.notifier);

// Search by keyword
await diaryNotifier.searchEntries('amazing');

// Filter by tag
await diaryNotifier.filterByTag('personal');

// Filter by mood
await diaryNotifier.filterByMood('Happy');

// Filter by date range
await diaryNotifier.filterByDateRange(
  DateTime(2025, 11, 1),
  DateTime(2025, 11, 30),
);
```

### Exporting and Importing

```dart
final diaryNotifier = ref.read(diaryProvider.notifier);

// Export to JSON
final jsonList = diaryNotifier.exportEntries();
// Save jsonList to file or send to server

// Import from JSON
await diaryNotifier.importEntries(jsonList);
```

---

## Migration to Cloud

When ready to add Firebase/cloud sync, follow these steps:

### 1. Update DiaryEntry Model

Add Firestore serialization:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  // ... existing fields
  
  // Add Firestore conversion
  factory DiaryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      mood: data['mood'],
      linkedTaskId: data['linkedTaskId'],
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'mood': mood,
      'linkedTaskId': linkedTaskId,
    };
  }
}
```

### 2. Create Firestore Repository

```dart
class DiaryFirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String get _userId => FirebaseAuth.instance.currentUser!.uid;
  
  CollectionReference get _collection =>
      _firestore.collection('users').doc(_userId).collection('diaryEntries');
  
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    await _collection.doc(entry.id).set(entry.toFirestore());
    return entry;
  }
  
  Stream<List<DiaryEntry>> watchEntries() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DiaryEntry.fromFirestore(doc)).toList());
  }
}
```

### 3. Hybrid Approach (Offline-First)

Keep Hive for offline access, sync with Firestore:

```dart
class HybridDiaryRepository {
  final DiaryRepository _local;
  final DiaryFirestoreRepository _cloud;
  final ConnectivityService _connectivity;
  
  Future<DiaryEntry> createEntry(/* params */) async {
    // Save locally first
    final entry = await _local.createEntry(/* params */);
    
    // Sync to cloud if online
    if (await _connectivity.isOnline()) {
      try {
        await _cloud.createEntry(entry);
      } catch (e) {
        // Mark for sync later
        _markForSync(entry.id);
      }
    }
    
    return entry;
  }
}
```

---

## Testing

### Unit Tests

Create `test/features/diary/data/diary_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tasker/src/features/diary/data/diary_repository.dart';
import 'package:tasker/src/features/diary/models/diary_entry.dart';

void main() {
  late DiaryRepository repository;
  
  setUp(() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DiaryEntryAdapter());
    repository = DiaryRepository();
    await repository.init();
  });
  
  tearDown(() async {
    await repository.close();
    await Hive.deleteFromDisk();
  });
  
  group('DiaryRepository', () {
    test('should create entry', () async {
      final entry = await repository.createEntry(
        title: 'Test',
        body: 'Test body',
      );
      
      expect(entry.id, isNotEmpty);
      expect(entry.title, 'Test');
      expect(entry.body, 'Test body');
    });
    
    test('should retrieve all entries', () async {
      await repository.createEntry(title: 'Entry 1', body: 'Body 1');
      await repository.createEntry(title: 'Entry 2', body: 'Body 2');
      
      final entries = repository.getAllEntries();
      expect(entries.length, 2);
    });
    
    test('should search entries', () async {
      await repository.createEntry(title: 'Flutter', body: 'Learning Flutter');
      await repository.createEntry(title: 'Dart', body: 'Programming in Dart');
      
      final results = repository.searchEntries('Flutter');
      expect(results.length, 1);
      expect(results.first.title, 'Flutter');
    });
  });
}
```

### Widget Tests

Create `test/features/diary/presentation/diary_list_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasker/src/features/diary/presentation/diary_list_screen.dart';

void main() {
  testWidgets('DiaryListScreen displays empty state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DiaryListScreen(),
        ),
      ),
    );
    
    expect(find.text('No diary entries yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
```

### Integration Tests

Create `integration_test/diary_flow_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tasker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Create and edit diary entry', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Navigate to diary
    await tester.tap(find.text('Diary'));
    await tester.pumpAndSettle();
    
    // Create entry
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byType(TextField).first, 'Test Entry');
    await tester.enterText(find.byType(TextField).at(1), 'This is a test');
    await tester.tap(find.text('Save Entry'));
    await tester.pumpAndSettle();
    
    // Verify entry appears
    expect(find.text('Test Entry'), findsOneWidget);
  });
}
```

---

## Future Enhancements

### Phase 1: Rich Text Editor
- Replace plain `TextField` with `flutter_quill` for rich formatting
- Add support for bold, italic, lists, headings
- Insert images and links

### Phase 2: Cloud Sync
- Implement Firebase Firestore integration
- Offline-first architecture with background sync
- Conflict resolution for concurrent edits

### Phase 3: Encryption
- End-to-end encryption for sensitive entries
- Use `flutter_secure_storage` for encryption keys
- Encrypted cloud backup

### Phase 4: Advanced Features
- **Voice-to-text:** Dictate entries
- **Reminders:** Daily journaling reminders
- **Templates:** Quick-start templates (gratitude, reflection, goals)
- **Analytics:** Mood trends, word count stats
- **Attachments:** Photos, audio notes, documents

### Phase 5: Collaboration
- **Shared Journals:** Family or team journals
- **Comments:** Collaborate on shared entries
- **Permissions:** View-only vs edit access

### Phase 6: AI Integration
- **Writing Prompts:** AI-generated journaling prompts
- **Sentiment Analysis:** Automatic mood detection
- **Insights:** Weekly/monthly summaries
- **Smart Tags:** AI-suggested tags

---

## Troubleshooting

### Error: "DiaryRepository not initialized"

**Solution:** Ensure `repository.init()` is called before any operations:

```dart
final repository = DiaryRepository();
await repository.init();
```

### Error: "HiveError: Box not found"

**Solution:** Run code generation:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

### Error: "Provider not found"

**Solution:** Wrap your app with `ProviderScope`:

```dart
runApp(const ProviderScope(child: MyApp()));
```

### Entries Not Persisting

**Cause:** Hive box not properly initialized or closed prematurely.

**Solution:**
1. Verify `Hive.initFlutter()` is called in `main()`
2. Register adapter: `Hive.registerAdapter(DiaryEntryAdapter())`
3. Don't call `repository.close()` while app is running

---

## Performance Optimization

### Lazy Loading

For large diaries (1000+ entries), implement pagination:

```dart
List<DiaryEntry> getEntries({int limit = 50, int offset = 0}) {
  _ensureBoxOpen();
  final allEntries = _box!.values.toList();
  allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return allEntries.skip(offset).take(limit).toList();
}
```

### Index for Search

Add index for faster search:

```dart
// In Hive box, create indexed fields
@HiveType(typeId: 0)
class DiaryEntry {
  @HiveField(0, indexed: true)
  final String searchableText; // Lowercase title + body for faster search
}
```

### Debounced Search

Prevent excessive searches while typing:

```dart
Timer? _debounce;

void onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    ref.read(diaryProvider.notifier).searchEntries(query);
  });
}
```

---

## Security Considerations

### Local Storage Security

Hive stores data in plain text by default. For sensitive entries:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> initSecureHive() async {
  final secureStorage = FlutterSecureStorage();
  final encryptionKeyString = await secureStorage.read(key: 'diary_key');
  
  if (encryptionKeyString == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'diary_key',
      value: base64UrlEncode(key),
    );
  }
  
  final key = base64Url.decode(encryptionKeyString!);
  final encryptedBox = await Hive.openBox<DiaryEntry>(
    'diary_entries',
    encryptionCipher: HiveAesCipher(key),
  );
}
```

### Data Backup

Implement regular backups:

```dart
Future<void> backupDiary() async {
  final entries = repository.exportToJson();
  final file = File('${documentsDir}/diary_backup.json');
  await file.writeAsString(jsonEncode(entries));
  
  // Upload to cloud storage (Firebase Storage, etc.)
}
```

---

## API Reference

### DiaryRepository

#### Methods

| Method                              | Parameters                     | Returns               | Description         |
| ----------------------------------- | ------------------------------ | --------------------- | ------------------- |
| `init()`                            | -                              | `Future<void>`        | Initialize Hive box |
| `getAllEntries()`                   | -                              | `List<DiaryEntry>`    | Get all entries     |
| `getEntryById(id)`                  | `String id`                    | `DiaryEntry?`         | Get single entry    |
| `searchEntries(query)`              | `String query`                 | `List<DiaryEntry>`    | Search by keyword   |
| `getEntriesByTag(tag)`              | `String tag`                   | `List<DiaryEntry>`    | Filter by tag       |
| `getEntriesByMood(mood)`            | `String mood`                  | `List<DiaryEntry>`    | Filter by mood      |
| `getEntriesByDateRange(start, end)` | `DateTime start, DateTime end` | `List<DiaryEntry>`    | Filter by dates     |
| `createEntry({...})`                | See below                      | `Future<DiaryEntry>`  | Create new entry    |
| `updateEntry(id, {...})`            | See below                      | `Future<DiaryEntry?>` | Update entry        |
| `deleteEntry(id)`                   | `String id`                    | `Future<void>`        | Delete entry        |
| `exportToJson()`                    | -                              | `List<Map>`           | Export all entries  |
| `importFromJson(jsonList)`          | `List<Map>`                    | `Future<void>`        | Import entries      |

#### createEntry Parameters

```dart
Future<DiaryEntry> createEntry({
  required String title,
  required String body,
  List<String> tags = const [],
  String? mood,
  String? linkedTaskId,
})
```

#### updateEntry Parameters

```dart
Future<DiaryEntry?> updateEntry(
  String id, {
  String? title,
  String? body,
  List<String>? tags,
  String? mood,
  String? linkedTaskId,
})
```

### DiaryNotifier (Riverpod)

#### Methods

| Method                          | Parameters            | Returns               | Description           |
| ------------------------------- | --------------------- | --------------------- | --------------------- |
| `loadEntries()`                 | -                     | `Future<void>`        | Refresh entry list    |
| `createEntry({...})`            | Same as repo          | `Future<DiaryEntry?>` | Create + refresh      |
| `updateEntry(id, {...})`        | Same as repo          | `Future<bool>`        | Update + refresh      |
| `deleteEntry(id)`               | `String id`           | `Future<bool>`        | Delete + refresh      |
| `searchEntries(query)`          | `String query`        | `Future<void>`        | Search + update state |
| `filterByTag(tag)`              | `String tag`          | `Future<void>`        | Filter + update state |
| `filterByMood(mood)`            | `String mood`         | `Future<void>`        | Filter + update state |
| `filterByDateRange(start, end)` | `DateTime start, end` | `Future<void>`        | Filter + update state |
| `clearFilters()`                | -                     | `Future<void>`        | Reset to all entries  |
| `exportEntries()`               | -                     | `List<Map>`           | Export to JSON        |
| `importEntries(jsonList)`       | `List<Map>`           | `Future<void>`        | Import from JSON      |

---

## Changelog

### v1.0.0 (November 23, 2025)
- ✅ Initial implementation
- ✅ Local Hive storage
- ✅ CRUD operations
- ✅ Search and filter
- ✅ Tags and mood support
- ✅ Export/import functionality
- ✅ Material 3 UI

### Planned v1.1.0
- [ ] Rich text editor
- [ ] Image attachments
- [ ] Daily reminders
- [ ] Calendar view

### Planned v2.0.0
- [ ] Firebase sync
- [ ] End-to-end encryption
- [ ] Multi-device support
- [ ] Shared journals

---

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review [Tasker documentation](../overview.md)
3. Open an issue on GitHub

---

## License

Part of Tasker project - Private application (not for publication)

---

**Last Updated:** November 23, 2025  
**Maintained by:** Tasker Development Team
