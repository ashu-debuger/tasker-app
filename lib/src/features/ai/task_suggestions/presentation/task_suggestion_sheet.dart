import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task_suggestion.dart';
import '../models/task_suggestion_request.dart';
import 'task_suggestion_notifier.dart';

class TaskSuggestionSheet extends ConsumerWidget {
  const TaskSuggestionSheet({
    super.key,
    required this.request,
    required this.onSuggestionAccepted,
  });

  final TaskSuggestionRequest request;
  final void Function(TaskSuggestion suggestion) onSuggestionAccepted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(taskSuggestionControllerProvider(request));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_fix_high_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Smart suggestions for ${request.projectName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Regenerate',
                  onPressed: () {
                    ref
                        .read(taskSuggestionControllerProvider(request).notifier)
                        .refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'We analyze recent activity and propose bite-sized next steps. '
              'Use a suggestion to pre-fill the task creator.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            suggestions.when(
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No ideas right now. Try refreshing or adding more project context.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: min<double>(400, MediaQuery.of(context).size.height * 0.6),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final suggestion = items[index];
                      return _SuggestionCard(
                        suggestion: suggestion,
                        onAccept: () => onSuggestionAccepted(suggestion),
                      );
                    },
                    separatorBuilder: (context, _) =>
                      const SizedBox(height: 12),
                    itemCount: items.length,
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unable to load suggestions',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(
                              taskSuggestionControllerProvider(request).notifier,
                            )
                            .refresh();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.onAccept,
  });

  final TaskSuggestion suggestion;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text('Confidence ${(suggestion.confidence * 100).round()}%'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (suggestion.recommendedDueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    materialDatePickerFormat.format(suggestion.recommendedDueDate!),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (suggestion.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: suggestion.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Use suggestion'),
            ),
          ],
        ),
      ),
    );
  }
}

final DateFormat materialDatePickerFormat = DateFormat('MMM d, yyyy');
