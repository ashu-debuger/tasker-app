import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/routine.dart';
import '../notifiers/routine_notifier.dart';
import '../widgets/routine_dialog.dart';

/// Detail screen for viewing and managing a specific routine
class RoutineDetailScreen extends ConsumerWidget {
  final String routineId;
  final String userId;

  const RoutineDetailScreen({
    super.key,
    required this.routineId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineProvider(userId));

    return routinesAsync.when(
      data: (routines) {
        final routine = routines.firstWhere(
          (r) => r.id == routineId,
          orElse: () => Routine.empty,
        );

        if (routine.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Routine Not Found')),
            body: const Center(child: Text('This routine no longer exists')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(routine.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, ref, routine),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(context, ref, routine),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          routine.isActive ? Icons.check_circle : Icons.cancel,
                          color: routine.isActive ? Colors.green : Colors.grey,
                          size: 48,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                routine.isActive ? 'Active' : 'Inactive',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                routine.isActive
                                    ? 'This routine is currently running'
                                    : 'This routine is paused',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: routine.isActive,
                          onChanged: (_) async {
                            await ref
                                .read(routineProvider(userId).notifier)
                                .toggleRoutineActive(routine.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Schedule Section
                Text(
                  'Schedule',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.repeat,
                          'Frequency',
                          routine.frequency.displayName,
                        ),
                        if (routine.frequency == RoutineFrequency.weekly ||
                            routine.frequency == RoutineFrequency.custom) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            Icons.calendar_today,
                            'Days',
                            _formatDays(routine.daysOfWeek),
                          ),
                        ],
                        if (routine.timeOfDay != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            Icons.access_time,
                            'Time',
                            routine.timeOfDay!,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          Icons.today,
                          'Runs Today',
                          routine.shouldRunToday() ? 'Yes' : 'No',
                          valueColor: routine.shouldRunToday()
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Reminder Section
                Text(
                  'Reminders',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.notifications,
                          'Reminder',
                          routine.reminderEnabled ? 'Enabled' : 'Disabled',
                          valueColor: routine.reminderEnabled
                              ? Colors.green
                              : Colors.grey,
                        ),
                        if (routine.reminderEnabled) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            Icons.schedule,
                            'Remind Before',
                            '${routine.reminderMinutesBefore} minutes',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (routine.description != null &&
                    routine.description!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        routine.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Metadata
                Text(
                  'Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.add_circle,
                          'Created',
                          _formatDate(routine.createdAt),
                        ),
                        if (routine.updatedAt != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            Icons.update,
                            'Last Updated',
                            _formatDate(routine.updatedAt!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDays(List<int> days) {
    if (days.isEmpty) return 'Not set';
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((day) => dayNames[day - 1]).join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Routine routine) {
    showDialog(
      context: context,
      builder: (context) => RoutineDialog(userId: userId, routine: routine),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text(
          'Are you sure you want to delete "${routine.title}"? This action cannot be undone.',
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
      await ref
          .read(routineProvider(userId).notifier)
          .deleteRoutine(routine.id);

      if (!context.mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${routine.title}" deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
