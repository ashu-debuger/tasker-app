import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import '../../domain/models/sticky_note.dart';
import '../notifiers/sticky_note_notifier.dart';

/// Main screen displaying sticky notes in a masonry grid layout
class StickyNotesGridScreen extends ConsumerStatefulWidget {
  final String userId;

  const StickyNotesGridScreen({super.key, required this.userId});

  @override
  ConsumerState<StickyNotesGridScreen> createState() =>
      _StickyNotesGridScreenState();
}

class _StickyNotesGridScreenState extends ConsumerState<StickyNotesGridScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  NoteColor? _selectedColorFilter;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StickyNote> _filterNotes(List<StickyNote> notes) {
    var filtered = notes;

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((note) {
        final title = note.title?.toLowerCase() ?? '';
        final content = _getPlainTextContent(note).toLowerCase();
        return title.contains(query) || content.contains(query);
      }).toList();
    }

    // Apply color filter
    if (_selectedColorFilter != null) {
      filtered = filtered
          .where((note) => note.color == _selectedColorFilter)
          .toList();
    }

    return filtered;
  }

  String _getPlainTextContent(StickyNote note) {
    try {
      final delta = jsonDecode(note.content) as List;
      final doc = quill.Document.fromJson(delta);
      return doc.toPlainText().trim();
    } catch (e) {
      return note.content.trim();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedColorFilter = null;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(stickyNoteProvider(widget.userId));
    final filteredNotes = notesState.notes.isEmpty
        ? <StickyNote>[]
        : _filterNotes(notesState.notes);
    final hasActiveFilters =
        _searchQuery.isNotEmpty || _selectedColorFilter != null;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text('Sticky Notes'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                } else {
                  setState(() => _isSearching = false);
                }
              },
              tooltip: 'Clear search',
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = true);
              },
              tooltip: 'Search notes',
            ),
        ],
      ),
      body: notesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notesState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notesState.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(stickyNoteProvider(widget.userId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Color filter chips
                if (notesState.notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // All notes chip
                          FilterChip(
                            label: Text('All (${notesState.notes.length})'),
                            selected:
                                _selectedColorFilter == null &&
                                !hasActiveFilters,
                            onSelected: (selected) {
                              setState(() {
                                _selectedColorFilter = null;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          // Color filter chips
                          ...NoteColor.values.map((color) {
                            final count = notesState.notes
                                .where((n) => n.color == color)
                                .length;
                            if (count == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text('${color.name} ($count)'),
                                selected: _selectedColorFilter == color,
                                backgroundColor: color.color.withValues(
                                  alpha: 0.3,
                                ),
                                selectedColor: color.color,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedColorFilter = selected
                                        ? color
                                        : null;
                                  });
                                },
                              ),
                            );
                          }),
                          // Clear filters button
                          if (hasActiveFilters)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ActionChip(
                                label: const Text('Clear filters'),
                                avatar: const Icon(Icons.clear, size: 18),
                                onPressed: _clearFilters,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Notes grid or empty state
                Expanded(
                  child: filteredNotes.isEmpty && hasActiveFilters
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notes found',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear all filters'),
                              ),
                            ],
                          ),
                        )
                      : notesState.notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sticky_note_2_outlined,
                                size: 120,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No sticky notes yet',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to create your first note',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : MasonryGridView.count(
                          crossAxisCount: _getCrossAxisCount(context),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            return NoteCard(
                              note: note,
                              onTap: () => _navigateToEditor(context, note),
                              onDelete: () =>
                                  _confirmDelete(context, ref, note),
                              searchQuery: _searchQuery,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  void _navigateToEditor(BuildContext context, StickyNote? note) {
    context.push(
      '/sticky-notes/editor',
      extra: {'userId': widget.userId, 'note': note},
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    StickyNote note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
          note.title != null
              ? 'Are you sure you want to delete "${note.title}"?'
              : 'Are you sure you want to delete this note?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(stickyNoteProvider(widget.userId).notifier)
            .deleteNote(note.id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Note deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting note: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Card widget for displaying a single sticky note
class NoteCard extends StatelessWidget {
  final StickyNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String searchQuery;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final contentPreview = _getContentPreview();

    return Card(
      color: note.color.color,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: note.title != null
                        ? Text(
                            note.title!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.black54,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                    tooltip: 'Delete note',
                  ),
                ],
              ),

              if (note.title != null) const SizedBox(height: 8),

              // Content preview
              if (contentPreview.isNotEmpty)
                Text(
                  contentPreview,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Footer with timestamp
              Text(
                _formatDate(note.updatedAt ?? note.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getContentPreview() {
    try {
      // Try to parse as Quill Delta JSON
      final delta = jsonDecode(note.content) as List;
      final doc = quill.Document.fromJson(delta);
      return doc.toPlainText().trim();
    } catch (e) {
      // Fallback to plain text
      return note.content.trim();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
