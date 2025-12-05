import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tasker/src/features/settings/data/models/cliq_notification_settings.dart';
import 'package:tasker/src/features/settings/presentation/notifiers/cliq_notifier.dart';
import 'dart:math';

/// Screen for managing Zoho Cliq integration settings
class CliqSettingsScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userEmail;

  const CliqSettingsScreen({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  ConsumerState<CliqSettingsScreen> createState() => _CliqSettingsScreenState();
}

class _CliqSettingsScreenState extends ConsumerState<CliqSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final cliqState = ref.watch(cliqProvider(widget.userId, widget.userEmail));
    final cliqNotifier = ref.read(
      cliqProvider(widget.userId, widget.userEmail).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoho Cliq Integration'),
        actions: [
          if (cliqState.isLinked)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => cliqNotifier.loadCliqStatus(),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: cliqState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error banner
                  if (cliqState.error != null) ...[
                    _buildErrorBanner(cliqState.error!, cliqNotifier),
                    const SizedBox(height: 16),
                  ],

                  // Link status card
                  _buildLinkStatusCard(cliqState, cliqNotifier),
                  const SizedBox(height: 24),

                  // Notification settings (only if linked)
                  if (cliqState.isLinked) ...[
                    _buildNotificationSettingsSection(cliqState, cliqNotifier),
                    const SizedBox(height: 24),
                    _buildQuietHoursSection(cliqState, cliqNotifier),
                    const SizedBox(height: 24),
                    _buildDoNotDisturbSection(cliqState, cliqNotifier),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildErrorBanner(String error, CliqNotifier notifier) {
    return MaterialBanner(
      content: Text(error),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      actions: [
        TextButton(
          onPressed: () => notifier.clearError(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  Widget _buildLinkStatusCard(CliqState state, CliqNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isLinked ? Icons.link : Icons.link_off,
                  color: state.isLinked ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isLinked ? 'Connected' : 'Not Connected',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (state.isLinked && state.mapping != null)
                        Text(
                          'Linked as ${state.mapping!.cliqUserName}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.isLinked)
              _buildUnlinkButton(notifier)
            else
              _buildLinkingSection(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkingSection(CliqState state, CliqNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect your Zoho Cliq account to receive task notifications directly in Cliq.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        // Show challenge verification if code exists and not yet verified
        if (state.linkingCode != null &&
            state.challengeNumber != null &&
            !state.isPendingVerification) ...[
          _ChallengeVerificationUI(
            linkingCode: state.linkingCode!,
            correctChallengeNumber: state.challengeNumber!,
            onNumberSelected: (number) =>
                _onChallengeNumberSelected(number, notifier),
          ),
        ]
        // Show "waiting for Cliq" message if challenge is verified
        else if (state.linkingCode != null && state.isPendingVerification) ...[
          _buildWaitingForCliqUI(state, notifier),
        ]
        // Show code display if code exists but no challenge (backward compat)
        else if (state.linkingCode != null) ...[
          _buildLinkingCodeUI(state, notifier),
        ]
        // Show generate button
        else ...[
          FilledButton.icon(
            onPressed: () => _showPasswordVerificationDialog(notifier),
            icon: const Icon(Icons.link),
            label: const Text('Generate Linking Code'),
          ),
          const SizedBox(height: 8),
          Text(
            '🔐 You\'ll need to verify your password for security',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// Show password verification dialog before generating code
  Future<void> _showPasswordVerificationDialog(CliqNotifier notifier) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _PasswordVerificationDialog(
        onVerified: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    // If password verified, generate the linking code
    if (result == true) {
      notifier.setAuthenticated(true);
      await notifier.generateLinkingCode();
    }
  }

  /// Handle challenge number selection
  Future<void> _onChallengeNumberSelected(
    int selectedNumber,
    CliqNotifier notifier,
  ) async {
    final success = await notifier.verifyChallenge(selectedNumber);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Verified! Now complete the linking in Cliq.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Incorrect number. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build the "waiting for Cliq" UI after challenge is verified
  Widget _buildWaitingForCliqUI(CliqState state, CliqNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 48, color: Colors.green),
          const SizedBox(height: 12),
          Text(
            'Verification Complete!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Now go back to Zoho Cliq and enter the command again to complete linking:',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              '/tasker link ${state.linkingCode}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => notifier.loadCliqStatus(),
            icon: const Icon(Icons.refresh),
            label: const Text('I\'ve completed the linking'),
          ),
          TextButton(
            onPressed: () {
              notifier.clearAuthentication();
            },
            child: const Text('Cancel & Start Over'),
          ),
        ],
      ),
    );
  }

  /// Build the old linking code UI (backward compatibility)
  Widget _buildLinkingCodeUI(CliqState state, CliqNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Your linking code:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SelectableText(
            state.linkingCode!,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: state.linkingCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to link:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. Open Zoho Cliq'),
                Text('2. Type: /tasker link ${state.linkingCode}'),
                const Text('3. Press Enter'),
                const SizedBox(height: 8),
                Text(
                  'Code expires in 10 minutes',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => notifier.loadCliqStatus(),
            child: const Text('I\'ve linked my account'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlinkButton(CliqNotifier notifier) {
    return OutlinedButton.icon(
      onPressed: () => _showUnlinkConfirmation(notifier),
      icon: const Icon(Icons.link_off),
      label: const Text('Unlink Account'),
      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
    );
  }

  void _showUnlinkConfirmation(CliqNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Cliq Account?'),
        content: const Text(
          'You will no longer receive task notifications in Zoho Cliq. You can link again anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.unlinkCliq();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsSection(
    CliqState state,
    CliqNotifier notifier,
  ) {
    final settings = state.settings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Notification Types',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('All Notifications'),
              subtitle: const Text('Master toggle for all Cliq notifications'),
              value: settings.enabled,
              onChanged: (value) {
                notifier.updateNotificationSettings(
                  settings.copyWith(enabled: value),
                );
              },
            ),
            const Divider(),
            _buildNotificationToggle(
              'Task Assigned',
              'When a task is assigned to you',
              settings.taskAssigned,
              settings.enabled,
              () => notifier.toggleNotificationType(
                'task_assigned',
                !settings.taskAssigned,
              ),
            ),
            _buildNotificationToggle(
              'Task Completed',
              'When your tasks are completed',
              settings.taskCompleted,
              settings.enabled,
              () => notifier.toggleNotificationType(
                'task_completed',
                !settings.taskCompleted,
              ),
            ),
            _buildNotificationToggle(
              'Due Soon Reminders',
              'Tasks due within 24 hours',
              settings.taskDueSoon,
              settings.enabled,
              () => notifier.toggleNotificationType(
                'task_due_soon',
                !settings.taskDueSoon,
              ),
            ),
            _buildNotificationToggle(
              'Overdue Alerts',
              'Tasks that are past due',
              settings.taskOverdue,
              settings.enabled,
              () => notifier.toggleNotificationType(
                'task_overdue',
                !settings.taskOverdue,
              ),
            ),
            _buildNotificationToggle(
              'New Comments',
              'Comments on your tasks',
              settings.commentAdded,
              settings.enabled,
              () => notifier.toggleNotificationType(
                'comment_added',
                !settings.commentAdded,
              ),
            ),
            _buildNotificationToggle(
              'Project Invites',
              'Invitations to join projects',
              settings.projectInvite,
              settings.enabled,
              () => notifier.toggleNotificationType(
                'project_invite',
                !settings.projectInvite,
              ),
            ),
            _buildNotificationToggle(
              'Member Updates',
              'When members join/leave projects',
              settings.memberJoined,
              settings.enabled,
              () => notifier.toggleNotificationType(
                'member_joined',
                !settings.memberJoined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    bool enabled,
    VoidCallback onToggle,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value && enabled,
      onChanged: enabled ? (_) => onToggle() : null,
      dense: true,
    );
  }

  Widget _buildQuietHoursSection(CliqState state, CliqNotifier notifier) {
    final quietHours = state.settings.quietHours ?? const QuietHours();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Quiet Hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              subtitle: Text(
                quietHours.enabled
                    ? 'No notifications from ${_formatHour(quietHours.startHour)} to ${_formatHour(quietHours.endHour)}'
                    : 'Pause notifications during specific hours',
              ),
              value: quietHours.enabled,
              onChanged: (value) {
                notifier.updateQuietHours(
                  enabled: value,
                  startHour: quietHours.startHour,
                  endHour: quietHours.endHour,
                );
              },
            ),
            if (quietHours.enabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Start Time'),
                trailing: Text(_formatHour(quietHours.startHour)),
                onTap: () => _showTimePicker(
                  quietHours.startHour,
                  (hour) => notifier.updateQuietHours(
                    enabled: true,
                    startHour: hour,
                    endHour: quietHours.endHour,
                  ),
                ),
              ),
              ListTile(
                title: const Text('End Time'),
                trailing: Text(_formatHour(quietHours.endHour)),
                onTap: () => _showTimePicker(
                  quietHours.endHour,
                  (hour) => notifier.updateQuietHours(
                    enabled: true,
                    startHour: quietHours.startHour,
                    endHour: hour,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoNotDisturbSection(CliqState state, CliqNotifier notifier) {
    final dnd = state.settings.doNotDisturb;
    final isActive = dnd?.isActive ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.do_not_disturb,
                  size: 24,
                  color: isActive ? Colors.red : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'Do Not Disturb',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ON',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (isActive && dnd?.until != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Active until ${_formatDateTime(dnd!.until!)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ),
            const SizedBox(height: 8),
            if (isActive)
              FilledButton.icon(
                onPressed: () => notifier.disableDoNotDisturb(),
                icon: const Icon(Icons.notifications_active),
                label: const Text('Turn Off DND'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => notifier.enableDoNotDisturb(hours: 1),
                    child: const Text('1 Hour'),
                  ),
                  OutlinedButton(
                    onPressed: () => notifier.enableDoNotDisturb(hours: 4),
                    child: const Text('4 Hours'),
                  ),
                  OutlinedButton(
                    onPressed: () => notifier.enableDoNotDisturb(hours: 8),
                    child: const Text('8 Hours'),
                  ),
                  OutlinedButton(
                    onPressed: () => notifier.enableDoNotDisturb(hours: 24),
                    child: const Text('24 Hours'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${dt.month}/${dt.day} $displayHour:$minute $period';
  }

  void _showTimePicker(int currentHour, Function(int) onSelected) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Time'),
        children: List.generate(24, (hour) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              onSelected(hour);
            },
            child: Text(
              _formatHour(hour),
              style: TextStyle(
                fontWeight: hour == currentHour ? FontWeight.bold : null,
                color: hour == currentHour
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Separate StatefulWidget for password verification dialog
/// This properly manages the TextEditingController lifecycle
class _PasswordVerificationDialog extends StatefulWidget {
  final VoidCallback onVerified;
  final VoidCallback onCancel;

  const _PasswordVerificationDialog({
    required this.onVerified,
    required this.onCancel,
  });

  @override
  State<_PasswordVerificationDialog> createState() =>
      _PasswordVerificationDialogState();
}

class _PasswordVerificationDialogState
    extends State<_PasswordVerificationDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Re-authenticate with Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Password verified, close dialog with success
      if (mounted) {
        widget.onVerified();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Invalid password';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Your Identity'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For security, please enter your password to continue linking your Cliq account.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
              onFieldSubmitted: (_) => _verifyPassword(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : widget.onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _verifyPassword,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}

/// Separate StatefulWidget for challenge verification UI
/// This ensures random numbers are only generated once and not on every rebuild
class _ChallengeVerificationUI extends StatefulWidget {
  final String linkingCode;
  final int correctChallengeNumber;
  final void Function(int) onNumberSelected;

  const _ChallengeVerificationUI({
    required this.linkingCode,
    required this.correctChallengeNumber,
    required this.onNumberSelected,
  });

  @override
  State<_ChallengeVerificationUI> createState() =>
      _ChallengeVerificationUIState();
}

class _ChallengeVerificationUIState extends State<_ChallengeVerificationUI> {
  late List<int> _shuffledNumbers;

  @override
  void initState() {
    super.initState();
    _generateNumbers();
  }

  void _generateNumbers() {
    final random = Random();
    final numbers = <int>{widget.correctChallengeNumber};

    // Generate unique random numbers
    while (numbers.length < 4) {
      numbers.add(1000 + random.nextInt(9000));
    }

    // Shuffle the numbers
    _shuffledNumbers = numbers.toList()..shuffle(random);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.security,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Verify Your Account',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your code in Zoho Cliq:\n/tasker link ${widget.linkingCode}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              widget.linkingCode,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Cliq will show you a verification number.\nSelect that number below:',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _shuffledNumbers.map((number) {
              return SizedBox(
                width: 100,
                child: OutlinedButton(
                  onPressed: () => widget.onNumberSelected(number),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    number.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Code expires in 10 minutes',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.orange),
          ),
        ],
      ),
    );
  }
}
