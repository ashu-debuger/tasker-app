import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/projects/presentation/screens/projects_list_screen.dart';
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/routines/presentation/screens/routine_detail_screen.dart';
import '../../features/routines/presentation/screens/routines_list_screen.dart';
import '../../features/sticky_notes/presentation/screens/sticky_notes_grid_screen.dart';
import '../../features/sticky_notes/presentation/screens/note_editor_screen.dart';
import '../../features/sticky_notes/domain/models/sticky_note.dart';
import '../../features/settings/presentation/screens/encryption_settings_screen.dart';
import '../../features/settings/presentation/screens/reminder_settings_screen.dart';
import '../../features/settings/presentation/screens/notification_permission_screen.dart';
import '../../features/settings/presentation/screens/cliq_settings_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/reminders/presentation/screens/scheduled_reminders_screen.dart';
import '../../features/mind_maps/presentation/screens/mind_map_list_screen.dart';
import '../../features/mind_maps/presentation/screens/mind_map_canvas_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/projects/presentation/screens/pending_invitations_screen.dart';
import '../../features/diary/presentation/diary_list_screen.dart';
import '../../features/diary/presentation/diary_editor_screen.dart';
import '../../features/diary/models/diary_entry.dart';

/// Application route names
class AppRoutes {
  static const String home = '/';
  static const String splash = '/splash';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:projectId';
  static const String taskDetail = '/projects/:projectId/tasks/:taskId';
  static const String chat = '/projects/:projectId/chat';
  static const String routines = '/routines';
  static const String routineDetail = '/routines/:routineId';
  static const String calendar = '/calendar';
  static const String stickyNotes = '/sticky-notes';
  static const String stickyNoteEditor = '/sticky-notes/editor';
  static const String encryptionSettings = '/settings/encryption';
  static const String reminderSettings = '/settings/reminders';
  static const String cliqSettings = '/settings/cliq';
  static const String profile = '/profile';
  static const String scheduledReminders = '/reminders/scheduled';
  static const String notificationPermission = '/notification-permission';
  static const String mindMaps = '/mind-maps';
  static const String mindMapCanvas = '/mind-maps/:mindMapId';
  static const String notifications = '/notifications';
  static const String invitations = '/invitations';
  static const String diary = '/diary';
  static const String diaryEditor = '/diary/editor';
}

/// Global router configuration
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      redirect: (context, state) => AppRoutes.splash,
    ),
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: AppRoutes.projects,
      builder: (context, state) => const ProjectsListScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectDetail,
      builder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        return ProjectDetailScreen(projectId: projectId);
      },
    ),
    GoRoute(
      path: AppRoutes.taskDetail,
      builder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        final taskId = state.pathParameters['taskId']!;
        return TaskDetailScreen(projectId: projectId, taskId: taskId);
      },
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        final projectName =
            state.uri.queryParameters['projectName'] ?? 'Project';
        return ChatScreen(projectId: projectId, projectName: projectName);
      },
    ),
    GoRoute(
      path: AppRoutes.routines,
      builder: (context, state) => const RoutinesListScreen(),
    ),
    GoRoute(
      path: AppRoutes.routineDetail,
      builder: (context, state) {
        final routineId = state.pathParameters['routineId']!;
        final extra = state.extra as Map<String, dynamic>;
        final userId = extra['userId'] as String;
        return RoutineDetailScreen(routineId: routineId, userId: userId);
      },
    ),
    GoRoute(
      path: AppRoutes.calendar,
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: AppRoutes.stickyNotes,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final userId = extra['userId'] as String;
        return StickyNotesGridScreen(userId: userId);
      },
    ),
    GoRoute(
      path: AppRoutes.stickyNoteEditor,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final userId = extra['userId'] as String;
        final note = extra['note'] as StickyNote?;
        final enableNoteSwitcher =
            extra['enableNoteSwitcher'] as bool? ?? false;
        return NoteEditorScreen(
          userId: userId,
          note: note,
          enableNoteSwitcher: enableNoteSwitcher,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.encryptionSettings,
      builder: (context, state) => const EncryptionSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.reminderSettings,
      builder: (context, state) => const ReminderSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.cliqSettings,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final userId = extra['userId'] as String;
        final userEmail = extra['userEmail'] as String;
        return CliqSettingsScreen(userId: userId, userEmail: userEmail);
      },
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.scheduledReminders,
      builder: (context, state) => const ScheduledRemindersScreen(),
    ),
    GoRoute(
      path: AppRoutes.notificationPermission,
      builder: (context, state) => const NotificationPermissionScreen(),
    ),
    GoRoute(
      path: AppRoutes.mindMaps,
      builder: (context, state) => const MindMapListScreen(),
    ),
    GoRoute(
      path: AppRoutes.mindMapCanvas,
      builder: (context, state) {
        final mindMapId = state.pathParameters['mindMapId']!;
        final extra = state.extra as Map<String, dynamic>;
        final userId = extra['userId'] as String;
        return MindMapCanvasScreen(mindMapId: mindMapId, userId: userId);
      },
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.invitations,
      builder: (context, state) => const PendingInvitationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.diary,
      builder: (context, state) => const DiaryListScreen(),
    ),
    GoRoute(
      path: AppRoutes.diaryEditor,
      builder: (context, state) {
        final entry = state.extra as DiaryEntry?;
        return DiaryEditorScreen(entry: entry);
      },
    ),
    // Nested routes will be added as screens are implemented
  ],
  errorBuilder: (context, state) => const _ErrorScreen(),
);

/// Error screen for invalid routes
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: const Center(child: Text('Page not found')),
    );
  }
}
