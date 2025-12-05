import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/presentation/notifiers/project_members_notifier.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../domain/models/task.dart';
import '../notifiers/task_detail_notifier.dart';

/// Dialog for assigning tasks to project members
class TaskAssignmentDialog extends ConsumerStatefulWidget {
  final String projectId;
  final Task task;

  const TaskAssignmentDialog({
    super.key,
    required this.projectId,
    required this.task,
  });

  @override
  ConsumerState<TaskAssignmentDialog> createState() =>
      _TaskAssignmentDialogState();
}

class _TaskAssignmentDialogState extends ConsumerState<TaskAssignmentDialog> {
  final Set<String> _selectedAssignees = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current assignees
    _selectedAssignees.addAll(widget.task.assignees);
  }

  Future<void> _saveAssignment() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authProvider).value;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final taskNotifier = ref.read(
        taskDetailProvider(widget.task.id).notifier,
      );

      if (_selectedAssignees.isEmpty) {
        // Unassign task
        await taskNotifier.unassignTask(widget.task.id);
      } else {
        // Assign task
        await taskNotifier.assignTask(
          taskId: widget.task.id,
          assigneeIds: _selectedAssignees.toList(),
          assignedBy: currentUser.id,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedAssignees.isEmpty
                  ? 'Task unassigned'
                  : 'Task assigned to ${_selectedAssignees.length} member(s)',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update assignment: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(
      projectMembersListProvider(widget.projectId),
    );
    final currentUser = ref.watch(authProvider).value;

    return AlertDialog(
      title: const Text('Assign Task'),
      content: SizedBox(
        width: double.maxFinite,
        child: membersAsync.when(
          data: (members) {
            if (members.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No team members available.\nAdd members to the project first.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Unassigned option
                CheckboxListTile(
                  value: _selectedAssignees.isEmpty,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            if (value == true) {
                              _selectedAssignees.clear();
                            }
                          });
                        },
                  title: const Text('Unassigned'),
                  subtitle: const Text('No one assigned to this task'),
                  secondary: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_off_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const Divider(),
                // Members list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isCurrentUser = member.userId == currentUser?.id;
                      final isSelected = _selectedAssignees.contains(
                        member.userId,
                      );

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedAssignees.add(member.userId);
                                  } else {
                                    _selectedAssignees.remove(member.userId);
                                  }
                                });
                              },
                        title: Row(
                          children: [
                            Expanded(child: Text(member.displayName)),
                            if (isCurrentUser)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(member.email),
                        secondary: CircleAvatar(
                          backgroundImage: member.photoUrl != null
                              ? NetworkImage(member.photoUrl!)
                              : null,
                          child: member.photoUrl == null
                              ? Text(
                                  member.displayName[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 18),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error loading members: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveAssignment,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
