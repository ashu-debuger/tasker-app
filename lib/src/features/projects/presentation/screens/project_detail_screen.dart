import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../shared/date_time_utils.dart' as date_utils;
import '../../../ai/task_suggestions/models/task_suggestion.dart';
import '../../../ai/task_suggestions/models/task_suggestion_request.dart';
import '../../../ai/task_suggestions/presentation/task_suggestion_sheet.dart';
import '../../../settings/presentation/notifiers/reminder_settings_notifier.dart';
import '../../../tasks/domain/models/task.dart';
import '../../../tasks/presentation/providers/task_progress_provider.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../domain/models/project.dart';
import '../notifiers/project_detail_notifier.dart';
import '../notifiers/project_members_notifier.dart';
import '../widgets/member_management_dialog.dart';
import '../widgets/invitation_bottom_sheet.dart';

/// Project detail screen showing tasks and project info
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaskStatus? _filterStatus;
  bool _filterMyTasks = false;
  final _createTaskFormKey = GlobalKey<FormState>();
  final _taskTitleController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
  bool _encryptDescription = false;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  RecurrencePattern _recurrencePattern = RecurrencePattern.none;
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;
  bool _reminderEnabled = true;
  TaskPriority _priority = TaskPriority.medium;
  final List<String> _tags = [];
  final _tagInputController = TextEditingController();
  final Set<String> _autoSyncingTasks = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _showCreateTaskDialog({TaskSuggestion? suggestion}) async {
    _taskTitleController.text = suggestion?.title ?? '';
    _taskDescriptionController.text = suggestion?.description ?? '';
    _encryptDescription = false;
    final suggestedDueDate = suggestion?.recommendedDueDate;
    if (suggestedDueDate != null) {
      _selectedDueDate = DateTime(
        suggestedDueDate.year,
        suggestedDueDate.month,
        suggestedDueDate.day,
      );
      _selectedDueTime = TimeOfDay.fromDateTime(suggestedDueDate);
    } else {
      _selectedDueDate = null;
      _selectedDueTime = null;
    }
    _recurrencePattern = RecurrencePattern.none;
    _recurrenceInterval = 1;
    _recurrenceEndDate = null;
    _reminderEnabled = true;
    _priority = TaskPriority.medium;
    _tags.clear();
    _tagInputController.clear();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Task'),
          content: Form(
            key: _createTaskFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _taskTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'Enter task title',
                      prefixIcon: Icon(Icons.task),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task title';
                      }
                      if (value.trim().length < 2) {
                        return 'Title must be at least 2 characters';
                      }
                      return null;
                    },
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taskDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Enter task description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _encryptDescription,
                    onChanged: (value) {
                      setState(() {
                        _encryptDescription = value ?? false;
                      });
                    },
                    title: Row(
                      children: [
                        Icon(
                          _encryptDescription ? Icons.lock : Icons.lock_open,
                        ),
                        const SizedBox(width: 8),
                        const Text('Encrypt description'),
                      ],
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TaskPriority>(
                        value: _priority,
                        isExpanded: true,
                        items: TaskPriority.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flag,
                                      size: 16,
                                      color: _getPriorityColor(p),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(p.displayName),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _priority = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagInputController,
                              decoration: const InputDecoration(
                                labelText: 'Tags',
                                hintText: 'Add tag and press +',
                                prefixIcon: Icon(Icons.label),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              final tag = _tagInputController.text.trim();
                              if (tag.isNotEmpty && !_tags.contains(tag)) {
                                setState(() {
                                  _tags.add(tag);
                                  _tagInputController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add_circle),
                            tooltip: 'Add tag',
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _tags
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setState(() {
                                      _tags.remove(tag);
                                    });
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    value: _reminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _reminderEnabled = value;
                      });
                    },
                    title: const Text('Enable Reminder'),
                    subtitle: const Text(
                      'Uses global reminder lead time settings',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_reminderEnabled && _selectedDueDate != null)
                    Consumer(
                      builder: (context, ref, child) {
                        final reminderSettings = ref.watch(
                          reminderSettingsProvider,
                        );
                        final leadMinutes = reminderSettings.taskLeadMinutes;
                        final dueDateTime = date_utils.combineDateAndTime(
                          _selectedDueDate,
                          _selectedDueTime,
                        );

                        if (dueDateTime == null) {
                          return const SizedBox.shrink();
                        }

                        final now = DateTime.now();
                        var reminderTime = dueDateTime.subtract(
                          Duration(minutes: leadMinutes),
                        );
                        if (reminderTime.isBefore(now)) {
                          reminderTime = now;
                        }

                        final dateFormat = DateFormat('MMM d, yyyy');
                        final timeFormat = DateFormat('h:mm a');

                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 8,
                            bottom: 8,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.alarm,
                                size: 18,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reminder: ${dateFormat.format(reminderTime)} at ${timeFormat.format(reminderTime)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDueDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          _selectedDueTime = null;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Date (Optional)',
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: _selectedDueDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedDueDate = null;
                                    _selectedDueTime = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      child: Text(
                        _selectedDueDate != null
                            ? DateFormat(
                                'MMM d, yyyy',
                              ).format(_selectedDueDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: _selectedDueDate != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectedDueDate == null
                        ? null
                        : () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  _selectedDueTime ??
                                  TimeOfDay.fromDateTime(DateTime.now()),
                            );
                            if (time != null) {
                              setState(() {
                                _selectedDueTime = time;
                              });
                            }
                          },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Time (Optional)',
                        prefixIcon: const Icon(Icons.access_time),
                        suffixIcon: _selectedDueTime != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: _selectedDueDate == null
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedDueTime = null;
                                        });
                                      },
                              )
                            : null,
                        enabled: _selectedDueDate != null,
                      ),
                      child: Text(
                        _selectedDueDate == null
                            ? 'Select a date first'
                            : _selectedDueTime != null
                            ? _selectedDueTime!.format(context)
                            : 'Select time',
                        style: TextStyle(
                          color: _selectedDueDate == null
                              ? Theme.of(context).hintColor
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Recurrence',
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RecurrencePattern>(
                        value: _recurrencePattern,
                        isExpanded: true,
                        items: RecurrencePattern.values
                            .map(
                              (pattern) => DropdownMenuItem(
                                value: pattern,
                                child: Text(pattern.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _recurrencePattern = value;
                            if (_recurrencePattern == RecurrencePattern.none) {
                              _recurrenceInterval = 1;
                              _recurrenceEndDate = null;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  if (_recurrencePattern != RecurrencePattern.none) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _recurrenceInterval.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Repeat every',
                        prefixIcon: Icon(Icons.repeat_one),
                        suffixText: 'cycle(s)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final number = int.tryParse(value ?? '');
                        if (number == null || number < 1) {
                          return 'Enter a positive number';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        final number = int.tryParse(value);
                        setState(() {
                          _recurrenceInterval = number != null && number > 0
                              ? number
                              : 1;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate:
                              _recurrenceEndDate ??
                              _selectedDueDate ??
                              DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _recurrenceEndDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Repeat until (Optional)',
                          prefixIcon: const Icon(Icons.event_available),
                          suffixIcon: _recurrenceEndDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _recurrenceEndDate = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        child: Text(
                          _recurrenceEndDate != null
                              ? DateFormat(
                                  'MMM d, yyyy',
                                ).format(_recurrenceEndDate!)
                              : 'No end date',
                          style: TextStyle(
                            color: _recurrenceEndDate != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _createTask(dialogContext),
              child: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTask(BuildContext dialogContext) async {
    if (!_createTaskFormKey.currentState!.validate()) return;

    final title = _taskTitleController.text.trim();
    final description = _taskDescriptionController.text.trim();
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();

    final navigator = Navigator.of(dialogContext);
    if (!mounted) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final dueDateTime = _combineDateAndTime(
        _selectedDueDate,
        _selectedDueTime,
      );
      if (dueDateTime != null && !dueDateTime.isAfter(DateTime.now())) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Due date must be in the future.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate recurrence end date
      final normalizedInterval = _recurrencePattern == RecurrencePattern.none
          ? 1
          : _recurrenceInterval;
      final normalizedEndDate = _recurrencePattern == RecurrencePattern.none
          ? null
          : _recurrenceEndDate;
      if (_recurrencePattern != RecurrencePattern.none &&
          dueDateTime != null &&
          normalizedEndDate != null) {
        final dueDateOnly = DateTime(
          dueDateTime.year,
          dueDateTime.month,
          dueDateTime.day,
        );
        final endDateOnly = DateTime(
          normalizedEndDate.year,
          normalizedEndDate.month,
          normalizedEndDate.day,
        );
        if (endDateOnly.isBefore(dueDateOnly)) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Recurrence end date must be on or after the due date.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      await ref
          .read(projectDetailProvider(widget.projectId).notifier)
          .createTask(
            id: taskId,
            title: title,
            description: description.isEmpty ? null : description,
            isDescriptionEncrypted: _encryptDescription,
            dueDate: dueDateTime,
            recurrencePattern: _recurrencePattern,
            recurrenceInterval: normalizedInterval,
            recurrenceEndDate: normalizedEndDate,
            reminderEnabled: _reminderEnabled,
            priority: _priority,
            tags: List.from(_tags),
          );

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Task "$title" created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error creating task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openSuggestionSheet(ProjectDetailState state) {
    final request = _buildSuggestionRequest(state);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => TaskSuggestionSheet(
        request: request,
        onSuggestionAccepted: (suggestion) {
          Navigator.of(sheetContext).pop();
          _showCreateTaskDialog(suggestion: suggestion);
        },
      ),
    );
  }

  TaskSuggestionRequest _buildSuggestionRequest(ProjectDetailState state) {
    final keywords = _extractKeywords(state.tasks).toList(growable: false);
    final recent = state.tasks.take(5).map((task) => task.title).toList();
    final upcomingDueDates =
        state.tasks
            .where((task) => task.dueDate != null)
            .map((task) => task.dueDate!)
            .where((date) => date.isAfter(DateTime.now()))
            .toList()
          ..sort();

    final desiredDue = upcomingDueDates.isNotEmpty
        ? upcomingDueDates.first
        : DateTime.now().add(const Duration(days: 5));

    return TaskSuggestionRequest(
      projectId: state.project!.id,
      projectName: state.project!.name,
      recentTasks: recent,
      keywords: keywords.take(8).toList(),
      desiredDueDate: desiredDue,
      desiredCount: 3,
      focusArea: _filterStatus?.displayName,
    );
  }

  Iterable<String> _extractKeywords(List<Task> tasks) sync* {
    for (final task in tasks) {
      final tokens = task.title
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((token) => token.length > 3);
      yield* tokens;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.completed:
        return Icons.check_circle;
    }
  }

  Widget _buildTasksTab(ProjectDetailState state, List<Task> filteredTasks) {
    return Column(
      children: [
        // Project info card
        if (state.project!.description != null)
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(state.project!.description!),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${state.project!.members.length} members',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.task, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${state.tasks.length} tasks',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Filter indicators
        if (_filterStatus != null || _filterMyTasks)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                if (_filterStatus != null)
                  Chip(
                    avatar: Icon(
                      _getStatusIcon(_filterStatus!),
                      size: 18,
                      color: _getStatusColor(_filterStatus!),
                    ),
                    label: Text('Status: ${_filterStatus!.displayName}'),
                    onDeleted: () {
                      setState(() {
                        _filterStatus = null;
                      });
                    },
                  ),
                if (_filterMyTasks)
                  Chip(
                    avatar: Icon(
                      Icons.person,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: const Text('My Tasks'),
                    onDeleted: () {
                      setState(() {
                        _filterMyTasks = false;
                      });
                    },
                  ),
              ],
            ),
          ),

        // Tasks list
        Expanded(
          child: filteredTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _filterStatus == null
                            ? Icons.task
                            : Icons.filter_list_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filterStatus == null
                            ? 'No tasks yet'
                            : 'No ${_filterStatus!.displayName.toLowerCase()} tasks',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a task to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return _buildTaskCard(task);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMembersTab(ProjectDetailState state) {
    final project = state.project!;
    final currentUser = ref.watch(authProvider).value;
    final membersAsync = ref.watch(projectMembersListProvider(project.id));

    final userRole = currentUser != null
        ? project.getUserRole(currentUser.id)
        : null;
    final canManageMembers = userRole?.isAdmin ?? false;

    return Column(
      children: [
        // Members header with invite button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Team Members',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (canManageMembers) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    showInvitationBottomSheet(
                      context: context,
                      projectId: project.id,
                      projectName: project.name,
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Invite'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => MemberManagementDialog(
                        projectId: project.id,
                        projectOwnerId: project.ownerId,
                      ),
                    );
                  },
                  icon: const Icon(Icons.manage_accounts),
                  tooltip: 'Manage Members',
                ),
              ],
            ],
          ),
        ),

        // Members list
        Expanded(
          child: membersAsync.when(
            data: (members) {
              if (members.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No members yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (canManageMembers) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Invite team members to collaborate',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isCurrentUser = currentUser?.id == member.userId;

                  final role = member.role;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member.photoUrl != null
                            ? NetworkImage(member.photoUrl!)
                            : null,
                        child: member.photoUrl == null
                            ? Text(
                                member.displayName.isNotEmpty
                                    ? member.displayName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(member.displayName)),
                          if (isCurrentUser)
                            const Chip(
                              label: Text('You'),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.email),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                role.icon,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                role.displayName,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading members: ${error.toString()}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectDetailStream = ref.watch(
      projectDetailProvider(widget.projectId),
    );
    final projectDetailValue = projectDetailStream.asData?.value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.projects);
            }
          },
        ),
        title: projectDetailStream.when(
          data: (state) => Text(state.project?.name ?? 'Project'),
          loading: () => const Text('Loading...'),
          error: (error, stackTrace) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high_outlined),
            tooltip: 'AI suggestions',
            onPressed: () {
              final state = projectDetailValue;
              if (state == null || state.project == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project is still loading')),
                );
                return;
              }
              _openSuggestionSheet(state);
            },
          ),
          // Chat button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              final projectName =
                  projectDetailStream.value?.project?.name ?? 'Project';
              context.push(
                '${AppRoutes.projects}/${widget.projectId}/chat?projectName=${Uri.encodeComponent(projectName)}',
              );
            },
            tooltip: 'Project Chat',
          ),
          // Filter menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Tasks',
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  _filterStatus = null;
                  _filterMyTasks = false;
                } else if (value == 'my_tasks') {
                  _filterMyTasks = !_filterMyTasks;
                } else if (value == 'pending') {
                  _filterStatus = TaskStatus.pending;
                } else if (value == 'in_progress') {
                  _filterStatus = TaskStatus.inProgress;
                } else if (value == 'completed') {
                  _filterStatus = TaskStatus.completed;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Tasks')),
              PopupMenuItem(
                value: 'my_tasks',
                child: Row(
                  children: [
                    Icon(
                      _filterMyTasks
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('My Tasks Only'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text('Pending'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'in_progress',
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('In Progress'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text('Completed'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<_ProjectDetailMenuAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Project actions',
            onSelected: (action) {
              if (action == _ProjectDetailMenuAction.delete) {
                _confirmDeleteProject();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ProjectDetailMenuAction.delete,
                child: Row(
                  children: const [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete project'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: projectDetailStream.when(
        data: (state) {
          if (state.project == null) {
            return const Center(child: Text('Project not found'));
          }

          // Apply filters
          var filteredTasks = state.tasks;

          // Filter by status
          if (_filterStatus != null) {
            filteredTasks = filteredTasks
                .where((t) => t.status == _filterStatus)
                .toList();
          }

          // Filter by assigned to current user
          if (_filterMyTasks) {
            final currentUser = ref.watch(authProvider).value;
            if (currentUser != null) {
              filteredTasks = filteredTasks
                  .where((t) => t.assignees.contains(currentUser.id))
                  .toList();
            }
          }

          // For Personal project, show only tasks (no TabBar/Members)
          final isPersonalProject =
              widget.projectId == Project.personalProjectId;

          if (isPersonalProject) {
            return _buildTasksTab(state, filteredTasks);
          }

          return Column(
            children: [
              // TabBar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.task), text: 'Tasks'),
                  Tab(icon: Icon(Icons.people), text: 'Members'),
                ],
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tasks Tab
                    _buildTasksTab(state, filteredTasks),

                    // Members Tab
                    _buildMembersTab(state),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading project',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: projectDetailStream.maybeWhen(
        data: (state) => FloatingActionButton.extended(
          onPressed: () => _showCreateTaskDialog(),
          icon: const Icon(Icons.add),
          label: const Text('New Task'),
        ),
        orElse: () => null,
      ),
    );
  }
}

extension on _ProjectDetailScreenState {
  Widget _buildTaskCard(Task task) {
    final summaryAsync = ref.watch(taskSubtaskSummaryProvider(task.id));

    return summaryAsync.when(
      data: (summary) {
        _syncTaskStatusWithSubtasks(task, summary);
        return _taskTile(task, summary, isToggleEnabled: true);
      },
      loading: () => _taskTile(
        task,
        const TaskSubtaskSummary.loading(),
        isToggleEnabled: false,
      ),
      error: (error, stack) => _taskTile(
        task,
        const TaskSubtaskSummary.empty(),
        isToggleEnabled: true,
      ),
    );
  }

  Widget _taskTile(
    Task task,
    TaskSubtaskSummary summary, {
    required bool isToggleEnabled,
  }) {
    final subtitleChildren = <Widget>[];

    if (task.description != null) {
      subtitleChildren.addAll([
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (task.isDescriptionEncrypted) ...[
              const SizedBox(width: 4),
              Icon(Icons.lock, size: 14, color: Colors.green[600]),
            ],
          ],
        ),
      ]);
    }

    subtitleChildren.addAll([
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          Chip(
            label: Text(
              task.status.displayName,
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: _getStatusColor(
              task.status,
            ).withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Chip(
            avatar: Icon(
              Icons.flag,
              size: 14,
              color: _getPriorityColor(task.priority),
            ),
            label: Text(
              task.priority.displayName,
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: _getPriorityColor(
              task.priority,
            ).withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
      if (task.tags.isNotEmpty) ...[
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: task.tags
              .map(
                (tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                ),
              )
              .toList(),
        ),
      ],
      if (task.dueDate != null) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: task.isOverdue ? Colors.red : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _formatDueDateTime(task.dueDate!),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: task.isOverdue ? Colors.red : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    ]);

    // Show assignees if task is assigned
    if (task.assignees.isNotEmpty) {
      final membersAsync = ref.watch(
        projectMembersListProvider(widget.projectId),
      );
      final assigneeText = membersAsync.maybeWhen(
        data: (members) {
          final assigneeNames = members
              .where((m) => task.assignees.contains(m.userId))
              .map((m) => m.displayName)
              .take(2)
              .join(', ');
          if (task.assignees.length > 2) {
            return '$assigneeNames +${task.assignees.length - 2} more';
          }
          return assigneeNames;
        },
        orElse: () => '${task.assignees.length} assignee(s)',
      );

      subtitleChildren.addAll([
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.person, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                assigneeText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ]);
    }

    if (summary.hasSubtasks) {
      subtitleChildren.addAll([
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              summary.allComplete
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              size: 16,
              color: summary.allComplete ? Colors.green : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${summary.completed}/${summary.total} subtasks complete',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: summary.progress,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              summary.allComplete
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ]);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: task.status == TaskStatus.completed,
          onChanged: isToggleEnabled
              ? (value) {
                  if (value != null) {
                    _handleTaskCompletionToggle(task, summary, value);
                  }
                }
              : null,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: subtitleChildren,
        ),
        trailing: PopupMenuButton<_TaskTileMenuAction>(
          tooltip: 'Task actions',
          onSelected: (action) {
            switch (action) {
              case _TaskTileMenuAction.open:
                context.push(
                  '${AppRoutes.projects}/${widget.projectId}/tasks/${task.id}',
                );
                break;
              case _TaskTileMenuAction.delete:
                _confirmDeleteTask(task);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _TaskTileMenuAction.open,
              child: Row(
                children: const [
                  Icon(Icons.open_in_new),
                  SizedBox(width: 12),
                  Text('Open details'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _TaskTileMenuAction.delete,
              child: Row(
                children: const [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete task'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          context.push(
            '${AppRoutes.projects}/${widget.projectId}/tasks/${task.id}',
          );
        },
      ),
    );
  }

  void _syncTaskStatusWithSubtasks(Task task, TaskSubtaskSummary summary) {
    if (!summary.hasSubtasks) return;
    if (_autoSyncingTasks.contains(task.id)) return;

    final notifier = ref.read(projectDetailProvider(widget.projectId).notifier);

    if (summary.allComplete && task.status != TaskStatus.completed) {
      _autoSyncingTasks.add(task.id);
      notifier
          .updateTask(task.copyWith(status: TaskStatus.completed))
          .whenComplete(() {
            _autoSyncingTasks.remove(task.id);
          });
    } else if (!summary.allComplete && task.status == TaskStatus.completed) {
      final nextStatus = summary.completed == 0
          ? TaskStatus.pending
          : TaskStatus.inProgress;
      _autoSyncingTasks.add(task.id);
      notifier.updateTask(task.copyWith(status: nextStatus)).whenComplete(() {
        _autoSyncingTasks.remove(task.id);
      });
    }
  }

  Future<void> _handleTaskCompletionToggle(
    Task task,
    TaskSubtaskSummary summary,
    bool isChecked,
  ) async {
    final notifier = ref.read(projectDetailProvider(widget.projectId).notifier);

    if (isChecked) {
      if (summary.hasSubtasks && !summary.allComplete) {
        final confirm = await _confirmIncompleteSubtasks(summary.remaining);
        if (!confirm) return;
      }
      await notifier.updateTask(task.copyWith(status: TaskStatus.completed));
    } else {
      final nextStatus = summary.completed > 0
          ? TaskStatus.inProgress
          : TaskStatus.pending;
      await notifier.updateTask(task.copyWith(status: nextStatus));
    }
  }

  Future<bool> _confirmIncompleteSubtasks(int remaining) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subtasks remaining'),
        content: Text(
          remaining == 1
              ? 'There is 1 incomplete subtask. Mark task complete anyway?'
              : 'There are $remaining incomplete subtasks. Mark task complete anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _confirmDeleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}" and all of its subtasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    try {
      await ref
          .read(projectDetailProvider(widget.projectId).notifier)
          .deleteTask(task.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteProject() async {
    final projectName =
        ref
            .read(projectDetailProvider(widget.projectId))
            .value
            ?.project
            ?.name ??
        'this project';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Delete "$projectName" and all of its tasks? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    try {
      await ref
          .read(projectDetailProvider(widget.projectId).notifier)
          .deleteProject();
      if (!mounted) return;
      context.go(AppRoutes.projects);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project "$projectName" deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

enum _ProjectDetailMenuAction { delete }

enum _TaskTileMenuAction { open, delete }

DateTime? _combineDateAndTime(DateTime? date, TimeOfDay? time) {
  return date_utils.combineDateAndTime(date, time);
}

String _formatDueDateTime(DateTime date) {
  return date_utils.formatDueDateTime(date);
}

Color _getPriorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return Colors.grey;
    case TaskPriority.medium:
      return Colors.blue;
    case TaskPriority.high:
      return Colors.orange;
    case TaskPriority.urgent:
      return Colors.red;
  }
}
