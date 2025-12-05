# Zoho Cliq Integration: Step-by-Step Implementation Guide

**Document Purpose:** Practical, step-by-step guide for implementing Tasker × Zoho Cliq integration. This breaks down the complex integration into small, manageable tasks with clear responsibilities.

---

## Table of Contents

1. [Quick Start Overview](#quick-start-overview)
2. [Step 1: Zoho Cliq Setup](#step-1-zoho-cliq-setup)
3. [Step 2: Tasker Backend Preparation](#step-2-tasker-backend-preparation)
4. [Step 3: First Slash Command](#step-3-first-slash-command)
5. [Step 4: API Integration](#step-4-api-integration)
6. [Step 5: Webhook Setup](#step-5-webhook-setup)
7. [Next Steps Roadmap](#next-steps-roadmap)

---

## Quick Start Overview

### What You'll Do on Zoho Platform

1. Create Zoho Cliq developer account
2. Create new extension
3. Add slash command component
4. Write Deluge handler functions
5. Test in sandbox environment
6. Configure OAuth connections
7. Deploy to production

### What We'll Do in Tasker Codebase

1. Create API endpoints for Cliq integration
2. Implement authentication middleware
3. Set up webhook sender
4. Add Cliq-specific response formatters
5. Create database models for sync
6. Implement notification system

### Development Philosophy

🎯 **Small Steps:** Each step can be completed in 30-60 minutes  
✅ **Test Often:** Test after every step before moving forward  
🔄 **Iterate:** Get basic version working, then enhance  
📝 **Document:** Keep notes on what works and what doesn't  

---

## Step 1: Zoho Cliq Setup

### 1.1: Create Zoho Account (5 minutes)

**On Zoho Cliq Platform:**

1. Go to https://cliq.zoho.com/
2. Sign up for free account (use work email)
3. Complete organization setup
4. Verify email address

**Result:** You now have access to Zoho Cliq workspace

---

### 1.2: Enable Developer Mode (3 minutes)

**On Zoho Cliq Platform:**

1. Click your profile icon (top-right)
2. Select **Settings**
3. Go to **Bots & Tools** section
4. Click **Developer Mode** toggle to ON

**Result:** Developer options now visible in sidebar

---

### 1.3: Create Your First Extension (5 minutes)

**On Zoho Cliq Platform:**

1. Click **Bots & Tools** in left sidebar
2. Click **Extensions** tab
3. Click **Create Extension** button
4. Fill in details:
   - **Extension Name:** `Tasker`
   - **Description:** `Manage tasks directly in Cliq`
   - **Icon:** Upload a task/checklist icon (512x512 px)
5. Click **Create**

**Result:** Empty extension created, ready for components

**Screenshot Location:** Your extension appears in "My Extensions" list

---

### 1.4: Understand the Interface (2 minutes)

**On Zoho Cliq Platform:**

You'll see these tabs in your extension:

- **Components** - Add commands, bots, widgets, etc.
- **Connections** - Configure OAuth to external APIs
- **Databases** - Create tables for storing data
- **Settings** - App keys, webhooks, version control
- **Versions** - Manage sandbox/production versions

**Important:** Always work in **Sandbox version** during development!

---

## Step 2: Tasker Backend Preparation

### 2.1: Create API Structure (10 minutes)

**What We'll Do in Tasker:**

Create a new directory structure for Cliq integration:

```
lib/src/integrations/
├── cliq/
│   ├── models/
│   │   ├── cliq_task_request.dart
│   │   ├── cliq_task_response.dart
│   │   └── cliq_webhook_payload.dart
│   ├── services/
│   │   ├── cliq_auth_service.dart
│   │   ├── cliq_webhook_service.dart
│   │   └── cliq_task_service.dart
│   └── api/
│       ├── cliq_api_routes.dart
│       └── cliq_api_handlers.dart
```

**Action Required:** Create this folder structure first

---

### 2.2: Create Basic API Endpoint Model (15 minutes)

**File:** `lib/src/integrations/cliq/models/cliq_task_request.dart`

**Code to Add:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cliq_task_request.freezed.dart';
part 'cliq_task_request.g.dart';

/// Request model for creating a task from Zoho Cliq
@freezed
class CliqTaskRequest with _$CliqTaskRequest {
  const factory CliqTaskRequest({
    required String title,
    String? description,
    String? projectId,
    List<String>? assigneeIds,
    DateTime? dueDate,
    @Default('medium') String priority,
    List<String>? tags,
    
    // Cliq-specific context
    required CliqContext cliqContext,
  }) = _CliqTaskRequest;

  factory CliqTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CliqTaskRequestFromJson(json);
}

/// Context information from Zoho Cliq
@freezed
class CliqContext with _$CliqContext {
  const factory CliqContext({
    required String userId,         // Cliq user ID
    required String userName,        // Cliq username
    String? channelId,               // Channel where command was used
    String? messageId,               // Original message ID (if any)
    @Default('slash_command') String source, // slash_command, bot, widget, message_action
  }) = _CliqContext;

  factory CliqContext.fromJson(Map<String, dynamic> json) =>
      _$CliqContextFromJson(json);
}
```

**Action Required:** 
1. Create this file
2. Run `flutter pub get` (if freezed not in pubspec.yaml yet)
3. Run `dart run build_runner build` to generate code
4. Verify no errors

---

### 2.3: Create Response Model (10 minutes)

**File:** `lib/src/integrations/cliq/models/cliq_task_response.dart`

**Code to Add:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tasker/src/features/tasks/domain/models/task.dart';

part 'cliq_task_response.freezed.dart';
part 'cliq_task_response.g.dart';

/// Response model for Cliq extension with rich card formatting
@freezed
class CliqTaskResponse with _$CliqTaskResponse {
  const factory CliqTaskResponse({
    required bool success,
    String? message,
    CliqTaskData? task,
    CliqCard? card,
    CliqErrorInfo? error,
  }) = _CliqTaskResponse;

  factory CliqTaskResponse.fromJson(Map<String, dynamic> json) =>
      _$CliqTaskResponseFromJson(json);

  /// Create success response with task card
  factory CliqTaskResponse.success({
    required Task task,
    String? message,
  }) {
    return CliqTaskResponse(
      success: true,
      message: message ?? 'Task created successfully!',
      task: CliqTaskData.fromTask(task),
      card: CliqCard.taskCard(task),
    );
  }

  /// Create error response
  factory CliqTaskResponse.error({
    required String message,
    String? errorCode,
  }) {
    return CliqTaskResponse(
      success: false,
      message: message,
      error: CliqErrorInfo(
        code: errorCode ?? 'UNKNOWN_ERROR',
        message: message,
      ),
    );
  }
}

/// Simplified task data for Cliq
@freezed
class CliqTaskData with _$CliqTaskData {
  const factory CliqTaskData({
    required String id,
    required String title,
    String? description,
    required String status,
    String? priority,
    String? projectId,
    String? projectName,
    List<String>? assigneeIds,
    DateTime? dueDate,
    DateTime? createdAt,
  }) = _CliqTaskData;

  factory CliqTaskData.fromJson(Map<String, dynamic> json) =>
      _$CliqTaskDataFromJson(json);

  factory CliqTaskData.fromTask(Task task) {
    return CliqTaskData(
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status.name,
      priority: task.priority?.name,
      projectId: task.projectId,
      projectName: null, // TODO: Fetch from project repository
      assigneeIds: task.assignees,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
    );
  }
}

/// Rich card for Cliq UI
@freezed
class CliqCard with _$CliqCard {
  const factory CliqCard({
    required String theme,
    required String title,
    String? subtitle,
    List<CliqCardButton>? buttons,
    Map<String, dynamic>? data,
  }) = _CliqCard;

  factory CliqCard.fromJson(Map<String, dynamic> json) =>
      _$CliqCardFromJson(json);

  /// Generate task card UI
  factory CliqCard.taskCard(Task task) {
    final emoji = _getTaskEmoji(task.priority?.name);
    final dueText = task.dueDate != null
        ? 'Due: ${_formatDate(task.dueDate!)}'
        : 'No due date';

    return CliqCard(
      theme: _getThemeColor(task.priority?.name),
      title: '$emoji ${task.title}',
      subtitle: dueText,
      buttons: [
        CliqCardButton(
          label: 'View Details',
          action: 'view_task',
          actionData: {'taskId': task.id},
        ),
        CliqCardButton(
          label: 'Mark Complete',
          action: 'complete_task',
          actionData: {'taskId': task.id},
        ),
      ],
      data: {
        'taskId': task.id,
        'status': task.status.name,
        'priority': task.priority?.name ?? 'medium',
      },
    );
  }

  static String _getTaskEmoji(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return '🔥';
      case 'medium':
        return '📋';
      case 'low':
        return '📝';
      default:
        return '✅';
    }
  }

  static String _getThemeColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'red';
      case 'medium':
        return 'orange';
      case 'low':
        return 'blue';
      default:
        return 'gray';
    }
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else if (taskDate.isBefore(today)) {
      final days = today.difference(taskDate).inDays;
      return '$days days overdue';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

/// Card button configuration
@freezed
class CliqCardButton with _$CliqCardButton {
  const factory CliqCardButton({
    required String label,
    required String action,
    Map<String, dynamic>? actionData,
  }) = _CliqCardButton;

  factory CliqCardButton.fromJson(Map<String, dynamic> json) =>
      _$CliqCardButtonFromJson(json);
}

/// Error information
@freezed
class CliqErrorInfo with _$CliqErrorInfo {
  const factory CliqErrorInfo({
    required String code,
    required String message,
  }) = _CliqErrorInfo;

  factory CliqErrorInfo.fromJson(Map<String, dynamic> json) =>
      _$CliqErrorInfoFromJson(json);
}
```

**Action Required:**
1. Create this file
2. Run `dart run build_runner build`
3. Fix any import errors
4. Verify compilation succeeds

---

### 2.4: Check Dependencies (5 minutes)

**File:** `pubspec.yaml`

**Check if these dependencies exist:**

```yaml
dependencies:
  # ... existing dependencies ...
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
dev_dependencies:
  # ... existing dev dependencies ...
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  build_runner: ^2.4.8
```

**Action Required:**
1. If missing, add these dependencies
2. Run `flutter pub get`
3. Verify successful installation

---

## Step 3: First Slash Command

### 3.1: Create Slash Command in Cliq (10 minutes)

**On Zoho Cliq Platform:**

1. Open your **Tasker** extension
2. Go to **Components** tab
3. Click **Create Component** → **Command**
4. Configure command:
   - **Command Name:** `task`
   - **Command Hint:** `Manage your tasks`
   - **Suggestion:** `create [title]`
5. Click **Create**

**Result:** Empty slash command created, ready for handler code

---

### 3.2: Write Simple Handler (15 minutes)

**On Zoho Cliq Platform:**

In your `task` command, paste this handler code:

```deluge
// Handler for /task command
// Available parameters: arguments, chat, user, options, mentions, attachments, selections, location
response = Map();

// arguments is a string containing everything after /task
// Example: "/task create Fix bug" -> arguments = "create Fix bug"
args = arguments.trim();

// Get user info
userId = user.get("id");
userName = user.get("name");

// Split into parts
spaceIndex = args.indexOf(" ");
action = "";
restOfArgs = "";

if(spaceIndex > 0) {
    action = args.substring(0, spaceIndex);
    restOfArgs = args.substring(spaceIndex + 1);
} else {
    action = args;
}

// Log for debugging
info "Command executed by: " + userName + " (" + userId + ")";
info "Action: " + action;
info "Arguments: " + restOfArgs;

// Simple response for now
if(action == "create") {
    // Extract task title from remaining arguments
    title = restOfArgs;
    
    if(title.isEmpty()) {
        response.put("text", "❌ Please provide a task title.\nUsage: /task create [title]");
    } else {
        response.put("text", "✅ Task creation request received!");
        
        // Create a card with user info
        card = Map();
        card.put("title", "Creating Task");
        card.put("theme", "modern-inline");
        
        slides = list();
        slide = Map();
        slide.put("type", "label");
        slide.put("data", {
            "Title": title,
            "Created by": userName,
            "Status": "Processing..."
        });
        slides.add(slide);
        
        card.put("slides", slides);
        response.put("card", card);
    }
    
} else if(action == "list") {
    response.put("text", "📋 Listing your tasks...\n\n" +
        "*(This will connect to Tasker API in next step)*");
    
} else if(action == "help") {
    response.put("text", "📋 **Tasker Help**\n\n" +
        "**Available commands:**\n" +
        "`/task create [title]` - Create a new task\n" +
        "`/task list` - View your tasks\n" +
        "`/task help` - Show this help message");
        
} else {
    response.put("text", "❓ Unknown command: `" + action + "`\n\n" +
        "Type `/task help` for usage.");
}

return response;
```

**Action Required:**
1. Paste this code in the command handler editor
2. Click **Save**
3. Wait for validation to pass

---

### 3.3: Test Your First Command (5 minutes)

**On Zoho Cliq Platform:**

1. In the extension editor, look for **Test** button
2. Or open Cliq chat interface
3. Type: `/task create Fix login bug`
4. Press Enter

**Expected Result:**
```
✅ Task creation request received!

Creating Task
Title: Fix login bug
```

**Troubleshooting:**
- If command doesn't appear, check Developer Mode is ON
- If error occurs, check Deluge syntax in handler
- If no response, check you clicked Save

---

## Step 4: API Integration

### 4.1: Create API Service (20 minutes)

**File:** `lib/src/integrations/cliq/services/cliq_task_service.dart`

**Code to Add:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tasker/src/features/tasks/domain/models/task.dart';
import 'package:tasker/src/features/tasks/data/repositories/task_repository.dart';
import 'package:tasker/src/integrations/cliq/models/cliq_task_request.dart';
import 'package:tasker/src/integrations/cliq/models/cliq_task_response.dart';

/// Service for handling Cliq task operations
class CliqTaskService {
  final TaskRepository _taskRepository;
  final FirebaseFirestore _firestore;

  CliqTaskService({
    required TaskRepository taskRepository,
    required FirebaseFirestore firestore,
  })  : _taskRepository = taskRepository,
        _firestore = firestore;

  /// Create task from Cliq request
  Future<CliqTaskResponse> createTask(CliqTaskRequest request) async {
    try {
      // Map Cliq user to Tasker user
      final taskerUserId = await _mapCliqUserToTasker(
        request.cliqContext.userId,
      );

      if (taskerUserId == null) {
        return CliqTaskResponse.error(
          message: 'User not linked. Please connect your Tasker account first.',
          errorCode: 'USER_NOT_LINKED',
        );
      }

      // Create task object
      final task = Task(
        id: _firestore.collection('tasks').doc().id,
        title: request.title,
        description: request.description ?? '',
        status: TaskStatus.pending,
        priority: _parsePriority(request.priority),
        projectId: request.projectId,
        assignees: request.assigneeIds ?? [taskerUserId],
        dueDate: request.dueDate,
        createdBy: taskerUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: request.tags ?? [],
        metadata: {
          'source': 'cliq',
          'cliq_user_id': request.cliqContext.userId,
          'cliq_channel_id': request.cliqContext.channelId,
        },
      );

      // Save to database
      await _taskRepository.createTask(task);

      // Store Cliq mapping
      await _storeCliqMapping(
        taskId: task.id,
        cliqContext: request.cliqContext,
      );

      return CliqTaskResponse.success(
        task: task,
        message: '✅ Task created successfully!',
      );
    } catch (e) {
      return CliqTaskResponse.error(
        message: 'Failed to create task: ${e.toString()}',
        errorCode: 'CREATE_TASK_FAILED',
      );
    }
  }

  /// List tasks for Cliq user
  Future<List<Task>> listTasks({
    required String cliqUserId,
    String? projectId,
    String? status,
    int limit = 50,
  }) async {
    try {
      final taskerUserId = await _mapCliqUserToTasker(cliqUserId);
      if (taskerUserId == null) {
        return [];
      }

      // Query tasks
      Query<Map<String, dynamic>> query = _firestore
          .collection('tasks')
          .where('assignees', arrayContains: taskerUserId)
          .limit(limit);

      if (projectId != null) {
        query = query.where('projectId', isEqualTo: projectId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Task.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error listing tasks: $e');
      return [];
    }
  }

  /// Map Cliq user ID to Tasker user ID
  Future<String?> _mapCliqUserToTasker(String cliqUserId) async {
    try {
      final doc = await _firestore
          .collection('cliq_user_mappings')
          .doc(cliqUserId)
          .get();

      return doc.data()?['tasker_user_id'] as String?;
    } catch (e) {
      print('Error mapping user: $e');
      return null;
    }
  }

  /// Store Cliq-specific metadata
  Future<void> _storeCliqMapping({
    required String taskId,
    required CliqContext cliqContext,
  }) async {
    try {
      await _firestore.collection('cliq_task_mappings').doc(taskId).set({
        'task_id': taskId,
        'cliq_user_id': cliqContext.userId,
        'cliq_channel_id': cliqContext.channelId,
        'cliq_message_id': cliqContext.messageId,
        'source': cliqContext.source,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error storing Cliq mapping: $e');
    }
  }

  /// Parse priority string
  TaskPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}
```

**Action Required:**
1. Create this file
2. Fix any import errors (adjust paths to match your project structure)
3. Run `flutter analyze` to check for issues
4. Don't run the app yet (we'll add the API endpoint first)

---

### 4.2: Status Check

**Before proceeding to Step 5:**

✅ Verify you have completed:
- [ ] Created folder structure under `lib/src/integrations/cliq/`
- [ ] Created `cliq_task_request.dart` model
- [ ] Created `cliq_task_response.dart` model
- [ ] Ran `dart run build_runner build` successfully
- [ ] Created `cliq_task_service.dart` service
- [ ] Created basic slash command in Zoho Cliq
- [ ] Tested `/task create` command (even if it only shows confirmation)

**If all checked:** Ready for Step 5!  
**If any unchecked:** Go back and complete those steps first

---

## Step 5: Webhook Setup

### 5.1: Plan Webhook Architecture (5 minutes)

**Understanding the Flow:**

```
Tasker App/Backend → Firebase Cloud Function → Zoho Cliq Webhook → Extension Handler
```

**What triggers webhooks:**
- Task created
- Task updated (status, assignee, due date)
- Task completed
- Comment added
- Task assigned to user

**What we'll build:**
1. Firestore trigger function (detects changes)
2. Webhook sender (posts to Cliq)
3. Cliq webhook receiver (extension handler)
4. Notification formatter

---

### 5.2: Get Cliq Webhook URL (3 minutes)

**On Zoho Cliq Platform:**

1. Open your **Tasker** extension
2. Go to **Settings** tab
3. Look for **Incoming Webhook** section
4. Copy the webhook URL (format: `https://cliq.zoho.com/api/v2/applications/{app_id}/incoming?appkey={app_key}`)
5. **Save this URL** - you'll need it in Tasker backend

**Security Note:** This URL contains your app key - keep it secret!

---

### 5.3: Create Webhook Model (10 minutes)

**File:** `lib/src/integrations/cliq/models/cliq_webhook_payload.dart`

**Code to Add:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cliq_webhook_payload.freezed.dart';
part 'cliq_webhook_payload.g.dart';

/// Payload sent to Zoho Cliq incoming webhook
@freezed
class CliqWebhookPayload with _$CliqWebhookPayload {
  const factory CliqWebhookPayload({
    required String event,
    required DateTime timestamp,
    required Map<String, dynamic> data,
    CliqNotificationTarget? target,
  }) = _CliqWebhookPayload;

  factory CliqWebhookPayload.fromJson(Map<String, dynamic> json) =>
      _$CliqWebhookPayloadFromJson(json);

  /// Create task created event
  factory CliqWebhookPayload.taskCreated({
    required String taskId,
    required String title,
    required String createdBy,
    List<String>? assignees,
    String? projectId,
  }) {
    return CliqWebhookPayload(
      event: 'task.created',
      timestamp: DateTime.now(),
      data: {
        'taskId': taskId,
        'title': title,
        'createdBy': createdBy,
        'assignees': assignees ?? [],
        'projectId': projectId,
      },
    );
  }

  /// Create task completed event
  factory CliqWebhookPayload.taskCompleted({
    required String taskId,
    required String title,
    required String completedBy,
    List<String>? assignees,
  }) {
    return CliqWebhookPayload(
      event: 'task.completed',
      timestamp: DateTime.now(),
      data: {
        'taskId': taskId,
        'title': title,
        'completedBy': completedBy,
        'assignees': assignees ?? [],
      },
      target: CliqNotificationTarget(
        userIds: assignees,
      ),
    );
  }

  /// Create task assigned event
  factory CliqWebhookPayload.taskAssigned({
    required String taskId,
    required String title,
    required String assignedBy,
    required List<String> assignedTo,
  }) {
    return CliqWebhookPayload(
      event: 'task.assigned',
      timestamp: DateTime.now(),
      data: {
        'taskId': taskId,
        'title': title,
        'assignedBy': assignedBy,
        'assignedTo': assignedTo,
      },
      target: CliqNotificationTarget(
        userIds: assignedTo,
      ),
    );
  }
}

/// Notification target specification
@freezed
class CliqNotificationTarget with _$CliqNotificationTarget {
  const factory CliqNotificationTarget({
    List<String>? userIds,
    String? channelId,
    bool? broadcast,
  }) = _CliqNotificationTarget;

  factory CliqNotificationTarget.fromJson(Map<String, dynamic> json) =>
      _$CliqNotificationTargetFromJson(json);
}
```

**Action Required:**
1. Create this file
2. Run `dart run build_runner build`
3. Verify compilation

---

## Next Steps Roadmap

### Immediate Next Steps (This Week)

**Step 6: Create Firebase Cloud Function for Webhooks**
- Set up Cloud Functions project
- Create Firestore trigger for task changes
- Implement webhook sender
- Test with sample data

**Step 7: Update Cliq Extension with Webhook Handler**
- Add webhook handler in extension
- Process different event types
- Format notifications
- Post to users/channels

**Step 8: Implement User Linking**
- Create user authentication flow
- Link Cliq users to Tasker accounts
- Store mappings in Firestore
- Handle linking UI

### Medium Term (Next 2 Weeks)

**Step 9: Enhance Slash Commands**
- Add `/task list` with filtering
- Add `/task view [id]` for details
- Add `/task update [id]` for modifications
- Add `/task complete [id]`

**Step 10: Build Widget Dashboard**
- Create widget component in Cliq
- Design dashboard tabs
- Implement data loading
- Add button handlers

**Step 11: Create Bot Integration**
- Add bot component
- Implement mention handler
- Add conversational flows
- Natural language parsing

### Long Term (Next Month)

**Step 12: Message Actions**
- Create message action component
- Add "Create Task from Message"
- Link messages to tasks

**Step 13: Schedulers**
- Daily digest scheduler
- Reminder scheduler
- Weekly reports

**Step 14: Testing & Polish**
- Comprehensive testing
- Error handling improvements
- Performance optimization

**Step 15: Production Deployment**
- Marketplace submission
- Documentation
- Launch!

---

## Development Tips

### 🎯 Focus on MVP First

Complete Steps 1-8 before adding fancy features. A working basic integration is better than a feature-rich broken one.

### ✅ Test After Every Step

Don't accumulate untested code. Test each component immediately after creating it.

### 📝 Keep Notes

Document any issues you encounter and their solutions. You'll reference this later.

### 🔄 Iterate Quickly

Get something working end-to-end first, then make it better. Don't try to perfect each step.

### 🐛 Debug Strategically

**Cliq Side:**
- Use `info` statements in Deluge to log values
- Check execution logs in extension settings
- Test in sandbox before production

**Tasker Side:**
- Use `print()` statements liberally
- Check Firebase Console logs
- Use Postman to test API endpoints directly

### 🤝 Need Help?

**Zoho Cliq Resources:**
- Documentation: https://www.zoho.com/cliq/help/platform/
- Forums: https://help.zoho.com/portal/en/community/zoho-cliq
- Deluge Guide: https://www.zoho.com/deluge/help/

**Flutter/Firebase:**
- Flutter Docs: https://docs.flutter.dev/
- Firebase Docs: https://firebase.google.com/docs
- Riverpod Docs: https://riverpod.dev/

---

## Progress Tracking

### Current Status

- [x] Step 1: Zoho Cliq Setup
- [x] Step 2: Tasker Backend Preparation  
- [x] Step 3: First Slash Command
- [ ] Step 4: API Integration (In Progress)
- [ ] Step 5: Webhook Setup (Ready to start)
- [ ] Step 6-15: Coming soon

### Time Investment So Far

- Zoho setup: ~30 minutes
- Tasker models: ~45 minutes  
- First command: ~20 minutes
- **Total: ~95 minutes**

### Next Session Goal

Complete Steps 4-5 to have bidirectional communication working (Cliq → Tasker → Cliq notifications)

---

**Document Version:** 1.0  
**Last Updated:** November 22, 2025  
**Status:** Steps 1-5 Defined, Ready for Implementation
