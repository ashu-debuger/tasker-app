import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:tasker/src/core/encryption/encryption_service.dart';
import 'package:tasker/src/core/storage/adapters/sticky_note_adapter.dart';
import 'package:tasker/src/features/sticky_notes/data/repositories/firebase_sticky_note_repository.dart';
import 'package:tasker/src/features/sticky_notes/domain/models/sticky_note.dart';

@GenerateMocks([EncryptionService])
import 'firebase_sticky_note_repository_test.mocks.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockEncryptionService mockEncryption;
  late Box<StickyNote> testBox;
  late FirebaseStickyNoteRepository repository;

  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('./test/hive_test');
    
    // Register adapters
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(NotePositionAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(StickyNoteAdapter());
    }
  });

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    mockEncryption = MockEncryptionService();

    // Create a fresh box for each test
    try {
      await Hive.deleteBoxFromDisk('test_sticky_notes');
    } catch (_) {}
    testBox = await Hive.openBox<StickyNote>('test_sticky_notes');

    repository = FirebaseStickyNoteRepository(
      fakeFirestore,
      mockEncryption,
      testBox,
    );

    // Default mock behavior: encryption is a no-op (returns same string)
    when(mockEncryption.encrypt(any))
        .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
    when(mockEncryption.decrypt(any))
        .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
  });

  tearDown(() async {
    await testBox.clear();
    await testBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('FirebaseStickyNoteRepository', () {
    group('createNote', () {
      test('creates note in Firestore and caches in Hive', () async {
        // Arrange
        final note = StickyNote(
          id: 'note-1',
          title: 'Test Note',
          content: 'Test content',
          color: NoteColor.yellow,
          position: const NotePosition(x: 100, y: 200),
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 1,
        );

        // Act
        await repository.createNote(note);

        // Assert - Check Firestore
        final doc = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;
        expect(data['id'], 'note-1');
        expect(data['title'], 'Test Note');
        expect(data['content'], 'Test content');
        expect(data['color'], 'yellow');
        expect(data['userId'], 'user-1');

        // Assert - Check Hive cache
        expect(testBox.containsKey('note-1'), isTrue);
        final cached = testBox.get('note-1');
        expect(cached!.id, 'note-1');
        expect(cached.title, 'Test Note');

        // Verify encryption was called
        verify(mockEncryption.encrypt('Test content')).called(1);
      });

      test('creates note with encrypted content', () async {
        // Arrange
        when(mockEncryption.encrypt('Secret content'))
            .thenAnswer((_) async => 'encrypted_content');

        final note = StickyNote(
          id: 'note-2',
          content: 'Secret content',
          color: NoteColor.pink,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );

        // Act
        await repository.createNote(note);

        // Assert - Firestore should have encrypted content
        final doc = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .get();

        expect(doc.data()!['content'], 'encrypted_content');

        // Hive cache should also have encrypted content
        final cached = testBox.get('note-2');
        expect(cached!.content, 'encrypted_content');
      });

      test('handles encryption failure gracefully', () async {
        // Arrange
        when(mockEncryption.encrypt(any))
            .thenThrow(Exception('Encryption failed'));

        final note = StickyNote(
          id: 'note-3',
          content: 'Plain content',
          color: NoteColor.blue,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );

        // Act
        await repository.createNote(note);

        // Assert - Should store plain content when encryption fails
        final doc = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-3')
            .get();

        expect(doc.data()!['content'], 'Plain content');
      });
    });

    group('getNoteById', () {
      test('returns note from cache if available', () async {
        // Arrange
        final note = StickyNote(
          id: 'note-1',
          content: 'Cached content',
          color: NoteColor.green,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );
        await testBox.put('note-1', note);

        // Act
        final result = await repository.getNoteById('note-1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'note-1');
        expect(result.content, 'Cached content');
        
        // Should try to decrypt cached content
        verify(mockEncryption.decrypt('Cached content')).called(1);
      });

      test('fetches from Firestore if not in cache', () async {
        // Arrange
        final noteData = StickyNote(
          id: 'note-2',
          content: 'Firestore content',
          color: NoteColor.purple,
          position: const NotePosition(x: 50, y: 100),
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .set(noteData.toJson());

        // Ensure there's at least one cached note so userId can be determined
        final dummyNote = StickyNote(
          id: 'dummy',
          content: 'dummy',
          color: NoteColor.yellow,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );
        await testBox.put('dummy', dummyNote);

        // Act
        final result = await repository.getNoteById('note-2');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'note-2');
        expect(result.content, 'Firestore content');

        // Should be cached after fetching
        expect(testBox.containsKey('note-2'), isTrue);
      });

      test('returns null for non-existent note', () async {
        // Arrange - Add dummy note for userId
        final dummyNote = StickyNote(
          id: 'dummy',
          content: 'dummy',
          color: NoteColor.yellow,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );
        await testBox.put('dummy', dummyNote);

        // Act
        final result = await repository.getNoteById('non-existent');

        // Assert
        expect(result, isNull);
      });

      test('decrypts content when fetching', () async {
        // Arrange
        when(mockEncryption.decrypt('encrypted_data'))
            .thenAnswer((_) async => 'decrypted_data');

        final note = StickyNote(
          id: 'note-3',
          content: 'encrypted_data',
          color: NoteColor.orange,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );
        await testBox.put('note-3', note);

        // Act
        final result = await repository.getNoteById('note-3');

        // Assert
        expect(result!.content, 'decrypted_data');
        verify(mockEncryption.decrypt('encrypted_data')).called(1);
      });
    });

    group('updateNote', () {
      test('updates note in Firestore and cache', () async {
        // Arrange
        final originalNote = StickyNote(
          id: 'note-1',
          content: 'Original content',
          color: NoteColor.yellow,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 1,
        );

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .set(originalNote.toJson());

        final updatedNote = originalNote.copyWith(
          content: 'Updated content',
          position: const NotePosition(x: 150, y: 250),
          zIndex: 2,
        );

        // Act
        await repository.updateNote(updatedNote);

        // Assert - Check Firestore
        final doc = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .get();

        expect(doc.data()!['content'], 'Updated content');
        expect(doc.data()!['position']['x'], 150.0);
        expect(doc.data()!['position']['y'], 250.0);
        expect(doc.data()!['zIndex'], 2);
        expect(doc.data()!['updatedAt'], isNotNull);

        // Assert - Check Hive cache
        final cached = testBox.get('note-1');
        expect(cached!.content, 'Updated content');
        expect(cached.position.x, 150.0);
        expect(cached.zIndex, 2);
      });

      test('sets updatedAt timestamp', () async {
        // Arrange
        final note = StickyNote(
          id: 'note-2',
          content: 'Content',
          color: NoteColor.pink,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          updatedAt: null,
        );

        // Create the note first
        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .set(note.toJson());

        // Act
        await repository.updateNote(note);

        // Assert
        final cached = testBox.get('note-2');
        expect(cached!.updatedAt, isNotNull);
        expect(cached.updatedAt!.isAfter(DateTime(2025, 11, 13)), isTrue);
      });
    });

    group('deleteNote', () {
      test('deletes note from Firestore and cache', () async {
        // Arrange
        final note = StickyNote(
          id: 'note-1',
          content: 'To be deleted',
          color: NoteColor.blue,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .set(note.toJson());

        await testBox.put('note-1', note);

        // Act
        await repository.deleteNote('note-1');

        // Assert - Check Firestore
        final doc = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .get();

        expect(doc.exists, isFalse);

        // Assert - Check Hive cache
        expect(testBox.containsKey('note-1'), isFalse);
      });

      test('handles deletion of non-existent note gracefully', () async {
        // Act & Assert - Should not throw
        await repository.deleteNote('non-existent');

        // Cache should not have it
        expect(testBox.containsKey('non-existent'), isFalse);
      });
    });

    group('streamNotesForUser', () {
      test('streams notes ordered by zIndex', () async {
        // Arrange
        final note1 = StickyNote(
          id: 'note-1',
          content: 'Note 1',
          color: NoteColor.yellow,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 3,
        );

        final note2 = StickyNote(
          id: 'note-2',
          content: 'Note 2',
          color: NoteColor.pink,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 1,
        );

        final note3 = StickyNote(
          id: 'note-3',
          content: 'Note 3',
          color: NoteColor.blue,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 2,
        );

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .set(note1.toJson());

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .set(note2.toJson());

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-3')
            .set(note3.toJson());

        // Act
        final stream = repository.streamNotesForUser('user-1');
        final notes = await stream.first;

        // Assert - Should be ordered by zIndex ascending
        expect(notes.length, 3);
        expect(notes[0].id, 'note-2'); // zIndex: 1
        expect(notes[1].id, 'note-3'); // zIndex: 2
        expect(notes[2].id, 'note-1'); // zIndex: 3
      });

      test('caches notes in Hive while streaming', () async {
        // Arrange
        final note = StickyNote(
          id: 'note-1',
          content: 'Streamed note',
          color: NoteColor.green,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 1,
        );

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .set(note.toJson());

        // Act
        final stream = repository.streamNotesForUser('user-1');
        await stream.first;

        // Assert - Should be cached
        expect(testBox.containsKey('note-1'), isTrue);
        final cached = testBox.get('note-1');
        expect(cached!.content, 'Streamed note');
      });

      test('decrypts content for all notes', () async {
        // Arrange
        when(mockEncryption.decrypt('encrypted_1'))
            .thenAnswer((_) async => 'decrypted_1');
        when(mockEncryption.decrypt('encrypted_2'))
            .thenAnswer((_) async => 'decrypted_2');

        final note1 = StickyNote(
          id: 'note-1',
          content: 'encrypted_1',
          color: NoteColor.yellow,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 1,
        );

        final note2 = StickyNote(
          id: 'note-2',
          content: 'encrypted_2',
          color: NoteColor.pink,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 2,
        );

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .set(note1.toJson());

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .set(note2.toJson());

        // Act
        final stream = repository.streamNotesForUser('user-1');
        final notes = await stream.first;

        // Assert
        expect(notes[0].content, 'decrypted_1');
        expect(notes[1].content, 'decrypted_2');
        verify(mockEncryption.decrypt('encrypted_1')).called(1);
        verify(mockEncryption.decrypt('encrypted_2')).called(1);
      });
    });

    group('updateNotes (batch)', () {
      test('updates multiple notes in single batch', () async {
        // Arrange
        final note1 = StickyNote(
          id: 'note-1',
          content: 'Content 1',
          color: NoteColor.yellow,
          position: const NotePosition(x: 0, y: 0),
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 1,
        );

        final note2 = StickyNote(
          id: 'note-2',
          content: 'Content 2',
          color: NoteColor.pink,
          position: const NotePosition(x: 100, y: 100),
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
          zIndex: 2,
        );

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .set(note1.toJson());

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .set(note2.toJson());

        final updatedNote1 = note1.copyWith(position: const NotePosition(x: 200, y: 200));
        final updatedNote2 = note2.copyWith(position: const NotePosition(x: 300, y: 300));

        // Act
        await repository.updateNotes([updatedNote1, updatedNote2]);

        // Assert - Check Firestore
        final doc1 = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .get();

        final doc2 = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .get();

        expect(doc1.data()!['position']['x'], 200.0);
        expect(doc2.data()!['position']['x'], 300.0);

        // Assert - Check Hive cache
        expect(testBox.get('note-1')!.position.x, 200.0);
        expect(testBox.get('note-2')!.position.x, 300.0);
      });

      test('handles empty list gracefully', () async {
        // Act & Assert - Should not throw
        await repository.updateNotes([]);
      });
    });

    group('deleteNotes (batch)', () {
      test('deletes multiple notes in single batch', () async {
        // Arrange
        final note1 = StickyNote(
          id: 'note-1',
          content: 'Content 1',
          color: NoteColor.blue,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );

        final note2 = StickyNote(
          id: 'note-2',
          content: 'Content 2',
          color: NoteColor.green,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .set(note1.toJson());

        await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .set(note2.toJson());

        await testBox.put('note-1', note1);
        await testBox.put('note-2', note2);

        // Act
        await repository.deleteNotes(['note-1', 'note-2']);

        // Assert - Check Firestore
        final doc1 = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .get();

        final doc2 = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .get();

        expect(doc1.exists, isFalse);
        expect(doc2.exists, isFalse);

        // Assert - Check Hive cache
        expect(testBox.containsKey('note-1'), isFalse);
        expect(testBox.containsKey('note-2'), isFalse);
      });
    });

    group('syncOfflineNotes', () {
      test('syncs all cached notes to Firestore', () async {
        // Arrange
        final note1 = StickyNote(
          id: 'note-1',
          content: 'Cached 1',
          color: NoteColor.purple,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );

        final note2 = StickyNote(
          id: 'note-2',
          content: 'Cached 2',
          color: NoteColor.orange,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );

        await testBox.put('note-1', note1);
        await testBox.put('note-2', note2);

        // Act
        await repository.syncOfflineNotes();

        // Assert - Check Firestore
        final doc1 = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .get();

        final doc2 = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-2')
            .get();

        expect(doc1.exists, isTrue);
        expect(doc2.exists, isTrue);
        expect(doc1.data()!['content'], 'Cached 1');
        expect(doc2.data()!['content'], 'Cached 2');
      });

      test('handles empty cache gracefully', () async {
        // Act & Assert - Should not throw
        await repository.syncOfflineNotes();
      });

      test('groups notes by userId for batch operations', () async {
        // Arrange
        final note1 = StickyNote(
          id: 'note-1',
          content: 'User 1 note',
          color: NoteColor.yellow,
          position: NotePosition.zero,
          userId: 'user-1',
          createdAt: DateTime(2025, 11, 13),
        );

        final note2 = StickyNote(
          id: 'note-2',
          content: 'User 2 note',
          color: NoteColor.pink,
          position: NotePosition.zero,
          userId: 'user-2',
          createdAt: DateTime(2025, 11, 13),
        );

        await testBox.put('note-1', note1);
        await testBox.put('note-2', note2);

        // Act
        await repository.syncOfflineNotes();

        // Assert - Both users should have their notes
        final doc1 = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('sticky_notes')
            .doc('note-1')
            .get();

        final doc2 = await fakeFirestore
            .collection('users')
            .doc('user-2')
            .collection('sticky_notes')
            .doc('note-2')
            .get();

        expect(doc1.exists, isTrue);
        expect(doc2.exists, isTrue);
      });
    });
  });
}
