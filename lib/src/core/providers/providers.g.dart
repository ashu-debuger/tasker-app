// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Auth instance provider

@ProviderFor(firebaseAuth)
const firebaseAuthProvider = FirebaseAuthProvider._();

/// Firebase Auth instance provider

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  /// Firebase Auth instance provider
  const FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'912368c3df3f72e4295bf7a8cda93b9c5749d923';

/// Firestore instance provider

@ProviderFor(firestore)
const firestoreProvider = FirestoreProvider._();

/// Firestore instance provider

final class FirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  /// Firestore instance provider
  const FirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firestoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firestoreHash() => r'0e25e335c5657f593fc1baf3d9fd026e70bca7fa';

/// Current Firebase user stream provider

@ProviderFor(authStateChanges)
const authStateChangesProvider = AuthStateChangesProvider._();

/// Current Firebase user stream provider

final class AuthStateChangesProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Current Firebase user stream provider
  const AuthStateChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateChangesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateChangesHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authStateChanges(ref);
  }
}

String _$authStateChangesHash() => r'5f8861723c359af3f00d0995225ba1df8c413368';

/// AuthRepository provider

@ProviderFor(authRepository)
const authRepositoryProvider = AuthRepositoryProvider._();

/// AuthRepository provider

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// AuthRepository provider
  const AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'4905d569f1c870d18db35654c0fcdc3f099c466e';

/// ProjectRepository provider

@ProviderFor(projectRepository)
const projectRepositoryProvider = ProjectRepositoryProvider._();

/// ProjectRepository provider

final class ProjectRepositoryProvider
    extends
        $FunctionalProvider<
          ProjectRepository,
          ProjectRepository,
          ProjectRepository
        >
    with $Provider<ProjectRepository> {
  /// ProjectRepository provider
  const ProjectRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProjectRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProjectRepository create(Ref ref) {
    return projectRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectRepository>(value),
    );
  }
}

String _$projectRepositoryHash() => r'bb9486360f9f86d54895939a96a917289d3f660e';

/// TaskRepository provider

@ProviderFor(taskRepository)
const taskRepositoryProvider = TaskRepositoryProvider._();

/// TaskRepository provider

final class TaskRepositoryProvider
    extends $FunctionalProvider<TaskRepository, TaskRepository, TaskRepository>
    with $Provider<TaskRepository> {
  /// TaskRepository provider
  const TaskRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskRepositoryHash();

  @$internal
  @override
  $ProviderElement<TaskRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaskRepository create(Ref ref) {
    return taskRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskRepository>(value),
    );
  }
}

String _$taskRepositoryHash() => r'9d781f82c20079bf64b11bb6923aa03942ab40a4';

/// ChatRepository provider

@ProviderFor(chatRepository)
const chatRepositoryProvider = ChatRepositoryProvider._();

/// ChatRepository provider

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  /// ChatRepository provider
  const ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'7992cb50d69f3e8702990d387311b790473368c5';

/// DevDataSeeder provider (debug mode only)

@ProviderFor(devDataSeeder)
const devDataSeederProvider = DevDataSeederProvider._();

/// DevDataSeeder provider (debug mode only)

final class DevDataSeederProvider
    extends $FunctionalProvider<DevDataSeeder, DevDataSeeder, DevDataSeeder>
    with $Provider<DevDataSeeder> {
  /// DevDataSeeder provider (debug mode only)
  const DevDataSeederProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devDataSeederProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devDataSeederHash();

  @$internal
  @override
  $ProviderElement<DevDataSeeder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DevDataSeeder create(Ref ref) {
    return devDataSeeder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DevDataSeeder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DevDataSeeder>(value),
    );
  }
}

String _$devDataSeederHash() => r'c9641cf38a1b42f02caba4264e5a84e4d9d481d6';

/// EncryptionService provider

@ProviderFor(encryptionService)
const encryptionServiceProvider = EncryptionServiceProvider._();

/// EncryptionService provider

final class EncryptionServiceProvider
    extends
        $FunctionalProvider<
          EncryptionService,
          EncryptionService,
          EncryptionService
        >
    with $Provider<EncryptionService> {
  /// EncryptionService provider
  const EncryptionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'encryptionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$encryptionServiceHash();

  @$internal
  @override
  $ProviderElement<EncryptionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EncryptionService create(Ref ref) {
    return encryptionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EncryptionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EncryptionService>(value),
    );
  }
}

String _$encryptionServiceHash() => r'288943b36a333b439551781b34b340d21c30b236';

/// RoutineRepository provider

@ProviderFor(routineRepository)
const routineRepositoryProvider = RoutineRepositoryProvider._();

/// RoutineRepository provider

final class RoutineRepositoryProvider
    extends
        $FunctionalProvider<
          RoutineRepository,
          RoutineRepository,
          RoutineRepository
        >
    with $Provider<RoutineRepository> {
  /// RoutineRepository provider
  const RoutineRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routineRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routineRepositoryHash();

  @$internal
  @override
  $ProviderElement<RoutineRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RoutineRepository create(Ref ref) {
    return routineRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoutineRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoutineRepository>(value),
    );
  }
}

String _$routineRepositoryHash() => r'13c00d41d2495e7c0738b433b33cadd7db663b40';

/// NotificationService provider (singleton)

@ProviderFor(notificationService)
const notificationServiceProvider = NotificationServiceProvider._();

/// NotificationService provider (singleton)

final class NotificationServiceProvider
    extends
        $FunctionalProvider<
          NotificationService,
          NotificationService,
          NotificationService
        >
    with $Provider<NotificationService> {
  /// NotificationService provider (singleton)
  const NotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationService create(Ref ref) {
    return notificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationService>(value),
    );
  }
}

String _$notificationServiceHash() =>
    r'58da87941dbfa08925105dcc4d74091ee38c8593';

/// StickyNote Hive box provider

@ProviderFor(stickyNoteBox)
const stickyNoteBoxProvider = StickyNoteBoxProvider._();

/// StickyNote Hive box provider

final class StickyNoteBoxProvider
    extends $FunctionalProvider<Box<dynamic>, Box<dynamic>, Box<dynamic>>
    with $Provider<Box<dynamic>> {
  /// StickyNote Hive box provider
  const StickyNoteBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stickyNoteBoxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stickyNoteBoxHash();

  @$internal
  @override
  $ProviderElement<Box<dynamic>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Box<dynamic> create(Ref ref) {
    return stickyNoteBox(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Box<dynamic> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Box<dynamic>>(value),
    );
  }
}

String _$stickyNoteBoxHash() => r'73fbfa64cce541e320165149006b8d9bfe5fb03e';

/// Reminder settings Hive box provider

@ProviderFor(reminderSettingsBox)
const reminderSettingsBoxProvider = ReminderSettingsBoxProvider._();

/// Reminder settings Hive box provider

final class ReminderSettingsBoxProvider
    extends
        $FunctionalProvider<
          Box<ReminderSettings>,
          Box<ReminderSettings>,
          Box<ReminderSettings>
        >
    with $Provider<Box<ReminderSettings>> {
  /// Reminder settings Hive box provider
  const ReminderSettingsBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSettingsBoxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSettingsBoxHash();

  @$internal
  @override
  $ProviderElement<Box<ReminderSettings>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Box<ReminderSettings> create(Ref ref) {
    return reminderSettingsBox(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Box<ReminderSettings> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Box<ReminderSettings>>(value),
    );
  }
}

String _$reminderSettingsBoxHash() =>
    r'2e1b87f8aabe4bd742f5073e42c9116c62631852';

/// StickyNoteRepository provider

@ProviderFor(stickyNoteRepository)
const stickyNoteRepositoryProvider = StickyNoteRepositoryProvider._();

/// StickyNoteRepository provider

final class StickyNoteRepositoryProvider
    extends
        $FunctionalProvider<
          StickyNoteRepository,
          StickyNoteRepository,
          StickyNoteRepository
        >
    with $Provider<StickyNoteRepository> {
  /// StickyNoteRepository provider
  const StickyNoteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stickyNoteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stickyNoteRepositoryHash();

  @$internal
  @override
  $ProviderElement<StickyNoteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StickyNoteRepository create(Ref ref) {
    return stickyNoteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StickyNoteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StickyNoteRepository>(value),
    );
  }
}

String _$stickyNoteRepositoryHash() =>
    r'eeed48b5ca65c03cd18a99c9a892ba7cce33334e';

/// ReminderSettingsRepository provider

@ProviderFor(reminderSettingsRepository)
const reminderSettingsRepositoryProvider =
    ReminderSettingsRepositoryProvider._();

/// ReminderSettingsRepository provider

final class ReminderSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          ReminderSettingsRepository,
          ReminderSettingsRepository,
          ReminderSettingsRepository
        >
    with $Provider<ReminderSettingsRepository> {
  /// ReminderSettingsRepository provider
  const ReminderSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSettingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReminderSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReminderSettingsRepository create(Ref ref) {
    return reminderSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderSettingsRepository>(value),
    );
  }
}

String _$reminderSettingsRepositoryHash() =>
    r'7ae7ef670c646c259b671612948a5402943e085e';

/// MindMap Hive box provider

@ProviderFor(mindMapBox)
const mindMapBoxProvider = MindMapBoxProvider._();

/// MindMap Hive box provider

final class MindMapBoxProvider
    extends $FunctionalProvider<Box<dynamic>, Box<dynamic>, Box<dynamic>>
    with $Provider<Box<dynamic>> {
  /// MindMap Hive box provider
  const MindMapBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mindMapBoxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mindMapBoxHash();

  @$internal
  @override
  $ProviderElement<Box<dynamic>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Box<dynamic> create(Ref ref) {
    return mindMapBox(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Box<dynamic> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Box<dynamic>>(value),
    );
  }
}

String _$mindMapBoxHash() => r'7b53b56575fec442ddbc1311d55bf27c671b2424';

/// MindMapNode Hive box provider

@ProviderFor(mindMapNodeBox)
const mindMapNodeBoxProvider = MindMapNodeBoxProvider._();

/// MindMapNode Hive box provider

final class MindMapNodeBoxProvider
    extends $FunctionalProvider<Box<dynamic>, Box<dynamic>, Box<dynamic>>
    with $Provider<Box<dynamic>> {
  /// MindMapNode Hive box provider
  const MindMapNodeBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mindMapNodeBoxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mindMapNodeBoxHash();

  @$internal
  @override
  $ProviderElement<Box<dynamic>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Box<dynamic> create(Ref ref) {
    return mindMapNodeBox(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Box<dynamic> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Box<dynamic>>(value),
    );
  }
}

String _$mindMapNodeBoxHash() => r'26ee97b82ccfcc55dcd1cd9dff54ca47d62d6e4e';

/// MindMapRepository provider

@ProviderFor(mindMapRepository)
const mindMapRepositoryProvider = MindMapRepositoryProvider._();

/// MindMapRepository provider

final class MindMapRepositoryProvider
    extends
        $FunctionalProvider<
          MindMapRepository,
          MindMapRepository,
          MindMapRepository
        >
    with $Provider<MindMapRepository> {
  /// MindMapRepository provider
  const MindMapRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mindMapRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mindMapRepositoryHash();

  @$internal
  @override
  $ProviderElement<MindMapRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MindMapRepository create(Ref ref) {
    return mindMapRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MindMapRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MindMapRepository>(value),
    );
  }
}

String _$mindMapRepositoryHash() => r'8a3631d53a2edf9c15a553573d8e44cd509336d3';

/// TaskReminderHelper provider (shared reminder scheduling logic)

@ProviderFor(taskReminderHelper)
const taskReminderHelperProvider = TaskReminderHelperProvider._();

/// TaskReminderHelper provider (shared reminder scheduling logic)

final class TaskReminderHelperProvider
    extends
        $FunctionalProvider<
          TaskReminderHelper,
          TaskReminderHelper,
          TaskReminderHelper
        >
    with $Provider<TaskReminderHelper> {
  /// TaskReminderHelper provider (shared reminder scheduling logic)
  const TaskReminderHelperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskReminderHelperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskReminderHelperHash();

  @$internal
  @override
  $ProviderElement<TaskReminderHelper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TaskReminderHelper create(Ref ref) {
    return taskReminderHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskReminderHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskReminderHelper>(value),
    );
  }
}

String _$taskReminderHelperHash() =>
    r'964c967d42e2be0ea5c39e21485f6acd35a7685b';

/// InvitationRepository provider

@ProviderFor(invitationRepository)
const invitationRepositoryProvider = InvitationRepositoryProvider._();

/// InvitationRepository provider

final class InvitationRepositoryProvider
    extends
        $FunctionalProvider<
          InvitationRepository,
          InvitationRepository,
          InvitationRepository
        >
    with $Provider<InvitationRepository> {
  /// InvitationRepository provider
  const InvitationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invitationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invitationRepositoryHash();

  @$internal
  @override
  $ProviderElement<InvitationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InvitationRepository create(Ref ref) {
    return invitationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvitationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvitationRepository>(value),
    );
  }
}

String _$invitationRepositoryHash() =>
    r'12d9e8f538c1b178bbe58d7a4996d14ad340e046';

/// ProjectMemberRepository provider

@ProviderFor(projectMemberRepository)
const projectMemberRepositoryProvider = ProjectMemberRepositoryProvider._();

/// ProjectMemberRepository provider

final class ProjectMemberRepositoryProvider
    extends
        $FunctionalProvider<
          ProjectMemberRepository,
          ProjectMemberRepository,
          ProjectMemberRepository
        >
    with $Provider<ProjectMemberRepository> {
  /// ProjectMemberRepository provider
  const ProjectMemberRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectMemberRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectMemberRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProjectMemberRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProjectMemberRepository create(Ref ref) {
    return projectMemberRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectMemberRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectMemberRepository>(value),
    );
  }
}

String _$projectMemberRepositoryHash() =>
    r'dbffd3481fcda9b8b3575b7598a2cb0c66653d1b';

/// NotificationRepository provider

@ProviderFor(notificationRepository)
const notificationRepositoryProvider = NotificationRepositoryProvider._();

/// NotificationRepository provider

final class NotificationRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationRepository,
          NotificationRepository,
          NotificationRepository
        >
    with $Provider<NotificationRepository> {
  /// NotificationRepository provider
  const NotificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationRepository create(Ref ref) {
    return notificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationRepository>(value),
    );
  }
}

String _$notificationRepositoryHash() =>
    r'7d956ab41fc12edd57e12d82e497e233d51ba5d6';

/// PushNotificationService provider

@ProviderFor(pushNotificationService)
const pushNotificationServiceProvider = PushNotificationServiceProvider._();

/// PushNotificationService provider

final class PushNotificationServiceProvider
    extends
        $FunctionalProvider<
          PushNotificationService,
          PushNotificationService,
          PushNotificationService
        >
    with $Provider<PushNotificationService> {
  /// PushNotificationService provider
  const PushNotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushNotificationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushNotificationServiceHash();

  @$internal
  @override
  $ProviderElement<PushNotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushNotificationService create(Ref ref) {
    return pushNotificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushNotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushNotificationService>(value),
    );
  }
}

String _$pushNotificationServiceHash() =>
    r'19b3f90803232d95ad8b78a5536ce82240c7efab';

/// NotificationListenerService provider

@ProviderFor(notificationListenerService)
const notificationListenerServiceProvider =
    NotificationListenerServiceProvider._();

/// NotificationListenerService provider

final class NotificationListenerServiceProvider
    extends
        $FunctionalProvider<
          NotificationListenerService,
          NotificationListenerService,
          NotificationListenerService
        >
    with $Provider<NotificationListenerService> {
  /// NotificationListenerService provider
  const NotificationListenerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationListenerServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationListenerServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationListenerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationListenerService create(Ref ref) {
    return notificationListenerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationListenerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationListenerService>(value),
    );
  }
}

String _$notificationListenerServiceHash() =>
    r'a9f197fa7f5fa9ebd93df5c693ffde755c10c587';

@ProviderFor(QuickActionSelection)
const quickActionSelectionProvider = QuickActionSelectionProvider._();

final class QuickActionSelectionProvider
    extends $NotifierProvider<QuickActionSelection, QuickActionCommand?> {
  const QuickActionSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickActionSelectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickActionSelectionHash();

  @$internal
  @override
  QuickActionSelection create() => QuickActionSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuickActionCommand? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuickActionCommand?>(value),
    );
  }
}

String _$quickActionSelectionHash() =>
    r'cfe9ae3ffd2064416eeb7a763808f29faf9ca980';

abstract class _$QuickActionSelection extends $Notifier<QuickActionCommand?> {
  QuickActionCommand? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<QuickActionCommand?, QuickActionCommand?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuickActionCommand?, QuickActionCommand?>,
              QuickActionCommand?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(quickActionService)
const quickActionServiceProvider = QuickActionServiceProvider._();

final class QuickActionServiceProvider
    extends
        $FunctionalProvider<
          QuickActionService,
          QuickActionService,
          QuickActionService
        >
    with $Provider<QuickActionService> {
  const QuickActionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickActionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickActionServiceHash();

  @$internal
  @override
  $ProviderElement<QuickActionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  QuickActionService create(Ref ref) {
    return quickActionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuickActionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuickActionService>(value),
    );
  }
}

String _$quickActionServiceHash() =>
    r'938e5de3eafd5a0bde18c67942ccc01c48d737d3';

@ProviderFor(tileActionService)
const tileActionServiceProvider = TileActionServiceProvider._();

final class TileActionServiceProvider
    extends
        $FunctionalProvider<
          TileActionService,
          TileActionService,
          TileActionService
        >
    with $Provider<TileActionService> {
  const TileActionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tileActionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tileActionServiceHash();

  @$internal
  @override
  $ProviderElement<TileActionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TileActionService create(Ref ref) {
    return tileActionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TileActionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TileActionService>(value),
    );
  }
}

String _$tileActionServiceHash() => r'b9267110de6b6ccc7e490ea406745258e27bd7f2';
