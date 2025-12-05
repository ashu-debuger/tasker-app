# Development Task Board

Purpose: Central place for AI agent and developers to track work items. Update statuses by moving tasks between sections. Add metadata inline using bracket tags.

Metadata Tags (optional):

- [P1] / [P2] / [P3] = Priority
- [EST:2h] = Estimated time
- [DEP:auth] = Depends on another task key
- [OWNER:unassigned] = Assign an owner
- [BLOCKED:reason] = Blocker description
- [DONE:YYYY-MM-DD] = Completion date (agent fills when moved to Complete)

Conventions:

- Keep granular tasks ("one sitting" size where possible).
- When a task moves to Complete, copy it verbatim under Complete and append [DONE:date].
- If you create new tasks, put them first in Upcoming unless they begin immediately.

---

## Complete

1. Create feature-oriented folder structure under `lib/src` [P1] [EST:1h] [DONE:2025-11-13]
2. Add initial dependencies to `pubspec.yaml` (flutter_riverpod, riverpod_annotation, equatable, firebase_core, firebase_auth, cloud_firestore, hive, hive_flutter, json_serializable, build_runner, riverpod_generator, intl) [P1] [EST:30m] [DONE:2025-11-13]
3. Initialize Firebase project & integrate (Android + iOS) (flutterfire configure; add google-services.json & GoogleService-Info.plist; generate `firebase_options.dart`) [P1] [EST:2h] [DONE:2025-11-13]
4. Set up Riverpod providers (Firebase instances in lib/src/core/providers/providers.dart) [P2] [EST:45m] [DEP:folder-structure] [DONE:2025-11-13]
5. Configure basic navigation (go_router; implement AppRouter) [P1] [EST:1h] [DEP:folder-structure] [DONE:2025-11-13]
6. Create User model (`app_user.dart`) with serialization [P1] [EST:30m] [DONE:2025-11-13]
7. Implement AuthRepository interface + FirebaseAuth implementation [P1] [EST:1h] [DEP:firebase-init] [DONE:2025-11-13]
8. Implement AuthNotifier (AsyncNotifier with methods: signIn, signUp, signOut; states via AsyncValue<AppUser>) [P1] [EST:1h] [DEP:auth-repo] [DONE:2025-11-13]
9. Build UI: SplashScreen (checks auth state) + SignInScreen + SignUpScreen (form validation, error handling) [P1] [EST:2h] [DEP:auth-notifier] [DONE:2025-11-13]
10. Wire Riverpod providers & initial theme in `main.dart` [P1] [EST:30m] [DEP:auth-notifier] [DONE:2025-11-13]
11. Draft Firestore security rules outline for auth & projects (not final) [P2] [EST:45m] [DEP:firebase-init] [DONE:2025-11-13]
12. Define data models: Project (id, name, description, members, createdAt), Task (id, projectId, title, description, dueDate, status, assignees, createdAt), Subtask (id, taskId, title, status) [P1] [EST:1h] [DONE:2025-11-13]
13. Serialization & fromFirestore/toFirestore mappers for models [P1] [EST:45m] [DEP:models] [DONE:2025-11-13]
14. ProjectRepository (CRUD + streamProjectsForUser) [P1] [EST:1.5h] [DEP:models] [DONE:2025-11-13]
15. TaskRepository (CRUD + streamTasksForProject) [P1] [EST:1.5h] [DEP:models] [DONE:2025-11-13]
16. ProjectListNotifier (AsyncNotifierProvider for loading & streaming projects) [P1] [EST:45m] [DEP:project-repo] [DONE:2025-11-13]
17. ProjectDetailNotifier (load project + tasks with AsyncNotifier) [P2] [EST:1h] [DEP:task-repo] [DONE:2025-11-13]
18. TaskDetailNotifier (load + update subtasks + progress calc with AsyncNotifier) [P2] [EST:1h] [DEP:task-repo] [DONE:2025-11-13]
19. UI: ProjectsListScreen (list + create project dialog) [P1] [EST:1h] [DEP:project-list-notifier] [DONE:2025-11-13]
20. UI: ProjectDetailScreen (tasks list, project metadata, create task dialog, status filtering) [P1] [EST:1h] [DEP:project-detail-notifier] [DONE:2025-11-13]
21. UI: TaskDetailScreen (subtasks, status changes, progress bar) [P2] [EST:1h] [DEP:task-detail-notifier] [DONE:2025-11-13]
22. Progress percentage utility (completed / total) [P2] [EST:30m] [DEP:task-detail-notifier] [DONE:2025-11-13]
23. Define task status enum (Pending, InProgress, Completed) & integrate with UI filters [P2] [EST:30m] [DEP:models] [DONE:2025-11-13]
24. Seed sample data script for local dev (conditional dev mode) [P3] [EST:45m] [DONE:2025-11-13]
25. Basic Chat model (id, projectId, senderId, text, createdAt, encrypted? flag) [P2] [EST:30m] [DONE:2025-11-13]
26. ChatRepository (sendMessage, streamMessages) [P2] [EST:1h] [DEP:chat-model] [DONE:2025-11-13]
27. ChatNotifier (AsyncNotifier for sending messages & streaming) [P2] [EST:45m] [DEP:chat-repo] [DONE:2025-11-13]
28. ChatScreen UI (list + input + scroll) [P2] [EST:1h] [DEP:chat-notifier] [DONE:2025-11-13]
29. Error handling pattern (AppException base + mapping) [P2] [EST:45m] [DEP:repositories] [DONE:2025-11-13]
30. Logging setup (simple logger / Firebase Crashlytics placeholder) [P3] [EST:30m] [DONE:2025-11-13]
31. Unit tests: AuthRepository & AuthNotifier [P1] [EST:1h] [DEP:auth-notifier] [DONE:2025-11-13]
32. Unit tests: ProjectRepository & ProjectListNotifier [P2] [EST:1h] [DEP:project-list-notifier] [DONE:2025-11-13]
33. Unit tests: TaskRepository & TaskDetailNotifier [P2] [EST:1h] [DEP:task-detail-notifier] [DONE:2025-11-13]
34. Integration test: Sign in flow & project creation [P2] [EST:1.5h] [DEP:auth-ui] [DONE:2025-11-13]
35. CI pipeline skeleton (format, analyze, test) [P3] [EST:1h] [DONE:2025-11-13]
36. Calendar agenda context chips + reschedule workflow [P2] [DONE:2025-11-15]
37. Calendar project filtering toggle [P2] [DONE:2025-11-15]
38. Keep reminders in sync when rescheduling calendar tasks [P2] [DONE:2025-11-15]
39. Calendar multi-project filtering support [P2] [DONE:2025-11-15]
40. Global task reminder helper + CRUD integration [P2] [DONE:2025-11-15]
41. Reminder settings model + storage + UI + helpers (RS-1..RS-7) [P1] [DONE:2025-11-15]
42. AI heuristic task suggestions + project detail integration [P2] [DONE:2025-11-16]

---

## Current (Active Work In Progress)

🎉 **Phase 1 Complete!** All 35 core tasks finished.

Ready for the next Phase 2 enhancement.

---

## Upcoming (Phase 2 - Advanced Features)

Encryption, advanced routines, and collaborative features.

---

## Notes / Scratchpad

- After Phase 1 completion, move encryption and advanced routine features into Current for Phase 2.
- Using go_router for navigation (decided 2025-11-13).
- Using Riverpod for state management (decided 2025-11-13 for better performance).
- Confirm Firestore rules before public beta.
