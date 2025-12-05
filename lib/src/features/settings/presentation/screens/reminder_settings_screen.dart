import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/reminder_settings.dart';
import '../notifiers/reminder_settings_notifier.dart';

class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose the default lead times Tasker should use when scheduling reminders.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _LeadTimeCard(
            title: 'Task reminders',
            subtitle: 'How long before a task is due should Tasker notify you?',
            selectedMinutes: settings.taskLeadMinutes,
            onMinutesSelected: (minutes) async {
              if (minutes == settings.taskLeadMinutes) return;
              await notifier.updateTaskLeadMinutes(minutes);
              if (!context.mounted) return;
              _showSnackBar(
                context,
                'Task reminders updated to ${_formatMinutes(minutes)}',
              );
            },
          ),
          const SizedBox(height: 16),
          _LeadTimeCard(
            title: 'Routine reminders',
            subtitle:
                'Default reminder lead time for daily and weekly routines.',
            selectedMinutes: settings.routineLeadMinutes,
            onMinutesSelected: (minutes) async {
              if (minutes == settings.routineLeadMinutes) return;
              await notifier.updateRoutineLeadMinutes(minutes);
              if (!context.mounted) return;
              _showSnackBar(
                context,
                'Routine reminders updated to ${_formatMinutes(minutes)}',
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              await notifier.resetToDefaults();
              if (!context.mounted) return;
              _showSnackBar(context, 'Reminder settings reset to defaults');
            },
            icon: const Icon(Icons.restore),
            label: const Text('Reset to defaults'),
          ),
        ],
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LeadTimeCard extends StatelessWidget {
  const _LeadTimeCard({
    required this.title,
    required this.subtitle,
    required this.selectedMinutes,
    required this.onMinutesSelected,
  });

  final String title;
  final String subtitle;
  final int selectedMinutes;
  final Future<void> Function(int) onMinutesSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ReminderSettings.supportedLeadTimes.map((minutes) {
                final label = _formatMinutes(minutes);
                return ChoiceChip(
                  label: Text(label),
                  selected: selectedMinutes == minutes,
                  onSelected: (_) {
                    if (selectedMinutes == minutes) return;
                    onMinutesSelected(minutes);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Currently notifying ${_formatMinutes(selectedMinutes).toLowerCase()} beforehand.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMinutes(int minutes) {
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hour' : '$hours hours';
  }
  return '$minutes min';
}
