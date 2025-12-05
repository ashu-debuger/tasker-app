import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/diary_repository.dart';
import '../models/diary_entry.dart';

part 'diary_notifier.g.dart';

/// Provider for DiaryRepository instance
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository();
});

/// State class for diary entries
class DiaryState {
  final List<DiaryEntry> entries;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  DiaryState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  DiaryState copyWith({
    List<DiaryEntry>? entries,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return DiaryState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier for managing diary state
@riverpod
class Diary extends _$Diary {
  late DiaryRepository _repository;

  @override
  DiaryState build() {
    _repository = ref.read(diaryRepositoryProvider);
    _initialize();
    return DiaryState();
  }

  /// Initialize repository and load entries
  Future<void> _initialize() async {
    try {
      await _repository.init();
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize: $e');
    }
  }

  /// Load all entries
  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true);
    try {
      final entries = _repository.getAllEntries();
      state = state.copyWith(entries: entries, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load entries: $e',
      );
    }
  }

  /// Create a new entry
  Future<DiaryEntry?> createEntry({
    required String title,
    required String body,
    DateTime? entryDate,
    List<String> tags = const [],
    String? mood,
    String? linkedTaskId,
  }) async {
    try {
      final entry = await _repository.createEntry(
        title: title,
        body: body,
        entryDate: entryDate,
        tags: tags,
        mood: mood,
        linkedTaskId: linkedTaskId,
      );
      await loadEntries(); // Refresh list
      return entry;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create entry: $e');
      return null;
    }
  }

  /// Update an existing entry
  Future<bool> updateEntry(
    String id, {
    String? title,
    String? body,
    DateTime? entryDate,
    List<String>? tags,
    String? mood,
    String? linkedTaskId,
  }) async {
    try {
      final updatedEntry = await _repository.updateEntry(
        id,
        title: title,
        body: body,
        entryDate: entryDate,
        tags: tags,
        mood: mood,
        linkedTaskId: linkedTaskId,
      );
      if (updatedEntry != null) {
        await loadEntries(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update entry: $e');
      return false;
    }
  }

  /// Delete an entry
  Future<bool> deleteEntry(String id) async {
    try {
      await _repository.deleteEntry(id);
      await loadEntries(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete entry: $e');
      return false;
    }
  }

  /// Search entries
  Future<void> searchEntries(String query) async {
    state = state.copyWith(searchQuery: query);
    if (query.isEmpty) {
      await loadEntries();
      return;
    }

    try {
      final entries = _repository.searchEntries(query);
      state = state.copyWith(entries: entries, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Search failed: $e');
    }
  }

  /// Filter entries by tag
  Future<void> filterByTag(String tag) async {
    try {
      final entries = _repository.getEntriesByTag(tag);
      state = state.copyWith(entries: entries, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Filter failed: $e');
    }
  }

  /// Filter entries by mood
  Future<void> filterByMood(String mood) async {
    try {
      final entries = _repository.getEntriesByMood(mood);
      state = state.copyWith(entries: entries, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Filter failed: $e');
    }
  }

  /// Filter entries by date range
  Future<void> filterByDateRange(DateTime start, DateTime end) async {
    try {
      final entries = _repository.getEntriesByDateRange(start, end);
      state = state.copyWith(entries: entries, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Filter failed: $e');
    }
  }

  /// Get entry by ID
  DiaryEntry? getEntryById(String id) {
    try {
      return _repository.getEntryById(id);
    } catch (e) {
      state = state.copyWith(error: 'Entry not found: $e');
      return null;
    }
  }

  /// Clear search/filters
  Future<void> clearFilters() async {
    state = state.copyWith(searchQuery: '');
    await loadEntries();
  }

  /// Export entries to JSON
  List<Map<String, dynamic>> exportEntries() {
    return _repository.exportToJson();
  }

  /// Import entries from JSON
  Future<void> importEntries(List<Map<String, dynamic>> jsonList) async {
    try {
      await _repository.importFromJson(jsonList);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: 'Import failed: $e');
    }
  }
}
