import '../../domain/models/sticky_note.dart';

/// Repository interface for sticky note operations
abstract class StickyNoteRepository {
  /// Get a sticky note by ID
  Future<StickyNote?> getNoteById(String noteId);

  /// Stream all sticky notes for a user
  Stream<List<StickyNote>> streamNotesForUser(String userId);

  /// Create a new sticky note
  Future<void> createNote(StickyNote note);

  /// Update an existing sticky note
  Future<void> updateNote(StickyNote note);

  /// Delete a sticky note
  Future<void> deleteNote(String noteId);

  /// Batch update multiple notes (for position changes)
  Future<void> updateNotes(List<StickyNote> notes);

  /// Delete multiple notes
  Future<void> deleteNotes(List<String> noteIds);

  /// Sync offline notes with Firebase
  Future<void> syncOfflineNotes();
}
