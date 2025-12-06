import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/presentation/notifiers/project_members_notifier.dart';
import '../../../projects/domain/models/project_role.dart';
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

      final currentRole = ref
          .read(memberRoleProvider(widget.projectId, currentUser.id))
          .asData
          ?.value;
      final canAssign = currentRole?.canEdit ?? false;

      if (!canAssign) {
        throw Exception('You do not have permission to assign tasks');
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
    final currentRoleAsync = currentUser != null
        ? ref.watch(memberRoleProvider(widget.projectId, currentUser.id))
        : const AsyncValue<ProjectRole?>.data(null);
    final canAssign = currentRoleAsync.asData?.value?.canEdit ?? false;

    return AlertDialog(
      title: const Text('Assign Task'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
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

                  final memberTiles = members
                      .map((member) {
                        final isCurrentUser = member.userId == currentUser?.id;
                        final isSelected = _selectedAssignees.contains(
                          member.userId,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: _isLoading || !canAssign
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
                      })
                      .toList(growable: false);

                  return ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      CheckboxListTile(
                        value: _selectedAssignees.isEmpty,
                        onChanged: _isLoading || !canAssign
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
                      ...memberTiles,
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!canAssign)
              Container(
                margin: const EdgeInsets.only(top: 12.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can view assignments but cannot modify them with your current role.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || !canAssign ? null : _saveAssignment,
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
