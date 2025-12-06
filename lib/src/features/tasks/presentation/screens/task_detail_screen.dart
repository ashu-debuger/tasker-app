import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../notifiers/task_detail_notifier.dart';
import '../../domain/models/task.dart';
import '../../domain/models/subtask.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/date_time_utils.dart' as date_utils;
import '../widgets/task_assignment_dialog.dart';
import '../../../projects/presentation/notifiers/project_members_notifier.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../projects/domain/models/project_role.dart';

/// Task detail screen showing subtasks and task info
class TaskDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _createSubtaskFormKey = GlobalKey<FormState>();
  final _subtaskTitleController = TextEditingController();
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editRecurrenceIntervalController =
      TextEditingController();

  @override
  void dispose() {
    _subtaskTitleController.dispose();
    _editTitleController.dispose();
    _editRecurrenceIntervalController.dispose();
    super.dispose();
  }

  Future<void> _showCreateSubtaskDialog() async {
    _subtaskTitleController.clear();

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Subtask'),
          content: Form(
            key: _createSubtaskFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _subtaskTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtask Title',
                    hintText: 'Enter subtask title',
                    prefixIcon: Icon(Icons.check_box_outline_blank),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subtask title';
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
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                        );
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date (Optional)',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: selectedDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  selectedDate = null;
                                  selectedTime = null;
                                });
                              },
                            )
                          : null,
                    ),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('MMM d, yyyy').format(selectedDate!)
                          : 'Select date',
                      style: TextStyle(
                        color: selectedDate != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: selectedDate == null
                      ? null
                      : () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime:
                                selectedTime ??
                                TimeOfDay.fromDateTime(DateTime.now()),
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = time;
                            });
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Time (Optional)',
                      prefixIcon: const Icon(Icons.access_time),
                      suffixIcon: selectedTime != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: selectedDate == null
                                  ? null
                                  : () {
                                      setState(() {
                                        selectedTime = null;
                                      });
                                    },
                            )
                          : null,
                      enabled: selectedDate != null,
                    ),
                    child: Text(
                      selectedDate == null
                          ? 'Select a date first'
                          : selectedTime != null
                          ? selectedTime!.format(context)
                          : 'Select time',
                      style: TextStyle(
                        color: selectedDate == null
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _createSubtask(
                context,
                _combineDateAndTime(selectedDate, selectedTime),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSubtask(
    BuildContext dialogContext,
    DateTime? dueDate,
  ) async {
    if (!_createSubtaskFormKey.currentState!.validate()) return;

    final title = _subtaskTitleController.text.trim();
    final subtaskId = DateTime.now().millisecondsSinceEpoch.toString();

    final navigator = Navigator.of(dialogContext);

    // Validate future date
    final validationError = date_utils.validateFutureDateTime(dueDate);
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await ref
          .read(taskDetailProvider(widget.taskId).notifier)
          .createSubtask(id: subtaskId, title: title, dueDate: dueDate);

      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subtask "$title" added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding subtask: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditTaskDialog(Task task) async {
    final formKey = GlobalKey<FormState>();
    final titleController = _editTitleController;
    final recurrenceIntervalController = _editRecurrenceIntervalController;
    titleController.text = task.title;
    recurrenceIntervalController.text = task.recurrenceInterval.toString();
    DateTime? selectedDueDate = task.dueDate != null
        ? DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day)
        : null;
    TimeOfDay? selectedDueTime = task.dueDate != null
        ? TimeOfDay.fromDateTime(task.dueDate!)
        : null;
    RecurrencePattern recurrencePattern = task.recurrencePattern;
    DateTime? recurrenceEndDate = task.recurrenceEndDate;
    bool reminderEnabled = task.reminderEnabled;
    var recurrenceInterval = task.recurrenceInterval;
    TaskPriority priority = task.priority;
    List<String> tags = List.from(task.tags);
    final tagInputController = TextEditingController();

    Future<void> saveChanges(BuildContext dialogContext) async {
      if (!formKey.currentState!.validate()) return;

      final updatedTitle = titleController.text.trim();
      final normalizedInterval = recurrencePattern == RecurrencePattern.none
          ? 1
          : recurrenceInterval;
      final normalizedEndDate = recurrencePattern == RecurrencePattern.none
          ? null
          : recurrenceEndDate;
      final updatedDueDate = _combineDateAndTime(
        selectedDueDate,
        selectedDueTime,
      );

      if (updatedDueDate != null && !updatedDueDate.isAfter(DateTime.now())) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Due date must be in the future.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updatedTask = task.copyWith(
        title: updatedTitle,
        dueDate: updatedDueDate,
        recurrencePattern: recurrencePattern,
        recurrenceInterval: normalizedInterval,
        recurrenceEndDate: normalizedEndDate,
        reminderEnabled: reminderEnabled,
        priority: priority,
        tags: tags,
      );

      final navigator = Navigator.of(dialogContext);

      try {
        await ref
            .read(taskDetailProvider(widget.taskId).notifier)
            .updateTask(updatedTask);
        navigator.pop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "$updatedTitle" updated'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Task'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleController,
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
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TaskPriority>(
                        value: priority,
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
                            priority = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDueDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Date (Optional)',
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: selectedDueDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    selectedDueDate = null;
                                    selectedDueTime = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      child: Text(
                        selectedDueDate != null
                            ? DateFormat('MMM d, yyyy').format(selectedDueDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: selectedDueDate != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: selectedDueDate == null
                        ? null
                        : () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  selectedDueTime ??
                                  TimeOfDay.fromDateTime(DateTime.now()),
                            );
                            if (time != null) {
                              setState(() {
                                selectedDueTime = time;
                              });
                            }
                          },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Time (Optional)',
                        prefixIcon: const Icon(Icons.access_time),
                        suffixIcon: selectedDueTime != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: selectedDueDate == null
                                    ? null
                                    : () {
                                        setState(() {
                                          selectedDueTime = null;
                                        });
                                      },
                              )
                            : null,
                        enabled: selectedDueDate != null,
                      ),
                      child: Text(
                        selectedDueDate == null
                            ? 'Select a date first'
                            : selectedDueTime != null
                            ? selectedDueTime!.format(context)
                            : 'Select time',
                        style: TextStyle(
                          color: selectedDueDate == null
                              ? Theme.of(context).hintColor
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    value: reminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        reminderEnabled = value;
                      });
                    },
                    title: const Text('Enable Reminder'),
                    subtitle: const Text(
                      'Uses global reminder lead time settings',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: tagInputController,
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
                              final tag = tagInputController.text.trim();
                              if (tag.isNotEmpty && !tags.contains(tag)) {
                                setState(() {
                                  tags.add(tag);
                                  tagInputController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add_circle),
                            tooltip: 'Add tag',
                          ),
                        ],
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: tags
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setState(() {
                                      tags.remove(tag);
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
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Recurrence',
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RecurrencePattern>(
                        value: recurrencePattern,
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
                            recurrencePattern = value;
                            if (recurrencePattern == RecurrencePattern.none) {
                              recurrenceInterval = 1;
                              recurrenceIntervalController.text = '1';
                              recurrenceEndDate = null;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  if (recurrencePattern != RecurrencePattern.none) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: recurrenceIntervalController,
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
                        recurrenceInterval = number != null && number > 0
                            ? number
                            : 1;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate:
                              recurrenceEndDate ??
                              selectedDueDate ??
                              DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            recurrenceEndDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Repeat until (Optional)',
                          prefixIcon: const Icon(Icons.event_available),
                          suffixIcon: recurrenceEndDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      recurrenceEndDate = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        child: Text(
                          recurrenceEndDate != null
                              ? DateFormat(
                                  'MMM d, yyyy',
                                ).format(recurrenceEndDate!)
                              : 'No end date',
                          style: TextStyle(
                            color: recurrenceEndDate != null
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
              onPressed: () => saveChanges(dialogContext),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    try {
      await ref
          .read(taskDetailProvider(widget.taskId).notifier)
          .toggleSubtaskCompletion(subtask.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating subtask: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSubtask(Subtask subtask) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subtask'),
        content: Text('Are you sure you want to delete "${subtask.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(taskDetailProvider(widget.taskId).notifier)
          .deleteSubtask(subtask.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subtask "${subtask.title}" deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting subtask: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showAssignmentDialog(Task task) async {
    await showDialog(
      context: context,
      builder: (context) =>
          TaskAssignmentDialog(projectId: widget.projectId, task: task),
    );
  }

  Widget _buildAssigneesList(Task task) {
    final membersAsync = ref.watch(
      projectMembersListProvider(widget.projectId),
    );

    return membersAsync.when(
      data: (members) {
        // Filter members who are assigned to this task
        final assignedMembers = members
            .where((member) => task.assignees.contains(member.userId))
            .toList();

        if (assignedMembers.isEmpty) {
          return Text(
            'No one assigned',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: assignedMembers.map((member) {
            return Chip(
              avatar: member.photoUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(member.photoUrl!),
                    )
                  : CircleAvatar(
                      child: Text(
                        member.displayName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
              label: Text(member.displayName),
              labelStyle: const TextStyle(fontSize: 13),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => Text(
        'Error loading assignees',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> _updateTaskStatus(TaskStatus newStatus) async {
    try {
      await ref
          .read(taskDetailProvider(widget.taskId).notifier)
          .updateTaskStatus(newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task status updated to ${newStatus.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task status: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final taskDetailStream = ref.watch(taskDetailProvider(widget.taskId));
    final currentUser = ref.watch(authProvider).value;
    final roleAsync = currentUser != null
        ? ref.watch(memberRoleProvider(widget.projectId, currentUser.id))
        : const AsyncValue<ProjectRole?>.data(null);
    final currentRole = roleAsync.asData?.value;
    final canEdit = currentRole?.canEdit ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('${AppRoutes.projects}/${widget.projectId}');
            }
          },
        ),
        title: taskDetailStream.when(
          data: (state) {
            if (state.task != null) {
              return Text(state.task!.title);
            }
            if (state.error != null) {
              return const Text('Error');
            }
            return const Text('Loading...');
          },
          loading: () => const Text('Loading...'),
          error: (error, stackTrace) => const Text('Error'),
        ),
        actions: [
          taskDetailStream.maybeWhen(
            data: (state) {
              if (state.task == null) return const SizedBox.shrink();
              if (!canEdit) return const SizedBox.shrink();
              return PopupMenuButton<TaskStatus>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Update Status',
                onSelected: _updateTaskStatus,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: TaskStatus.pending,
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        const Text('Mark as Pending'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TaskStatus.inProgress,
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Mark as In Progress'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TaskStatus.completed,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        const Text('Mark as Completed'),
                      ],
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          taskDetailStream.maybeWhen(
            data: (state) {
              if (state.task == null) return const SizedBox.shrink();
              if (!canEdit) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit task',
                onPressed: () => _showEditTaskDialog(state.task!),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          taskDetailStream.maybeWhen(
            data: (state) {
              if (state.task == null) return const SizedBox.shrink();
              if (!canEdit) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete task',
                onPressed: () => _confirmDeleteTask(state.task!),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: taskDetailStream.when(
        data: (state) {
          if (state.task == null) {
            if (state.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          }

          final task = state.task!;
          final subtasks = state.subtasks;
          final completionPercentage = state.completionPercentage;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Task info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                task.status,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(task.status),
                                  color: _getStatusColor(task.status),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  task.status.displayName,
                                  style: TextStyle(
                                    color: _getStatusColor(task.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                task.priority,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: _getPriorityColor(task.priority),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  task.priority.displayName,
                                  style: TextStyle(
                                    color: _getPriorityColor(task.priority),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (task.dueDate != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: task.isOverdue
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDueDateTime(task.dueDate!),
                                  style: TextStyle(
                                    color: task.isOverdue
                                        ? Colors.red
                                        : Colors.grey[600],
                                    fontWeight: task.isOverdue
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Description
                      if (task.description != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                            ),
                            if (task.isDescriptionEncrypted) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Encrypted',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],

                      // Assignment section
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Assigned to',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: canEdit
                                ? () => _showAssignmentDialog(task)
                                : null,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: Text(
                              task.assignees.isEmpty ? 'Assign' : 'Reassign',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (task.assignees.isEmpty)
                        Text(
                          'No one assigned',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                        )
                      else
                        _buildAssigneesList(task),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$completionPercentage%',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: completionPercentage == 100
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: completionPercentage / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(
                            completionPercentage == 100
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${subtasks.where((s) => s.isCompleted).length} of ${subtasks.length} subtasks completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subtasks header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtasks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: canEdit ? _showCreateSubtaskDialog : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Subtasks list
              if (subtasks.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.checklist,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No subtasks yet',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Break down this task into smaller steps',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...subtasks.map((subtask) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Checkbox(
                        value: subtask.isCompleted,
                        onChanged: canEdit
                            ? (value) => _toggleSubtask(subtask)
                            : null,
                      ),
                      title: Text(
                        subtask.title,
                        style: TextStyle(
                          decoration: subtask.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: subtask.isCompleted ? Colors.grey[600] : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created ${_formatDate(subtask.createdAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (subtask.dueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: _isSubtaskOverdue(subtask)
                                        ? Colors.red
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due ${_formatDueDateTime(subtask.dueDate!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isSubtaskOverdue(subtask)
                                          ? Colors.red
                                          : Colors.grey[600],
                                      fontWeight: _isSubtaskOverdue(subtask)
                                          ? FontWeight.w600
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: canEdit
                            ? () => _deleteSubtask(subtask)
                            : null,
                        color: Colors.red[300],
                        tooltip: 'Delete subtask',
                      ),
                      onTap: canEdit ? () => _toggleSubtask(subtask) : null,
                    ),
                  );
                }),
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
                'Error loading task',
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
    );
  }

  DateTime? _combineDateAndTime(DateTime? date, TimeOfDay? time) {
    return date_utils.combineDateAndTime(date, time);
  }

  String _formatDueDateTime(DateTime date) {
    return date_utils.formatDueDateTime(date);
  }

  bool _isSubtaskOverdue(Subtask subtask) {
    if (subtask.dueDate == null || subtask.isCompleted) return false;
    return subtask.dueDate!.isBefore(DateTime.now());
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _confirmDeleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}" and all subtasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(taskDetailProvider(widget.taskId).notifier).deleteTask();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" deleted'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('${AppRoutes.projects}/${widget.projectId}');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
