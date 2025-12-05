import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/project_role.dart';
import '../notifiers/invitation_notifier.dart';
import '../../../../core/utils/app_logger.dart';

/// Bottom sheet for sending project invitations
class InvitationBottomSheet extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const InvitationBottomSheet({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<InvitationBottomSheet> createState() =>
      _InvitationBottomSheetState();
}

class _InvitationBottomSheetState extends ConsumerState<InvitationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  ProjectRole _selectedRole = ProjectRole.editor;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invitationState = ref.watch(invitationProvider);

    // Listen for state changes
    ref.listen<InvitationState>(invitationProvider, (previous, next) {
      if (next.error != null) {
        appLogger.e(
          '[InvitationBottomSheet] Error: ${next.error}',
          error: next.error,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(invitationProvider.notifier).clearMessages();
      }

      if (next.successMessage != null) {
        appLogger.i('[InvitationBottomSheet] Success: ${next.successMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(invitationProvider.notifier).clearMessages();

        // Close bottom sheet on success
        Navigator.of(context).pop();
      }
    });

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite to Project',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            widget.projectName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter email to invite',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !invitationState.isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email address';
                    }
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role selector
                Text('Role', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProjectRole>(
                  isExpanded: true,
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shield),
                  ),
                  items: ProjectRole.values
                      .where((role) => role != ProjectRole.owner)
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Row(
                            children: [
                              Text(
                                role.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${role.displayName} - ${_getRoleDescription(role)}',
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: invitationState.isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                ),
                const SizedBox(height: 8),
                // Role description for selected role
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getRoleDescription(_selectedRole),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Optional message
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (Optional)',
                    hintText: 'Add a personal message...',
                    prefixIcon: Icon(Icons.message),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  enabled: !invitationState.isLoading,
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: invitationState.isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: invitationState.isLoading
                            ? null
                            : _sendInvitation,
                        icon: invitationState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: const Text('Send Invite'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleDescription(ProjectRole role) {
    switch (role) {
      case ProjectRole.admin:
        return 'Manage members and settings';
      case ProjectRole.editor:
        return 'Edit tasks and content';
      case ProjectRole.viewer:
        return 'View only access';
      case ProjectRole.owner:
        return 'Full control';
    }
  }

  void _sendInvitation() {
    if (!_formKey.currentState!.validate()) {
      appLogger.w('[InvitationBottomSheet] Form validation failed');
      return;
    }

    final email = _emailController.text.trim();
    final message = _messageController.text.trim();

    appLogger.i(
      '[InvitationBottomSheet] Sending invitation '
      'projectId=${widget.projectId} email=${maskEmail(email)} role=${_selectedRole.name}',
    );

    ref
        .read(invitationProvider.notifier)
        .sendInvitation(
          projectId: widget.projectId,
          email: email,
          role: _selectedRole,
          message: message.isEmpty ? null : message,
        );
  }
}

/// Helper function to show the invitation bottom sheet
void showInvitationBottomSheet({
  required BuildContext context,
  required String projectId,
  required String projectName,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) =>
        InvitationBottomSheet(projectId: projectId, projectName: projectName),
  );
}
