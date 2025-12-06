import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/project_role.dart';
import '../notifiers/project_members_notifier.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';

/// Dialog for viewing and managing project members
class MemberManagementDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String projectOwnerId;

  const MemberManagementDialog({
    super.key,
    required this.projectId,
    required this.projectOwnerId,
  });

  @override
  ConsumerState<MemberManagementDialog> createState() =>
      _MemberManagementDialogState();
}

class _MemberManagementDialogState
    extends ConsumerState<MemberManagementDialog> {
  ProjectMember? _memberToRemove;
  ProjectMember? _memberToChangeRole;
  ProjectRole? _newRole;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(
      projectMembersListProvider(widget.projectId),
    );
    final currentUser = ref.watch(authProvider).value;
    final currentRoleAsync = currentUser != null
        ? ref.watch(memberRoleProvider(widget.projectId, currentUser.id))
        : const AsyncValue<ProjectRole?>.data(null);
    final canManage =
        (currentRoleAsync.asData?.value?.isAdmin ?? false) ||
        currentUser?.id == widget.projectOwnerId;
    final membersState = ref.watch(projectMembersProvider);

    // Listen for state changes
    ref.listen<ProjectMembersState>(projectMembersProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(projectMembersProvider.notifier).clearMessages();
      }

      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(projectMembersProvider.notifier).clearMessages();
      }
    });

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.group,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Project Members',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Members list
            Expanded(
              child: membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return const Center(child: Text('No members yet'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isCurrentUser = currentUser?.id == member.userId;
                      final isOwner = member.userId == widget.projectOwnerId;
                      return _MemberListItem(
                        member: member,
                        isCurrentUser: isCurrentUser,
                        isOwner: isOwner,
                        canManage: canManage,
                        onChangeRole: canManage && !isOwner
                            ? () => _showChangeRoleDialog(member)
                            : null,
                        onRemove: canManage && !isOwner && !isCurrentUser
                            ? () => _showRemoveConfirmation(member)
                            : null,
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
                      Text('Error: ${error.toString()}'),
                    ],
                  ),
                ),
              ),
            ),

            // Loading indicator
            if (membersState.isLoading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(ProjectMember member) {
    setState(() {
      _memberToChangeRole = member;
      _newRole = member.role;
    });

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${member.displayName}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select new role:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...ProjectRole.values
                  .where((role) => role != ProjectRole.owner)
                  .map(
                    (role) => RadioListTile<ProjectRole>(
                      title: Row(
                        children: [
                          Text(role.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(role.displayName),
                        ],
                      ),
                      value: role,
                      groupValue: _newRole,
                      onChanged: (value) {
                        setState(() => _newRole = value);
                        this.setState(() => _newRole = value);
                      },
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _memberToChangeRole = null;
                _newRole = null;
              });
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _newRole != null ? () => _confirmRoleChange() : null,
            child: const Text('Change Role'),
          ),
        ],
      ),
    );
  }

  void _confirmRoleChange() {
    if (_memberToChangeRole == null || _newRole == null) return;

    Navigator.of(context).pop(); // Close dialog

    ref
        .read(projectMembersProvider.notifier)
        .updateMemberRole(
          projectId: widget.projectId,
          userId: _memberToChangeRole!.userId,
          newRole: _newRole!,
        );

    setState(() {
      _memberToChangeRole = null;
      _newRole = null;
    });
  }

  void _showRemoveConfirmation(ProjectMember member) {
    setState(() => _memberToRemove = member);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from this project? '
          'All their task assignments will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _memberToRemove = null);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _confirmRemoveMember(),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember() {
    if (_memberToRemove == null) return;

    Navigator.of(context).pop(); // Close dialog

    ref
        .read(projectMembersProvider.notifier)
        .removeMember(
          projectId: widget.projectId,
          userId: _memberToRemove!.userId,
        );

    setState(() => _memberToRemove = null);
  }
}

/// List item widget for a single member
class _MemberListItem extends StatelessWidget {
  final ProjectMember member;
  final bool isCurrentUser;
  final bool isOwner;
  final bool canManage;
  final VoidCallback? onChangeRole;
  final VoidCallback? onRemove;

  const _MemberListItem({
    required this.member,
    required this.isCurrentUser,
    required this.isOwner,
    required this.canManage,
    this.onChangeRole,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final role = member.role;

    return ListTile(
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
          Expanded(
            child: Text(
              member.displayName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (isCurrentUser)
            Chip(
              label: const Text('You'),
              labelStyle: const TextStyle(fontSize: 11),
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
              Text(role.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                role.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOwner ? Colors.amber[700] : null,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: canManage && (onChangeRole != null || onRemove != null)
          ? PopupMenuButton<String>(
              itemBuilder: (context) => [
                if (onChangeRole != null)
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 20),
                        SizedBox(width: 8),
                        Text('Change Role'),
                      ],
                    ),
                  ),
                if (onRemove != null)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'change_role' && onChangeRole != null) {
                  onChangeRole!();
                } else if (value == 'remove' && onRemove != null) {
                  onRemove!();
                }
              },
            )
          : null,
    );
  }
}
