import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/projects/data/repositories/project_repository.dart';
import '../../features/projects/data/repositories/firebase_project_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import '../../features/tasks/data/repositories/firebase_task_repository.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/data/repositories/firebase_chat_repository.dart';
import '../../features/routines/domain/repositories/routine_repository.dart';
import '../../features/routines/data/repositories/firebase_routine_repository.dart';
import '../../features/sticky_notes/data/repositories/sticky_note_repository.dart';
import '../../features/sticky_notes/data/repositories/firebase_sticky_note_repository.dart';
import '../../features/mind_maps/data/repositories/mind_map_repository.dart';
import '../../features/mind_maps/data/repositories/firebase_mind_map_repository.dart';
import '../../features/tasks/domain/helpers/task_reminder_helper.dart';
import '../../features/projects/domain/repositories/invitation_repository.dart';
import '../../features/projects/data/repositories/firebase_invitation_repository.dart';
import '../../features/projects/domain/repositories/project_member_repository.dart';
import '../../features/projects/data/repositories/firebase_project_member_repository.dart';
import '../../features/settings/data/repositories/reminder_settings_repository.dart';
import '../../features/settings/data/repositories/hive_reminder_settings_repository.dart';
import '../../features/settings/domain/models/reminder_settings.dart';
import '../storage/hive_service.dart';
import '../utils/dev_data_seeder.dart';
import '../encryption/encryption_service.dart';
import '../notifications/notification_service.dart';
import '../notifications/repositories/notification_repository.dart';
import '../notifications/repositories/firebase_notification_repository.dart';
import '../quick_actions/quick_action_service.dart';
import '../notifications/tile_action_service.dart';

part 'providers.g.dart';

/// Firebase Auth instance provider
@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

/// Firestore instance provider
@riverpod
FirebaseFirestore firestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// Current Firebase user stream provider
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
}

/// AuthRepository provider
@riverpod
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
}

/// ProjectRepository provider
@riverpod
ProjectRepository projectRepository(Ref ref) {
  return FirebaseProjectRepository(ref.watch(firestoreProvider));
}

/// TaskRepository provider
@riverpod
TaskRepository taskRepository(Ref ref) {
  return FirebaseTaskRepository(
    ref.watch(firestoreProvider),
    ref.watch(encryptionServiceProvider),
    ref.watch(notificationRepositoryProvider),
  );
}

/// ChatRepository provider
@riverpod
ChatRepository chatRepository(Ref ref) {
  return FirebaseChatRepository(
    ref.watch(firestoreProvider),
    ref.watch(encryptionServiceProvider),
  );
}

/// DevDataSeeder provider (debug mode only)
@riverpod
DevDataSeeder devDataSeeder(Ref ref) {
  return DevDataSeeder(
    authRepository: ref.watch(authRepositoryProvider),
    projectRepository: ref.watch(projectRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
  );
}

/// EncryptionService provider
@Riverpod(keepAlive: true)
EncryptionService encryptionService(Ref ref) {
  final service = EncryptionService();
  // Initialize the service (generates master key if not exists)
  unawaited(service.initialize());
  return service;
}

/// RoutineRepository provider
@riverpod
RoutineRepository routineRepository(Ref ref) {
  return FirebaseRoutineRepository(ref.watch(firestoreProvider));
}

/// NotificationService provider (singleton)
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService();
}

/// StickyNote Hive box provider
@Riverpod(keepAlive: true)
Box<dynamic> stickyNoteBox(Ref ref) {
  return Hive.box('sticky_notes');
}

/// Reminder settings Hive box provider
@Riverpod(keepAlive: true)
Box<ReminderSettings> reminderSettingsBox(Ref ref) {
  return Hive.box<ReminderSettings>(HiveService.settingsBox);
}

/// StickyNoteRepository provider
@riverpod
StickyNoteRepository stickyNoteRepository(Ref ref) {
  final box = ref.watch(stickyNoteBoxProvider);
  return FirebaseStickyNoteRepository(
    ref.watch(firestoreProvider),
    ref.watch(encryptionServiceProvider),
    box,
  );
}

/// ReminderSettingsRepository provider
@riverpod
ReminderSettingsRepository reminderSettingsRepository(Ref ref) {
  final box = ref.watch(reminderSettingsBoxProvider);
  return HiveReminderSettingsRepository(box);
}

/// MindMap Hive box provider
@Riverpod(keepAlive: true)
Box<dynamic> mindMapBox(Ref ref) {
  return Hive.box('mind_maps');
}

/// MindMapNode Hive box provider
@Riverpod(keepAlive: true)
Box<dynamic> mindMapNodeBox(Ref ref) {
  return Hive.box('mind_map_nodes');
}

/// MindMapRepository provider
@riverpod
MindMapRepository mindMapRepository(Ref ref) {
  final mindMapBox = ref.watch(mindMapBoxProvider);
  final nodeBox = ref.watch(mindMapNodeBoxProvider);
  return FirebaseMindMapRepository(
    firestore: ref.watch(firestoreProvider),
    mindMapBox: mindMapBox,
    nodeBox: nodeBox,
  );
}

/// TaskReminderHelper provider (shared reminder scheduling logic)
@riverpod
TaskReminderHelper taskReminderHelper(Ref ref) {
  return TaskReminderHelper(
    ref.watch(notificationServiceProvider),
    ref.watch(reminderSettingsRepositoryProvider),
  );
}

/// InvitationRepository provider
@riverpod
InvitationRepository invitationRepository(Ref ref) {
  return FirebaseInvitationRepository(
    firestore: ref.watch(firestoreProvider),
    notificationRepository: ref.watch(notificationRepositoryProvider),
  );
}

/// ProjectMemberRepository provider
@riverpod
ProjectMemberRepository projectMemberRepository(Ref ref) {
  return FirebaseProjectMemberRepository(
    firestore: ref.watch(firestoreProvider),
    notificationRepository: ref.watch(notificationRepositoryProvider),
  );
}

/// NotificationRepository provider
@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return FirebaseNotificationRepository(ref.watch(firestoreProvider));
}

// State notifier providers for feature state management
// Example:
// @riverpod
// class AuthNotifier extends _$AuthNotifier {
//   @override
//   AuthState build() => const AuthState.initial();
//
//   Future<void> signIn(String email, String password) async {
//     // Implementation
//   }
// }

class QuickActionCommand {
  QuickActionCommand({required this.type, this.metadata});

  final String type;
  final Map<String, Object?>? metadata;
}

@Riverpod(keepAlive: true)
class QuickActionSelection extends _$QuickActionSelection {
  bool _pending = false;

  @override
  QuickActionCommand? build() => null;

  void setAction(String type, {Map<String, Object?>? metadata}) {
    if (_pending) return;
    state = QuickActionCommand(type: type, metadata: metadata);
    _pending = true;
  }

  void markHandled() {
    state = null;
    _pending = false;
  }

  void reset() {
    state = null;
    _pending = false;
  }
}

@Riverpod(keepAlive: true)
QuickActionService quickActionService(Ref ref) {
  final service = QuickActionService(
    onAction: (actionType, metadata) {
      ref
          .read(quickActionSelectionProvider.notifier)
          .setAction(actionType, metadata: metadata);
    },
  );

  unawaited(service.initialize());

  return service;
}

@Riverpod(keepAlive: true)
TileActionService tileActionService(Ref ref) {
  final service = TileActionService(
    onAction: (actionType, metadata) {
      ref
          .read(quickActionSelectionProvider.notifier)
          .setAction(actionType, metadata: metadata);
    },
  );

  unawaited(service.initialize());
  ref.onDispose(() => unawaited(service.dispose()));

  return service;
}
