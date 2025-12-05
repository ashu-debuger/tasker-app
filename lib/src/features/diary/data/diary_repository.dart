import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../../../core/storage/hive_service.dart';

/// Repository for managing diary entries using Hive local storage
class DiaryRepository {
  final _uuid = const Uuid();

  Box<DiaryEntry> get _box => Hive.box<DiaryEntry>(HiveService.diaryEntriesBox);

  /// Initialize the Hive box (already opened by HiveService)
  Future<void> init() async {
    // Box is already opened by HiveService.init()
  }

  /// Get all diary entries sorted by creation date (newest first)
  List<DiaryEntry> getAllEntries() {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Get a single entry by ID
  DiaryEntry? getEntryById(String id) {
    return _box.values.firstWhere(
      (entry) => entry.id == id,
      orElse: () => throw Exception('Entry not found'),
    );
  }

  /// Search entries by title or body content
  List<DiaryEntry> searchEntries(String query) {
    final lowerQuery = query.toLowerCase();
    final entries = _box.values.where((entry) {
      return entry.title.toLowerCase().contains(lowerQuery) ||
          entry.body.toLowerCase().contains(lowerQuery);
    }).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Get entries by tag
  List<DiaryEntry> getEntriesByTag(String tag) {
    final entries = _box.values.where((entry) {
      return entry.tags.contains(tag);
    }).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Get entries by mood
  List<DiaryEntry> getEntriesByMood(String mood) {
    final entries = _box.values.where((entry) {
      return entry.mood == mood;
    }).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Get entries by date range
  List<DiaryEntry> getEntriesByDateRange(DateTime start, DateTime end) {
    final entries = _box.values.where((entry) {
      return entry.createdAt.isAfter(start) && entry.createdAt.isBefore(end);
    }).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Create a new diary entry
  Future<DiaryEntry> createEntry({
    required String title,
    required String body,
    DateTime? entryDate,
    List<String> tags = const [],
    String? mood,
    String? linkedTaskId,
  }) async {
    final now = DateTime.now();
    final entry = DiaryEntry(
      id: _uuid.v4(),
      title: title,
      body: body,
      entryDate:
          entryDate ??
          DateTime(
            now.year,
            now.month,
            now.day,
          ), // Default to today (date only)
      createdAt: now,
      updatedAt: now,
      tags: tags,
      mood: mood,
      linkedTaskId: linkedTaskId,
    );

    await _box.put(entry.id, entry);
    return entry;
  }

  /// Update an existing diary entry
  Future<DiaryEntry?> updateEntry(
    String id, {
    String? title,
    String? body,
    DateTime? entryDate,
    List<String>? tags,
    String? mood,
    String? linkedTaskId,
  }) async {
    final existingEntry = _box.get(id);
    if (existingEntry == null) return null;

    final updatedEntry = existingEntry.copyWith(
      title: title,
      body: body,
      entryDate: entryDate,
      updatedAt: DateTime.now(),
      tags: tags,
      mood: mood,
      linkedTaskId: linkedTaskId,
    );

    await _box.put(id, updatedEntry);
    return updatedEntry;
  }

  /// Delete a diary entry
  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  /// Delete all diary entries (use with caution)
  Future<void> deleteAllEntries() async {
    await _box.clear();
  }

  /// Get total count of entries
  int getEntryCount() {
    return _box.length;
  }

  /// Export all entries to JSON
  List<Map<String, dynamic>> exportToJson() {
    return _box.values.map((entry) => entry.toJson()).toList();
  }

  /// Import entries from JSON
  Future<void> importFromJson(List<Map<String, dynamic>> jsonList) async {
    for (final json in jsonList) {
      final entry = DiaryEntry.fromJson(json);
      await _box.put(entry.id, entry);
    }
  }
}
