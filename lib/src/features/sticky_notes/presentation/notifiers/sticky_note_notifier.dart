import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/providers.dart';
import '../../data/repositories/sticky_note_repository.dart';
import '../../domain/models/sticky_note.dart';

part 'sticky_note_notifier.g.dart';

/// State for the sticky notes list
class StickyNoteState {
  final List<StickyNote> notes;
  final bool isLoading;
  final String? error;

  const StickyNoteState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
  });

  StickyNoteState copyWith({
    List<StickyNote>? notes,
    bool? isLoading,
    String? error,
  }) {
    return StickyNoteState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing sticky notes
@riverpod
class StickyNoteNotifier extends _$StickyNoteNotifier {
  late StickyNoteRepository _repository;

  @override
  StickyNoteState build(String userId) {
    _repository = ref.watch(stickyNoteRepositoryProvider);
    _loadNotes();
    return const StickyNoteState(isLoading: true);
  }

  void _loadNotes() {
    _repository
        .streamNotesForUser(userId)
        .listen(
          (notes) {
            state = StickyNoteState(notes: notes, isLoading: false);
          },
          onError: (error) {
            state = StickyNoteState(error: error.toString(), isLoading: false);
          },
        );
  }

  /// Create a new sticky note
  Future<void> createNote({
    String? title,
    required String content,
    NoteColor color = NoteColor.yellow,
    NotePosition? position,
    int zIndex = 0,
    double width = 300,
    double height = 300,
  }) async {
    try {
      final note = StickyNote(
        id: '', // Let repository generate a proper ID
        title: title,
        content: content,
        color: color,
        position: position ?? NotePosition(x: 50, y: 50),
        userId: userId,
        createdAt: DateTime.now(),
        zIndex: zIndex,
        width: width,
        height: height,
      );

      await _repository.createNote(note);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create note: $e');
      rethrow;
    }
  }

  /// Update an existing sticky note
  Future<void> updateNote(StickyNote note) async {
    try {
      await _repository.updateNote(note);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update note: $e');
      rethrow;
    }
  }

  /// Delete a sticky note
  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete note: $e');
      rethrow;
    }
  }

  /// Update multiple notes (for drag/resize operations)
  Future<void> updateNotes(List<StickyNote> notes) async {
    try {
      await _repository.updateNotes(notes);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update notes: $e');
      rethrow;
    }
  }

  /// Delete multiple notes
  Future<void> deleteNotes(List<String> noteIds) async {
    try {
      await _repository.deleteNotes(noteIds);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete notes: $e');
      rethrow;
    }
  }

  /// Sync offline notes to Firestore
  Future<void> syncOfflineNotes() async {
    try {
      await _repository.syncOfflineNotes();
    } catch (e) {
      state = state.copyWith(error: 'Failed to sync notes: $e');
      rethrow;
    }
  }

  /// Get a specific note by ID
  Future<StickyNote?> getNoteById(String noteId) async {
    try {
      return await _repository.getNoteById(noteId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to get note: $e');
      return null;
    }
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}
