import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/sticky_note.dart';
import '../notifiers/sticky_note_notifier.dart';

/// Rich text editor screen for sticky notes
class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final StickyNote? note;
  final String userId;
  final bool enableNoteSwitcher;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.note,
    required this.userId,
    this.enableNoteSwitcher = false,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late quill.QuillController _controller;
  final _titleController = TextEditingController();
  final _focusNode = FocusNode();
  NoteColor _selectedColor = NoteColor.yellow;
  bool _hasChanges = false;
  StickyNote? _currentNote;
  bool _isHydrating = false;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  void _initializeEditor() {
    _currentNote = widget.note;
    _controller = _buildController(_currentNote);
    _controller.addListener(_onContentChanged);
    _titleController.addListener(_onContentChanged);
    _applyNoteState(_currentNote);
    _updateCharacterCount();
  }

  quill.QuillController _buildController(StickyNote? note) {
    if (note == null) {
      return quill.QuillController.basic();
    }

    try {
      final delta = jsonDecode(note.content) as List;
      return quill.QuillController(
        document: quill.Document.fromJson(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      final controller = quill.QuillController.basic();
      controller.document.insert(0, note.content);
      return controller;
    }
  }

  void _applyNoteState(StickyNote? note) {
    _isHydrating = true;
    _titleController.text = note?.title ?? '';
    _isHydrating = false;
    _selectedColor = note?.color ?? NoteColor.yellow;
    _hasChanges = false;
  }

  void _onContentChanged() {
    _updateCharacterCount();
    if (_isHydrating) return;
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _updateCharacterCount() {
    final text = _controller.document.toPlainText();
    final count = text.trim().length;
    if (_characterCount != count) {
      setState(() {
        _characterCount = count;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _titleController.removeListener(_onContentChanged);
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _saveNote() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Convert Quill document to JSON
      final delta = _controller.document.toDelta();
      final content = jsonEncode(delta.toJson());

      if (_currentNote != null) {
        // Update existing note
        final updatedNote = _currentNote!.copyWith(
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          content: content,
          color: _selectedColor,
        );

        await ref
            .read(stickyNoteProvider(widget.userId).notifier)
            .updateNote(updatedNote);

        messenger.showSnackBar(const SnackBar(content: Text('Note updated')));
      } else {
        // Create new note
        await ref
            .read(stickyNoteProvider(widget.userId).notifier)
            .createNote(
              title: _titleController.text.trim().isEmpty
                  ? null
                  : _titleController.text.trim(),
              content: content,
              color: _selectedColor,
            );

        messenger.showSnackBar(const SnackBar(content: Text('Note created')));
      }

      setState(() => _hasChanges = false);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error saving note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: NoteColor.values.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor == color
                        ? Colors.black
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: _selectedColor == color
                    ? const Icon(Icons.check, color: Colors.black54)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = months[now.month - 1];
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '${now.day} $month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final notesState = widget.enableNoteSwitcher
        ? ref.watch(stickyNoteProvider(widget.userId))
        : null;

    // Use the selected note color for the background
    final backgroundColor = _selectedColor.color;
    final isNoteColorDark =
        ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark;

    // Check if system theme is dark
    final isSystemDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Text color based on note color brightness (for icons and general text)
    final textColor = isNoteColorDark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF202124);
    final hintColor = isNoteColorDark
        ? const Color(0xFF666666)
        : const Color(0xFF9E9E9E);

    // Title text color - white in dark theme for visibility
    final titleTextColor = isSystemDarkMode ? Colors.white : textColor;
    final titleHintColor = isSystemDarkMode ? Colors.white70 : hintColor;

    // Toolbar should consider system theme for its appearance
    // Use dark toolbar styling when system is in dark mode OR when note color is dark
    final isToolbarDark = isSystemDarkMode || isNoteColorDark;

    // Check if keyboard is visible
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: textColor,
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.ios_share),
              color: textColor,
              onPressed: () {
                // Share functionality placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share not implemented yet')),
                );
              },
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.checkroom), // Shirt icon as in screenshot
              color: textColor,
              onPressed: _showColorPicker,
              tooltip: 'Change theme',
            ),
            IconButton(
              icon: const Icon(Icons.check),
              color: textColor,
              onPressed: _saveNote,
              tooltip: 'Save',
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title input
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: titleHintColor,
                      ),
                      contentPadding: const EdgeInsets.only(left: 4),
                    ),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: titleTextColor,
                    ),
                    cursorColor: titleTextColor,
                  ),
                ),

                // Metadata Row (Date | Characters)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _formatCurrentDate(),
                        style: TextStyle(fontSize: 13, color: hintColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '|',
                          style: TextStyle(fontSize: 13, color: hintColor),
                        ),
                      ),
                      Text(
                        '$_characterCount characters',
                        style: TextStyle(fontSize: 13, color: hintColor),
                      ),
                    ],
                  ),
                ),

                // Start typing hint
                if (_characterCount == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Text(
                      'Start typing',
                      style: TextStyle(fontSize: 16, color: hintColor),
                    ),
                  ),

                // Editor
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.apply(
                          bodyColor: textColor,
                          displayColor: textColor,
                        ),
                        textSelectionTheme: TextSelectionThemeData(
                          cursorColor: textColor,
                          selectionColor: textColor.withValues(alpha: 0.3),
                          selectionHandleColor: textColor,
                        ),
                      ),
                      child: quill.QuillEditor.basic(
                        controller: _controller,
                        focusNode: _focusNode,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Floating Toolbar - only visible when keyboard is open
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isKeyboardVisible ? null : 0,
                child: isKeyboardVisible
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            color:
                                (isToolbarDark
                                        ? const Color(0xFF303030)
                                        : Colors.white)
                                    .withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isToolbarDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: quill.QuillSimpleToolbar(
                              controller: _controller,
                              config: quill.QuillSimpleToolbarConfig(
                                showFontFamily: false,
                                showFontSize: false,
                                showSearchButton: false,
                                showInlineCode: false,
                                showSubscript: false,
                                showSuperscript: false,
                                showClipboardCut: false,
                                showClipboardCopy: false,
                                showClipboardPaste: false,
                                headerStyleType: quill.HeaderStyleType.buttons,
                                multiRowsDisplay: false,
                                toolbarIconAlignment: WrapAlignment.center,
                                buttonOptions:
                                    quill.QuillSimpleToolbarButtonOptions(
                                      base: quill.QuillToolbarBaseButtonOptions(
                                        iconTheme: quill.QuillIconTheme(
                                          iconButtonUnselectedData:
                                              quill.IconButtonData(
                                                color: isToolbarDark
                                                    ? Colors.white70
                                                    : Colors.black87,
                                              ),
                                          iconButtonSelectedData:
                                              quill.IconButtonData(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStatePropertyAll(
                                                        isToolbarDark
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  )
                                                            : const Color(
                                                                0xFFE0E0E0,
                                                              ),
                                                      ),
                                                  iconColor:
                                                      WidgetStatePropertyAll(
                                                        isToolbarDark
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        floatingActionButton: widget.enableNoteSwitcher && !isKeyboardVisible
            ? FloatingActionButton.extended(
                onPressed: (notesState == null || notesState.isLoading)
                    ? null
                    : () => _showNoteSwitcher(notesState.notes),
                icon: const Icon(Icons.switch_access_shortcut_add),
                label: const Text('Switch Note'),
                tooltip: 'Open another sticky note',
                backgroundColor: isNoteColorDark
                    ? const Color(0xFF424242)
                    : null,
                foregroundColor: isNoteColorDark ? Colors.white : null,
              )
            : null,
      ),
    );
  }

  Future<void> _showNoteSwitcher(List<StickyNote> notes) async {
    if (!mounted) return;
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved notes to switch to yet.')),
      );
      return;
    }

    final selectedNote = await showModalBottomSheet<StickyNote>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _NoteSwitcherSheet(notes: notes, currentNoteId: _currentNote?.id),
    );

    if (!mounted || selectedNote == null) return;
    _switchToExistingNote(selectedNote);
  }

  void _switchToExistingNote(StickyNote note) {
    final previousController = _controller;
    final newController = _buildController(note);
    newController.addListener(_onContentChanged);

    setState(() {
      _controller = newController;
      _currentNote = note;
      _applyNoteState(note);
    });

    previousController.removeListener(_onContentChanged);
    previousController.dispose();
  }
}

class _NoteSwitcherSheet extends StatelessWidget {
  const _NoteSwitcherSheet({required this.notes, this.currentNoteId});

  final List<StickyNote> notes;
  final String? currentNoteId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height * 0.65;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Switch to another note',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final isCurrent = note.id == currentNoteId;
                  return ListTile(
                    leading: Icon(
                      isCurrent
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isCurrent
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color,
                    ),
                    title: Text(note.title ?? 'Untitled note'),
                    subtitle: Text(
                      _preview(note),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).pop(note),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _preview(StickyNote note) {
    try {
      final delta = jsonDecode(note.content) as List;
      final doc = quill.Document.fromJson(delta);
      final text = doc.toPlainText().trim();
      if (text.isNotEmpty) return text;
    } catch (_) {
      // Fall through to raw content
    }
    return note.content.trim();
  }
}
