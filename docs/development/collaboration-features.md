# Collaboration Features Implementation Plan

## Overview
This document outlines the implementation plan for adding collaboration features to the Tasker app, including team member management, task assignment, and notifications for collaborative workflows.

## Features to Implement

### 1. Add Members by Email with Request System

#### 1.1 Data Models

**MemberInvitation Model** (`lib/src/features/projects/domain/models/member_invitation.dart`)
```dart
class MemberInvitation {
  final String id;
  final String projectId;
  final String projectName;
  final String invitedByUserId;
  final String invitedByUserName;
  final String invitedEmail;
  final String? invitedUserId; // Set when user with this email exists
  final InvitationStatus status; // pending, accepted, declined
  final DateTime createdAt;
  final DateTime? respondedAt;
  final ProjectRole role; // viewer, editor, admin
}

enum InvitationStatus {
  pending,
  accepted,
  declined,
  cancelled
}

enum ProjectRole {
  viewer,   // Can view tasks only
  editor,   // Can create/edit tasks
  admin     // Can manage members and project settings
}
```

**ProjectMember Model** (`lib/src/features/projects/domain/models/project_member.dart`)
```dart
class ProjectMember {
  final String userId;
  final String email;
  final String displayName;
  final String? photoUrl;
  final ProjectRole role;
  final DateTime addedAt;
  final String addedBy;
}
```

**Updated Project Model** (`lib/src/features/projects/domain/models/project.dart`)
```dart
class Project {
  // ... existing fields
  final List<ProjectMember> members;
  final String ownerId; // Creator of the project
  final Map<String, ProjectRole> memberRoles; // userId -> role mapping
}
```

#### 1.2 Firestore Structure

**Collection: `projects/{projectId}/members`**
```json
{
  "userId": "user123",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "role": "editor",
  "addedAt": "2025-11-21T10:00:00Z",
  "addedBy": "owner123"
}
```

**Collection: `invitations`**
```json
{
  "id": "inv123",
  "projectId": "proj123",
  "projectName": "My Project",
  "invitedByUserId": "user123",
  "invitedByUserName": "John Doe",
  "invitedEmail": "newuser@example.com",
  "invitedUserId": "user456", // null if user doesn't exist yet
  "status": "pending",
  "createdAt": "2025-11-21T10:00:00Z",
  "respondedAt": null,
  "role": "editor"
}
```

**Collection: `users/{userId}/pendingInvitations`**
```json
{
  "invitationId": "inv123",
  "projectId": "proj123",
  "projectName": "My Project",
  "invitedBy": "John Doe",
  "createdAt": "2025-11-21T10:00:00Z"
}
```

#### 1.3 UI Components

**Member Management Dialog** (`lib/src/features/projects/presentation/widgets/member_management_dialog.dart`)
- Show current members list with roles
- "Add Member" button → opens invite dialog
- Each member row shows:
  - Avatar, name, email
  - Role badge (Viewer/Editor/Admin)
  - Remove button (only for admins)
  - Role change dropdown (only for admins)

**Invite Member Dialog** (`lib/src/features/projects/presentation/widgets/invite_member_dialog.dart`)
- Email input field with validation
- Role selector dropdown (Viewer, Editor, Admin)
- Personal message (optional)
- "Send Invitation" button
- Shows list of pending invitations below with cancel option

**Invitation Request Badge** (on Projects List Screen)
- Badge showing count of pending invitations
- Tapping opens invitations bottom sheet

**Invitations Bottom Sheet** (`lib/src/features/projects/presentation/widgets/invitations_sheet.dart`)
- List of pending invitations
- Each invitation card shows:
  - Project name and icon
  - Invited by (name + avatar)
  - Role being offered
  - Date invited
  - Accept/Decline buttons
  - View project details option

#### 1.4 Repository Methods

**InvitationRepository** (`lib/src/features/projects/data/repositories/invitation_repository.dart`)
```dart
abstract class InvitationRepository {
  // Send invitation
  Future<void> sendInvitation({
    required String projectId,
    required String email,
    required ProjectRole role,
    String? message,
  });
  
  // Get invitations for a user (by email or userId)
  Stream<List<MemberInvitation>> getUserInvitations(String userId);
  
  // Get pending invitations for a project
  Stream<List<MemberInvitation>> getProjectInvitations(String projectId);
  
  // Accept invitation
  Future<void> acceptInvitation(String invitationId);
  
  // Decline invitation
  Future<void> declineInvitation(String invitationId);
  
  // Cancel invitation (by sender)
  Future<void> cancelInvitation(String invitationId);
}
```

**ProjectMemberRepository** (`lib/src/features/projects/data/repositories/project_member_repository.dart`)
```dart
abstract class ProjectMemberRepository {
  // Add member to project
  Future<void> addMember({
    required String projectId,
    required String userId,
    required ProjectRole role,
  });
  
  // Remove member from project
  Future<void> removeMember(String projectId, String userId);
  
  // Update member role
  Future<void> updateMemberRole({
    required String projectId,
    required String userId,
    required ProjectRole newRole,
  });
  
  // Get project members
  Stream<List<ProjectMember>> getProjectMembers(String projectId);
  
  // Check user's role in project
  Future<ProjectRole?> getUserRole(String projectId, String userId);
}
```

---

### 2. Request Options on Project Home Page

#### 2.1 UI Layout Changes

**Projects List Screen Updates** (`lib/src/features/projects/presentation/screens/projects_list_screen.dart`)

Add new app bar actions:
```dart
AppBar(
  title: Text('Projects'),
  actions: [
    // Invitation badge with count
    Badge(
      count: invitationCount,
      child: IconButton(
        icon: Icon(Icons.mail_outline),
        onPressed: () => _showInvitationsSheet(),
      ),
    ),
    // Notification bell
    IconButton(
      icon: Icon(Icons.notifications_outlined),
      onPressed: () => context.go(AppRoutes.notifications),
    ),
    // Profile menu
    IconButton(
      icon: CircleAvatar(child: Icon(Icons.person)),
      onPressed: () => _showProfileMenu(),
    ),
  ],
)
```

**Project Card Updates**
- Show member avatars (first 3 members + count)
- Add "Shared" badge for projects with multiple members
- Show your role badge (Owner/Admin/Editor/Viewer)

#### 2.2 Invitations Sheet

**InvitationsSheet Widget** (`lib/src/features/projects/presentation/widgets/invitations_sheet.dart`)
```dart
class InvitationsSheet extends ConsumerWidget {
  - Header: "Project Invitations (3)"
  - Tabs: "Received" and "Sent" 
  
  Received Tab:
  - List of invitations where current user is invitee
  - Accept/Decline actions
  
  Sent Tab:
  - List of invitations sent by current user
  - Cancel option for pending invitations
  - Status indicator (Pending/Accepted/Declined)
}
```

---

### 3. Task Assignment

#### 3.1 Data Model Updates

**Updated Task Model** (`lib/src/features/tasks/domain/models/task.dart`)
```dart
class Task {
  // ... existing fields
  final String? assignedTo; // userId of assigned member
  final String? assignedToName; // Display name for quick access
  final String? assignedToEmail;
  final DateTime? assignedAt;
  final String? assignedBy; // userId who assigned
}
```

#### 3.2 UI Components

**Task Assignment Selector** (in Task Creation/Edit Dialog)
- Dropdown showing all project members
- "Unassigned" option (default)
- Shows member avatar + name
- Only available if user has editor/admin role

**Task Detail Screen Updates** (`lib/src/features/tasks/presentation/screens/task_detail_screen.dart`)
- "Assigned to" section showing:
  - Avatar and name of assigned member
  - Assignment date
  - Reassign button (if user has permission)
- If unassigned: "Assign to someone" button

**Task Card Updates** (in Project Detail Screen)
- Show small avatar of assigned member on task card
- Badge indicating "Assigned to you" for current user's tasks

**Task Filters** (in Project Detail Screen)
- Add filter options:
  - All tasks
  - My tasks (assigned to me)
  - Unassigned tasks
  - Tasks by member (sub-menu)

#### 3.3 Repository Methods

**TaskRepository Updates** (`lib/src/features/tasks/data/repositories/task_repository.dart`)
```dart
// Add new methods
Future<void> assignTask({
  required String projectId,
  required String taskId,
  required String userId,
});

Future<void> unassignTask({
  required String projectId,
  required String taskId,
});

Stream<List<Task>> getTasksAssignedToUser({
  required String userId,
  String? projectId, // Filter by project if provided
});
```

---

### 4. Notification System

#### 4.1 Notification Types

**NotificationType Enum** (`lib/src/core/notifications/notification_types.dart`)
```dart
enum NotificationType {
  // Invitation notifications
  invitationReceived,
  invitationAccepted,
  invitationDeclined,
  
  // Task assignment
  taskAssigned,
  taskReassigned,
  taskUnassigned,
  
  // Task updates (for assigned tasks)
  taskCompleted,
  taskCommentAdded,
  taskDueSoon,
  taskOverdue,
  
  // Member activity
  memberAdded,
  memberRemoved,
  memberRoleChanged,
  
  // Project updates
  projectShared,
  projectArchived,
}
```

#### 4.2 Notification Model

**AppNotification Model** (`lib/src/core/notifications/models/app_notification.dart`)
```dart
class AppNotification {
  final String id;
  final String userId; // Recipient
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl; // Avatar or project image
  final Map<String, dynamic> data; // Contextual data
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl; // Deep link to relevant screen
}
```

#### 4.3 Firestore Structure

**Collection: `users/{userId}/notifications`**
```json
{
  "id": "notif123",
  "userId": "user123",
  "type": "invitationReceived",
  "title": "Project Invitation",
  "body": "John Doe invited you to 'Marketing Campaign'",
  "imageUrl": "https://...",
  "data": {
    "invitationId": "inv123",
    "projectId": "proj123",
    "projectName": "Marketing Campaign",
    "invitedBy": "John Doe"
  },
  "createdAt": "2025-11-21T10:00:00Z",
  "isRead": false,
  "actionUrl": "/invitations"
}
```

#### 4.4 Notification Scenarios

**1. Invitation Received**
- Trigger: User sends invitation
- Recipient: Invited user (if account exists)
- Title: "Project Invitation"
- Body: "[Inviter] invited you to '[Project Name]'"
- Action: Open invitations sheet

**2. Invitation Accepted**
- Trigger: Invitee accepts invitation
- Recipient: Inviter
- Title: "Invitation Accepted"
- Body: "[User] accepted your invitation to '[Project Name]'"
- Action: Open project detail

**3. Invitation Declined**
- Trigger: Invitee declines invitation
- Recipient: Inviter
- Title: "Invitation Declined"
- Body: "[User] declined your invitation to '[Project Name]'"
- Action: Open project members

**4. Task Assigned**
- Trigger: Task is assigned to a member
- Recipient: Assigned member
- Title: "New Task Assigned"
- Body: "[Assigner] assigned you '[Task Name]' in [Project Name]"
- Action: Open task detail

**5. Task Reassigned**
- Trigger: Task is reassigned to different member
- Recipients: 
  - Old assignee: "Task reassigned"
  - New assignee: "Task assigned to you"
- Action: Open task detail

**6. Task Completed**
- Trigger: Assigned task is marked complete
- Recipient: Task creator (if different from assignee)
- Title: "Task Completed"
- Body: "[Assignee] completed '[Task Name]'"
- Action: Open task detail

**7. Member Added to Project**
- Trigger: New member added (invitation accepted)
- Recipients: All project members (except new member)
- Title: "New Team Member"
- Body: "[Member] joined '[Project Name]'"
- Action: Open project members

**8. Task Due Soon**
- Trigger: Task due in 24 hours (for assigned tasks)
- Recipient: Assigned member
- Title: "Task Due Soon"
- Body: "'[Task Name]' is due tomorrow"
- Action: Open task detail

#### 4.5 Push Notifications

**Firebase Cloud Messaging Setup**
- Store FCM tokens in `users/{userId}/fcmTokens` collection
- Support multiple devices per user
- Cloud Function triggers for:
  - Invitation events
  - Task assignment
  - Task updates
  - Project activity

**NotificationService Updates** (`lib/src/core/notifications/notification_service.dart`)
```dart
class NotificationService {
  // ... existing methods
  
  // Send in-app notification
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  });
  
  // Send push notification
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });
  
  // Mark as read
  Future<void> markAsRead(String notificationId);
  
  // Mark all as read
  Future<void> markAllAsRead(String userId);
  
  // Delete notification
  Future<void> deleteNotification(String notificationId);
}
```

#### 4.6 Notifications Screen

**New Screen: NotificationsScreen** (`lib/src/features/notifications/presentation/screens/notifications_screen.dart`)
- AppBar with "Mark all as read" action
- Tabs: "All" and "Unread"
- Grouped by date (Today, Yesterday, This Week, Earlier)
- Each notification card shows:
  - Avatar/icon based on type
  - Title and body
  - Timestamp (relative)
  - Unread indicator dot
  - Swipe to delete
  - Tap to navigate to related screen

---

## Implementation Order

### Phase 1: Core Infrastructure (Week 1)
1. Create data models (MemberInvitation, ProjectMember, AppNotification)
2. Update Firestore structure and rules
3. Create repository interfaces and implementations
4. Add notification service methods

### Phase 2: Member Management (Week 2)
1. Build invitation repository
2. Create member management UI (dialog, list)
3. Implement invite member flow
4. Build invitations sheet (received/sent)
5. Add accept/decline functionality
6. Test invitation workflow end-to-end

### Phase 3: Project Home Updates (Week 2-3)
1. Add invitation badge to app bar
2. Update project cards to show members
3. Add role badges and indicators
4. Implement invitation count provider
5. Test UI updates

### Phase 4: Task Assignment (Week 3)
1. Update Task model and Firestore structure
2. Add assignment selector to task dialogs
3. Update task detail screen with assignment info
4. Add task filters (my tasks, unassigned, etc.)
5. Implement assign/unassign repository methods
6. Test assignment workflow

### Phase 5: Notifications (Week 4)
1. Create NotificationsScreen
2. Implement in-app notification system
3. Add notification triggers for all events
4. Build notification cards and list
5. Implement mark as read functionality
6. Set up FCM for push notifications
7. Test all notification scenarios

### Phase 6: Testing & Polish (Week 5)
1. Write unit tests for repositories
2. Write widget tests for new components
3. Integration testing for workflows
4. Polish UI/UX
5. Performance optimization
6. Documentation updates

---

## Firestore Security Rules Updates

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Invitations
    match /invitations/{invitationId} {
      // Anyone can read their own invitations
      allow read: if request.auth != null && (
        resource.data.invitedEmail == request.auth.token.email ||
        resource.data.invitedUserId == request.auth.uid ||
        resource.data.invitedByUserId == request.auth.uid
      );
      
      // Only project admins can create invitations
      allow create: if request.auth != null && 
        isProjectAdmin(request.resource.data.projectId);
      
      // Invitee can update to accept/decline
      allow update: if request.auth != null && (
        resource.data.invitedUserId == request.auth.uid ||
        resource.data.invitedEmail == request.auth.token.email
      );
      
      // Inviter can delete (cancel)
      allow delete: if request.auth != null && 
        resource.data.invitedByUserId == request.auth.uid;
    }
    
    // Project members
    match /projects/{projectId}/members/{userId} {
      // Members can read all members
      allow read: if request.auth != null && isMember(projectId);
      
      // Only admins can add/remove members
      allow create, delete: if request.auth != null && 
        isProjectAdmin(projectId);
      
      // Only admins can update roles
      allow update: if request.auth != null && 
        isProjectAdmin(projectId);
    }
    
    // User notifications
    match /users/{userId}/notifications/{notificationId} {
      // Users can only read/update their own notifications
      allow read, update: if request.auth != null && 
        request.auth.uid == userId;
      
      // System can create notifications
      allow create: if request.auth != null;
      
      // Users can delete their notifications
      allow delete: if request.auth != null && 
        request.auth.uid == userId;
    }
    
    // Helper functions
    function isMember(projectId) {
      return exists(/databases/$(database)/documents/projects/$(projectId)/members/$(request.auth.uid));
    }
    
    function isProjectAdmin(projectId) {
      let member = get(/databases/$(database)/documents/projects/$(projectId)/members/$(request.auth.uid));
      return member.data.role in ['admin', 'owner'];
    }
  }
}
```

---

## State Management

### Providers to Create

1. **InvitationNotifier** (`lib/src/features/projects/presentation/notifiers/invitation_notifier.dart`)
   - Manages invitation state
   - Methods: sendInvitation, acceptInvitation, declineInvitation

2. **ProjectMembersNotifier** (`lib/src/features/projects/presentation/notifiers/project_members_notifier.dart`)
   - Manages project members
   - Methods: addMember, removeMember, updateRole

3. **NotificationNotifier** (`lib/src/features/notifications/presentation/notifiers/notification_notifier.dart`)
   - Manages notification state
   - Methods: markAsRead, markAllAsRead, deleteNotification

4. **UserInvitationsProvider** (Stream provider)
   - Provides stream of user's pending invitations
   - Used for badge count

---

## UI/UX Considerations

### Design Guidelines
- Use Material 3 components throughout
- Consistent color coding for roles:
  - Owner/Admin: Purple
  - Editor: Blue
  - Viewer: Gray
- Smooth animations for:
  - Invitation acceptance
  - Task assignment
  - Notification appearance
- Haptic feedback for important actions
- Loading states for async operations
- Error handling with user-friendly messages

### Accessibility
- Proper semantic labels for screen readers
- Sufficient color contrast
- Touch targets minimum 48x48dp
- Keyboard navigation support

---

## Testing Strategy

### Unit Tests
- Repository methods
- Notification logic
- Permission checks
- Data model serialization

### Widget Tests
- Invitation dialogs
- Member management UI
- Task assignment selector
- Notification cards

### Integration Tests
- Complete invitation workflow
- Task assignment and notification flow
- Multi-user scenarios
- Offline behavior

---

## Future Enhancements

1. **Real-time Presence**
   - Show which members are online
   - See who is viewing a task

2. **Activity Feed**
   - Timeline of project activities
   - Filter by member or activity type

3. **@Mentions in Comments**
   - Tag members in task comments
   - Send notification to mentioned users

4. **Team Templates**
   - Save member groups as templates
   - Quick add entire teams to projects

5. **Permission Levels**
   - More granular permissions
   - Custom roles

6. **Invitation Links**
   - Generate shareable links
   - Set expiration times

---

## Success Metrics

- Time to invite and onboard a member: < 30 seconds
- Invitation acceptance rate: > 70%
- Task assignment usage: > 50% of multi-member projects
- Notification click-through rate: > 60%
- Zero critical security issues
- 99.9% uptime for notification delivery

---

## Notes

- All timestamps use UTC
- Email validation required before sending invitations
- Implement rate limiting for invitation sending (max 10 per hour)
- Cache member lists locally for offline access
- Implement optimistic updates for better UX
- Log all security-sensitive actions for audit trail
