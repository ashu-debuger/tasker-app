import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../notifiers/mind_map_notifier.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';

/// Screen showing list of user's mind maps
class MindMapListScreen extends ConsumerWidget {
  const MindMapListScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref, String userId) {
    final titleController = TextEditingController();
    final rootTextController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Mind Map'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rootTextController,
              decoration: const InputDecoration(
                labelText: 'Root Node Text',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty &&
                  rootTextController.text.trim().isNotEmpty) {
                AppLogger.info('Creating mind map for user: $userId');

                final mindMapId = await ref
                    .read(mindMapProvider.notifier)
                    .createMindMap(
                      userId,
                      titleController.text.trim(),
                      rootTextController.text.trim(),
                    );

                if (context.mounted && mindMapId != null) {
                  Navigator.pop(context);
                  context.push(
                    '/mind-maps/$mindMapId',
                    extra: {'userId': userId},
                  );
                } else if (mindMapId == null) {
                  AppLogger.error('Failed to create mind map - returned null');
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please sign in'));
        }

        final mindMapsStream = ref.watch(userMindMapsProvider(user.id));

        return Scaffold(
          appBar: AppBar(title: const Text('Mind Maps')),
          body: mindMapsStream.when(
            data: (mindMaps) {
              if (mindMaps.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No mind maps yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Create your first mind map to get started',
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () =>
                              _showCreateDialog(context, ref, user.id),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Mind Map'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: mindMaps.length,
                itemBuilder: (context, index) {
                  final mindMap = mindMaps[index];
                  final updatedDate = mindMap.updatedAt ?? mindMap.createdAt;
                  final dateStr = _formatDate(updatedDate);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.account_tree,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        mindMap.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mindMap.description != null &&
                              mindMap.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              mindMap.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Updated $dateStr',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          _showDeleteDialog(
                            context,
                            ref,
                            mindMap.id,
                            mindMap.title,
                          );
                        },
                      ),
                      onTap: () {
                        context.push(
                          '/mind-maps/${mindMap.id}',
                          extra: {'userId': user.id},
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading mind maps',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        error.toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateDialog(context, ref, user.id),
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String mindMapId,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mind Map'),
        content: Text(
          'Delete "$title" and all its nodes? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(mindMapProvider.notifier).deleteMindMap(mindMapId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
