import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../../domain/models/sticky_note.dart';
import 'sticky_note_repository.dart';
import '../../../../core/encryption/encryption_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Firebase implementation of StickyNoteRepository with offline-first support
class FirebaseStickyNoteRepository implements StickyNoteRepository {
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;
  final Box<dynamic> _offlineCache;
  static const _logTag = '[Sticky:Repo]';

  FirebaseStickyNoteRepository(
    this._firestore,
    this._encryptionService,
    this._offlineCache,
  );

  /// Collection reference for sticky notes
  CollectionReference _notesCollectionForUser(String userId) =>
      _firestore.collection('users').doc(userId).collection('sticky_notes');

  @override
  Future<StickyNote?> getNoteById(String noteId) async {
    appLogger.d('$_logTag getNoteById noteId=$noteId');
    try {
      // Check offline cache first
      if (_offlineCache.containsKey(noteId)) {
        final cachedNote = _offlineCache.get(noteId);
        if (cachedNote is StickyNote) {
          final decrypted = await _decryptNoteContent(
            cachedNote,
            context: 'getNoteById-cache',
          );
          appLogger.d('$_logTag getNoteById cache hit noteId=$noteId');
          return decrypted;
        }
      }

      // Try to fetch from Firebase (will use local cache if offline)
      final userId =
          _offlineCache.values.whereType<StickyNote>().firstOrNull?.userId ?? '';
      if (userId.isNotEmpty) {
        final doc = await logTimedAsync(
          '$_logTag getNote doc noteId=$noteId',
          () => _notesCollectionForUser(userId).doc(noteId).get(),
          level: Level.debug,
        );
        if (doc.exists) {
          var note = StickyNote.fromJson(doc.data() as Map<String, dynamic>);
          note = await _decryptNoteContent(note, context: 'getNoteById');
          await _offlineCache.put(noteId, note);
          appLogger.i('$_logTag getNoteById success noteId=$noteId source=remote');
          return note;
        }
      }

      return null;
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag getNoteById failed noteId=$noteId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<StickyNote>> streamNotesForUser(String userId) {
    try {
      appLogger.d('$_logTag streamNotesForUser subscribed userId=$userId');
      return _notesCollectionForUser(
        userId,
      ).orderBy('zIndex', descending: false).snapshots().asyncMap((
        snapshot,
      ) async {
        final notes = <StickyNote>[];
        for (final doc in snapshot.docs) {
          var note = StickyNote.fromJson(doc.data() as Map<String, dynamic>);
          note = await _decryptNoteContent(note, context: 'streamNotes');
          notes.add(note);
          await _offlineCache.put(note.id, note);
        }
        appLogger.d(
          '$_logTag streamNotesForUser snapshot=${notes.length} userId=$userId',
        );
        return notes;
      });
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag streamNotesForUser failed userId=$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> createNote(StickyNote note) async {
    try {
      if (note.userId.isEmpty) {
        throw ArgumentError(
          'StickyNote.userId must not be empty when creating a note.',
        );
      }

      appLogger.i('$_logTag createNote requested userId=${note.userId}');
      final notesCollection = _notesCollectionForUser(note.userId);

      // Generate an ID if empty to avoid invalid Firestore document paths
      final String id = note.id.isEmpty ? notesCollection.doc().id : note.id;

      // Encrypt content before storing
      final encryptedContent = await _encryptContent(
        note.content,
        noteId: id,
        context: 'createNote',
      );

      final encryptedNote = note.copyWith(id: id, content: encryptedContent);

      // Save to offline cache first (with encrypted content)
      await _offlineCache.put(id, encryptedNote);

      // Sync to Firebase (Firestore handles offline automatically)
      await logTimedAsync(
        '$_logTag createNote write noteId=$id',
        () => notesCollection.doc(id).set(encryptedNote.toJson()),
      );
      appLogger.i('$_logTag createNote success noteId=$id');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag createNote failed userId=${note.userId}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateNote(StickyNote note) async {
    try {
      appLogger.i('$_logTag updateNote requested noteId=${note.id}');

      // Encrypt content before storing
      final encryptedContent = await _encryptContent(
        note.content,
        noteId: note.id,
        context: 'updateNote',
      );

      final updatedNote = note.copyWith(
        content: encryptedContent,
        updatedAt: DateTime.now(),
      );

      // Update offline cache first
      await _offlineCache.put(note.id, updatedNote);

      // Sync to Firebase (Firestore handles offline automatically)
      await logTimedAsync(
        '$_logTag updateNote write noteId=${note.id}',
        () => _notesCollectionForUser(note.userId)
            .doc(note.id)
            .update(updatedNote.toJson()),
      );
      appLogger.i('$_logTag updateNote success noteId=${note.id}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag updateNote failed noteId=${note.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    try {
      appLogger.w('$_logTag deleteNote requested noteId=$noteId');
      final note = _offlineCache.get(noteId);
      if (note == null) return;

      // Delete from offline cache
      await _offlineCache.delete(noteId);

      // Delete from Firebase (Firestore handles offline automatically)
      await logTimedAsync(
        '$_logTag deleteNote write noteId=$noteId',
        () => _notesCollectionForUser(note.userId).doc(noteId).delete(),
      );
      appLogger.i('$_logTag deleteNote success noteId=$noteId');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteNote failed noteId=$noteId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateNotes(List<StickyNote> notes) async {
    try {
      appLogger.i('$_logTag updateNotes batchCount=${notes.length}');
      // Update all notes in cache first
      for (final note in notes) {
        final updatedNote = note.copyWith(updatedAt: DateTime.now());
        await _offlineCache.put(note.id, updatedNote);
      }

      // Batch update in Firebase (Firestore handles offline automatically)
      if (notes.isNotEmpty) {
        final batch = _firestore.batch();
        for (final note in notes) {
          final updatedNote = note.copyWith(updatedAt: DateTime.now());
          batch.update(
            _notesCollectionForUser(note.userId).doc(note.id),
            updatedNote.toJson(),
          );
        }
        await logTimedAsync(
          '$_logTag updateNotes batch commit count=${notes.length}',
          () => batch.commit(),
        );
        appLogger.i('$_logTag updateNotes batch success count=${notes.length}');
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag updateNotes failed count=${notes.length}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteNotes(List<String> noteIds) async {
    try {
      appLogger.w('$_logTag deleteNotes batchCount=${noteIds.length}');
      // Collect notes before deletion for userId
        final notes = noteIds
          .map((id) => _offlineCache.get(id))
          .whereType<StickyNote>()
          .toList();

      // Delete from cache
      await _offlineCache.deleteAll(noteIds);

      // Batch delete from Firebase (Firestore handles offline automatically)
      if (notes.isNotEmpty) {
        final batch = _firestore.batch();
        for (final note in notes) {
          batch.delete(_notesCollectionForUser(note.userId).doc(note.id));
        }
        await logTimedAsync(
          '$_logTag deleteNotes batch commit count=${notes.length}',
          () => batch.commit(),
        );
        appLogger.i('$_logTag deleteNotes success deleted=${notes.length}');
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag deleteNotes failed count=${noteIds.length}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> syncOfflineNotes() async {
    try {
      final cachedNotes = _offlineCache.values.whereType<StickyNote>().toList();
      if (cachedNotes.isEmpty) return;
      appLogger.i('$_logTag syncOfflineNotes cached=${cachedNotes.length}');

      // Group notes by userId
      final notesByUser = <String, List<StickyNote>>{};
      for (final note in cachedNotes) {
        notesByUser.putIfAbsent(note.userId, () => []).add(note);
      }

      // Sync each user's notes
      for (final entry in notesByUser.entries) {
        final userId = entry.key;
        final userNotes = entry.value;

        final batch = _firestore.batch();
        for (final note in userNotes) {
          batch.set(
            _notesCollectionForUser(userId).doc(note.id),
            note.toJson(),
          );
        }
        await logTimedAsync(
          '$_logTag syncOfflineNotes batch userId=$userId count=${userNotes.length}',
          () => batch.commit(),
        );
      }
      appLogger.i('$_logTag syncOfflineNotes success groups=${notesByUser.length}');
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag syncOfflineNotes failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<StickyNote> _decryptNoteContent(
    StickyNote note, {
    required String context,
  }) async {
    if (note.content.isEmpty) return note;
    try {
      final decrypted = await _encryptionService.decrypt(note.content);
      return note.copyWith(content: decrypted);
    } catch (e, stackTrace) {
      appLogger.w(
        '$_logTag $context decrypt failed noteId=${note.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return note;
    }
  }

  Future<String> _encryptContent(
    String content, {
    required String noteId,
    required String context,
  }) async {
    if (content.isEmpty) return content;
    try {
      return await logTimedAsync(
        '$_logTag $context encrypt noteId=$noteId',
        () => _encryptionService.encrypt(content),
        level: Level.debug,
      );
    } catch (e, stackTrace) {
      appLogger.e(
        '$_logTag $context encrypt failed noteId=$noteId',
        error: e,
        stackTrace: stackTrace,
      );
      return content;
    }
  }
}
