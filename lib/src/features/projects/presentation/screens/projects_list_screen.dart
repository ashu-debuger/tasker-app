import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart'; // TODO: Re-enable with debug menu
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../notifiers/project_list_notifier.dart';
import '../notifiers/invitation_notifier.dart';
import '../../domain/models/project.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../../core/routing/app_router.dart';
// import '../../../../core/providers/providers.dart'; // TODO: Re-enable with debug menu
import '../../../../core/widgets/offline_banner.dart';
import '../../../home/widgets/plugin_action_bar.dart';
import '../../../notifications/presentation/notifiers/notification_notifier.dart';

/// Projects list screen showing all user projects
class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

enum _ProjectMenuAction { open, delete }

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  final _createProjectFormKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _projectDescriptionController = TextEditingController();

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _showCreateProjectDialog() async {
    _projectNameController.clear();
    _projectDescriptionController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: Form(
          key: _createProjectFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _projectNameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  hintText: 'Enter project name',
                  prefixIcon: Icon(Icons.folder),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a project name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _projectDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter project description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
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
            onPressed: () => _createProject(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createProject(BuildContext dialogContext) async {
    if (!_createProjectFormKey.currentState!.validate()) return;

    final name = _projectNameController.text.trim();
    final description = _projectDescriptionController.text.trim();
    final projectId = DateTime.now().millisecondsSinceEpoch.toString();

    // Store references before async operation
    final navigator = Navigator.of(dialogContext);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(projectListProvider.notifier)
          .createProject(
            id: projectId,
            name: name,
            description: description.isEmpty ? null : description,
          );

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Project "$name" created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error creating project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Delete "${project.name}" and all of its tasks? This cannot be undone.',
        ),
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
      await ref.read(projectListProvider.notifier).deleteProject(project.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Project "${project.name}" deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // TODO: Re-enable debug methods when needed
  // Future<void> _seedSampleData() async {
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Seed Sample Data'),
  //       content: const Text(
  //         'This will create 3 sample projects with tasks and subtasks. '
  //         'Continue?',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(false),
  //           child: const Text('Cancel'),
  //         ),
  //         FilledButton(
  //           onPressed: () => Navigator.of(context).pop(true),
  //           child: const Text('Seed Data'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirm != true) return;

  //   try {
  //     final seeder = ref.read(devDataSeederProvider);
  //     await seeder.seedSampleData();

  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Sample data created successfully!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error seeding data: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // Future<void> _clearSampleData() async {
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Clear Sample Data'),
  //       content: const Text(
  //         'This will delete all sample projects created by the seed script. '
  //         'Continue?',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(false),
  //           child: const Text('Cancel'),
  //         ),
  //         FilledButton(
  //           onPressed: () => Navigator.of(context).pop(true),
  //           style: FilledButton.styleFrom(backgroundColor: Colors.red),
  //           child: const Text('Clear Data'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirm != true) return;

  //   try {
  //     final seeder = ref.read(devDataSeederProvider);
  //     await seeder.clearSampleData();

  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Sample data cleared successfully!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error clearing data: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // TODO: Re-enable debug menu when needed
  // Future<void> _showDebugMenu() async {
  //   await showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Debug Menu'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           FilledButton.icon(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               _seedSampleData();
  //             },
  //             icon: const Icon(Icons.add_box),
  //             label: const Text('Seed Sample Data'),
  //           ),
  //           const SizedBox(height: 8),
  //           OutlinedButton.icon(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               _clearSampleData();
  //             },
  //             icon: const Icon(Icons.delete_sweep),
  //             label: const Text('Clear Sample Data'),
  //             style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Close'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final projectsStream = ref.watch(projectListProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final invitationsAsync = ref.watch(userInvitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          const OfflineIndicator(),
          // Invitations bell
          invitationsAsync.when(
            data: (invitations) {
              final pendingCount = invitations.where((i) => i.isPending).length;
              return IconButton(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text(
                    pendingCount > 99 ? '99+' : pendingCount.toString(),
                  ),
                  child: const Icon(Icons.mail_outline),
                ),
                onPressed: () => context.push(AppRoutes.invitations),
                tooltip: 'Invitations',
              );
            },
            loading: () => IconButton(
              icon: const Icon(Icons.mail_outline),
              onPressed: () => context.push(AppRoutes.invitations),
            ),
            error: (_, __) => IconButton(
              icon: const Icon(Icons.mail_outline),
              onPressed: () => context.push(AppRoutes.invitations),
            ),
          ),
          // Notification bell
          unreadCountAsync.when(
            data: (count) => IconButton(
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text(count > 99 ? '99+' : count.toString()),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => context.push(AppRoutes.notifications),
              tooltip: 'Notifications',
            ),
            loading: () => const IconButton(
              icon: Icon(Icons.notifications_outlined),
              onPressed: null,
            ),
            error: (_, __) => IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push(AppRoutes.notifications),
            ),
          ),
          // TODO: Re-enable debug menu when needed
          // if (kDebugMode)
          //   IconButton(
          //     icon: const Icon(Icons.bug_report),
          //     onPressed: _showDebugMenu,
          //     tooltip: 'Debug Menu',
          //   ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tasker by Mantra',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Projects'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.sticky_note_2),
              title: const Text('Sticky Notes'),
              onTap: () {
                Navigator.pop(context);
                final authState = ref.read(authProvider);
                authState.whenData((user) {
                  if (user != null) {
                    context.push(
                      AppRoutes.stickyNotes,
                      extra: {'userId': user.id},
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Routines'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.routines);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Calendar'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.calendar);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree),
              title: const Text('Mind Maps'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.mindMaps);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Diary'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.diary);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notification_add),
              title: const Text('Scheduled Reminders'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.scheduledReminders);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Reminder Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.reminderSettings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Encryption Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.encryptionSettings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Zoho Cliq'),
              subtitle: const Text('Notifications & Linking'),
              onTap: () {
                Navigator.pop(context);
                final authState = ref.read(authProvider);
                authState.whenData((user) {
                  if (user != null) {
                    context.push(
                      AppRoutes.cliqSettings,
                      extra: {'userId': user.id, 'userEmail': user.email},
                    );
                  }
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.profile);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          const PluginActionBar(),
          Expanded(
            child: projectsStream.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No projects yet',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first project to get started',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: _showCreateProjectDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Project'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: project.isSystem
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            project.isSystem ? Icons.person : Icons.folder,
                            color: project.isSystem
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          project.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: project.description != null
                            ? Text(
                                project.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!project.isSystem && project.members.length > 1)
                              Chip(
                                label: Text(
                                  '${project.members.length} members',
                                ),
                                avatar: const Icon(Icons.people, size: 16),
                              ),
                            const SizedBox(width: 4),
                            if (!project.isSystem)
                              PopupMenuButton<_ProjectMenuAction>(
                                tooltip: 'Project actions',
                                onSelected: (action) {
                                  switch (action) {
                                    case _ProjectMenuAction.open:
                                      context.push(
                                        '${AppRoutes.projects}/${project.id}',
                                      );
                                      break;
                                    case _ProjectMenuAction.delete:
                                      _confirmDeleteProject(project);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: _ProjectMenuAction.open,
                                    child: Row(
                                      children: const [
                                        Icon(Icons.open_in_new, size: 18),
                                        SizedBox(width: 12),
                                        Text('Open Project'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: _ProjectMenuAction.delete,
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        SizedBox(width: 12),
                                        Text('Delete Project'),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          context.push('${AppRoutes.projects}/${project.id}');
                        },
                      ),
                    );
                  },
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
                      'Error loading projects',
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
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(projectListProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: projectsStream.maybeWhen(
        data: (projects) => projects.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _showCreateProjectDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Project'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}
