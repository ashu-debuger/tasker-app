# 📁 Projects

Collaborative project management in Tasker.

---

## Overview

Projects provide:
- 📁 Organize related tasks
- 👥 Team collaboration
- 🔐 Role-based access control
- 💬 Real-time chat
- 📊 Progress tracking

---

## Features

### Project Properties
| Property      | Type    | Description         |
| ------------- | ------- | ------------------- |
| `name`        | String  | Project name        |
| `description` | String? | Project description |
| `ownerId`     | String  | Creator's user ID   |
| `members`     | List    | Member user IDs     |
| `memberRoles` | Map     | Role assignments    |

### Member Roles
| Role   | Permissions                  |
| ------ | ---------------------------- |
| Owner  | Full control, delete project |
| Admin  | Manage members, settings     |
| Editor | Create/edit tasks            |
| Viewer | Read-only access             |

---

## Data Model

```dart
@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    String? description,
    required String ownerId,
    required List<String> members,
    required Map<String, ProjectRole> memberRoles,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Project;
}

enum ProjectRole { owner, admin, editor, viewer }
```

---

## Usage

### Create Project
```dart
final project = Project(
  id: const Uuid().v4(),
  name: 'Mobile App Launch',
  description: 'Q1 2025 app release',
  ownerId: currentUserId,
  members: [currentUserId],
  memberRoles: {currentUserId: ProjectRole.owner},
  createdAt: DateTime.now(),
);

await ref.read(projectListProvider.notifier).createProject(project);
```

### Invite Member
```dart
await ref.read(projectProvider(projectId).notifier).inviteMember(
  email: 'teammate@example.com',
  role: ProjectRole.editor,
);
```

### Update Role
```dart
await ref.read(projectProvider(projectId).notifier).updateMemberRole(
  userId: memberId,
  newRole: ProjectRole.admin,
);
```

---

## Invitation System

```dart
@freezed
class Invitation with _$Invitation {
  const factory Invitation({
    required String id,
    required String projectId,
    required String inviterId,
    required String inviteeEmail,
    required ProjectRole role,
    required InvitationStatus status,
    required DateTime createdAt,
    DateTime? respondedAt,
  }) = _Invitation;
}

enum InvitationStatus { pending, accepted, declined }
```

### Send Invitation
```dart
final invitation = Invitation(
  id: const Uuid().v4(),
  projectId: project.id,
  inviterId: currentUserId,
  inviteeEmail: 'new@member.com',
  role: ProjectRole.editor,
  status: InvitationStatus.pending,
  createdAt: DateTime.now(),
);
```

---

## Project Chat

Real-time messaging within projects:

```dart
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String projectId,
    required String senderId,
    required String content,
    required DateTime createdAt,
    @Default(false) bool isDeleted,
  }) = _ChatMessage;
}
```

---

## Routes

| Route                   | Screen              | Purpose           |
| ----------------------- | ------------------- | ----------------- |
| `/projects`             | ProjectListScreen   | View all projects |
| `/projects/:id`         | ProjectDetailScreen | View project      |
| `/projects/:id/tasks`   | ProjectTasksScreen  | Project tasks     |
| `/projects/:id/chat`    | ProjectChatScreen   | Project chat      |
| `/projects/:id/members` | MembersScreen       | Manage members    |

---

## Related Docs

- [Tasks Guide](./tasks.md) - Task management
- [Chat Guide](./chat.md) - Project messaging
- [Collaboration](../development/collaboration-features.md) - Multi-user features

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Features Index](../README.md#-features)**

</div>
