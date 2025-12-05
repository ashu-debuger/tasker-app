# Tasker × Zoho Cliq Integration Guide

## Executive Summary

This document outlines the complete strategy for building a two-way integration between **Tasker** (our Flutter task management app) and **Zoho Cliq** (enterprise team communication platform). The integration will enable seamless task management directly within Cliq's chat interface while maintaining real-time synchronization with the Tasker mobile/web app.

---

## Table of Contents

1. [Integration Overview](#integration-overview)
2. [Two-Way Communication Architecture](#two-way-communication-architecture)
3. [Extension Components Breakdown](#extension-components-breakdown)
4. [Implementation Roadmap](#implementation-roadmap)
5. [Technical Architecture](#technical-architecture)
6. [API Endpoints & Webhooks](#api-endpoints--webhooks)
7. [Security & Authentication](#security--authentication)
8. [User Experience Flows](#user-experience-flows)
9. [Development Phases](#development-phases)
10. [Testing Strategy](#testing-strategy)
11. [Deployment & Maintenance](#deployment--maintenance)

---

## Integration Overview

### What We're Building

A comprehensive Zoho Cliq extension that allows teams to:

- Create, update, and manage tasks directly from Cliq chat
- Receive real-time notifications about task changes
- View project dashboards and task lists in Cliq widgets
- Collaborate on tasks with team discussions
- Sync all changes bidirectionally with Tasker mobile/web app

### Core Value Proposition

**For Users:**
- Manage tasks without leaving their communication hub
- Reduce context switching between apps
- Get instant notifications for task updates
- Collaborate seamlessly with team members

**For Organizations:**
- Centralize workflow in single platform (Cliq)
- Increase task completion rates through better visibility
- Improve team coordination and accountability
- Leverage existing Cliq adoption

---

## Two-Way Communication Architecture

### Direction 1: Cliq → Tasker (User Actions)

**Flow:** User performs action in Cliq → Extension calls Tasker API → Database updated → Response sent back to Cliq

**Mechanisms:**
- **Slash Commands** → Tasker REST API → Update Firestore → Return confirmation
- **Bot Conversations** → Parse intent → API call → Store result → Reply to user
- **Widget Buttons** → Function handler → HTTP request → Update DB → Refresh widget
- **Message Actions** → Extract context → API operation → Show result

**Example Flow:**
```
User types: /task create "Fix login bug" project:Mobile due:tomorrow
    ↓
Slash command handler in Deluge script
    ↓
invoke.url POST to Tasker API (/api/tasks/create)
    ↓
Tasker backend validates & creates task in Firestore
    ↓
Returns task ID and details
    ↓
Extension posts confirmation message to Cliq
```

### Direction 2: Tasker → Cliq (Change Notifications)

**Flow:** Task updated in Tasker app → Webhook triggered → Cliq extension receives event → Post notification to channel/user

**Mechanisms:**
- **Firebase Cloud Functions** → Detect Firestore changes → POST to Cliq webhook
- **Tasker Backend** → Task CRUD operations → Trigger webhook → Extension processes
- **Real-time Sync** → Listen to Firestore streams → Send batch updates
- **User Actions in App** → Trigger notification rules → Push to Cliq

**Example Flow:**
```
User completes task in Tasker mobile app
    ↓
Firestore onUpdate trigger in Cloud Function
    ↓
Function evaluates notification rules (assignees, watchers)
    ↓
POST to Cliq incoming webhook with task details
    ↓
Extension processes webhook in handler
    ↓
Posts message to relevant channel/DM with task card
```

### Bidirectional Sync Strategy

**Real-Time Requirements:**
1. Task created in Cliq → Appears in app within 2 seconds
2. Task updated in app → Notification in Cliq within 3 seconds
3. Comment added in app → Shows in Cliq conversation thread
4. Status change anywhere → Reflected everywhere immediately

**Conflict Resolution:**
- Last-write-wins for simple field updates
- Operational transformation for collaborative text editing
- Version timestamps for conflict detection
- User notification on conflicting changes

---

## Extension Components Breakdown

### 1. Slash Commands (Text-Based Actions)

#### `/task` Command Suite

**Purpose:** Quick task creation and management via text commands

**Sub-commands:**
```
/task create [title] [options]
  Options: project:name, assignee:@user, due:date, priority:high/medium/low, 
           tags:tag1,tag2, description:"text"
  
/task list [filters]
  Filters: project:name, assignee:@user, status:pending/completed, due:today/week
  
/task view [task-id]
  Shows: Full task details, comments, subtasks, assignees, history
  
/task update [task-id] [field:value]
  Fields: status, priority, assignee, due, description, tags
  
/task complete [task-id]
  Marks task as complete and notifies assignees
  
/task assign [task-id] @user1 @user2
  Assigns task to mentioned users
  
/task comment [task-id] "comment text"
  Adds comment to task discussion
```

**Response Format:**
- Success: Rich card with task details and action buttons
- Error: Friendly error message with suggestions
- List: Paginated cards with navigation buttons

**Implementation Details:**
```deluge
// Example: /task create handler
response = invokeurl
[
    url: "https://tasker-api.example.com/api/v1/tasks"
    type: POST
    parameters: {
        "title": title,
        "projectId": project_id,
        "assignees": assignee_ids,
        "dueDate": due_date,
        "priority": priority,
        "createdBy": user.id,
        "source": "cliq"
    }
    headers: {
        "Authorization": "Bearer " + connection_token,
        "Content-Type": "application/json"
    }
    connection: "tasker_oauth"
];

if(response.get("success")) {
    task = response.get("task");
    card = generateTaskCard(task);
    return {"text": "Task created successfully!", "card": card};
} else {
    return {"text": "❌ Error: " + response.get("message")};
}
```

#### `/project` Command Suite

```
/project list
/project create [name] [description]
/project view [project-id]
/project members [project-id]
/project archive [project-id]
```

#### `/routine` Command Suite

```
/routine list
/routine create [title] [schedule]
/routine toggle [routine-id]
/routine history [routine-id]
```

### 2. Bot (@TaskerBot)

**Purpose:** Conversational interface for natural language task management

**Capabilities:**
- Natural language processing for task creation
- Context-aware conversations
- Multi-turn dialogues for complex operations
- Proactive suggestions and reminders

**Handler Types:**

**Mention Handler:**
```deluge
// User mentions @TaskerBot in channel
handler mention(message) {
    intent = parseIntent(message.text);
    
    if(intent == "create_task") {
        // Extract task details from natural language
        details = extractTaskDetails(message.text);
        
        if(details.isComplete()) {
            createTask(details);
        } else {
            // Ask for missing information
            return askForDetails(details.missing);
        }
    }
}
```

**Message Handler:**
```deluge
// Direct message to bot
handler message(message) {
    context = getConversationContext(message.userId);
    
    if(context.waiting_for == "task_title") {
        context.task.title = message.text;
        context.waiting_for = "due_date";
        return "Got it! When is this due? (e.g., tomorrow, next Friday, 2024-12-01)";
    }
}
```

**Welcome Handler:**
```deluge
// User starts conversation with bot
handler welcome() {
    return {
        "text": "👋 Hi! I'm TaskerBot. I can help you manage tasks right here in Cliq.",
        "card": {
            "title": "Quick Actions",
            "buttons": [
                {"label": "Create Task", "action": {"type": "invoke.function", "name": "show_task_form"}},
                {"label": "My Tasks", "action": {"type": "invoke.function", "name": "show_my_tasks"}},
                {"label": "Help", "action": {"type": "open.url", "url": "https://tasker.app/help"}}
            ]
        }
    };
}
```

**Conversation Examples:**

```
User: @TaskerBot create a task to review PR
Bot: Sure! What should I call this task?
User: Review John's authentication PR
Bot: Got it! When should this be done?
User: by end of day tomorrow
Bot: Any specific project?
User: Mobile App
Bot: Perfect! Creating task... ✅ Task created: "Review John's authentication PR" 
     Due: Dec 1, 2024 | Project: Mobile App | Assigned: You
     [View Details] [Add Assignees]
```

### 3. Message Actions (Context Menu)

**Purpose:** Quick actions on messages to create tasks from conversations

**Actions:**

**"Create Task from Message"**
- Right-click any message → "Create Task from Message"
- Pre-fills task title with message content
- Links task to original message
- Preserves context and participants

**"Add to Existing Task"**
- Attach message as comment to task
- Creates reference link
- Notifies task assignees

**"Set Reminder"**
- Create quick reminder from message
- Schedule notification

**Implementation:**
```deluge
handler message_action create_task_from_message(message) {
    return {
        "type": "form",
        "title": "Create Task",
        "hint": "Creating task from message by " + message.sender.name,
        "fields": [
            {"type": "text", "name": "title", "label": "Task Title", "value": message.text.substring(0, 100)},
            {"type": "select", "name": "project", "label": "Project", "options": getProjects()},
            {"type": "user_select", "name": "assignees", "label": "Assign To", "multiple": true},
            {"type": "date", "name": "due_date", "label": "Due Date"}
        ],
        "button": {
            "label": "Create Task",
            "action": {"type": "invoke.function", "name": "create_task_from_message", "id": message.id}
        }
    };
}
```

### 4. Widget (Dashboard & Task Management)

**Purpose:** Persistent home screen interface for task overview and management

**Widget Structure:**

**Tab 1: Dashboard**
```json
{
  "title": "Dashboard",
  "sections": [
    {
      "id": "stats",
      "title": "Today's Overview",
      "type": "status",
      "data": [
        {"label": "Total Tasks", "value": "24", "color": "blue"},
        {"label": "Due Today", "value": "5", "color": "orange"},
        {"label": "Overdue", "value": "2", "color": "red"},
        {"label": "Completed", "value": "17", "color": "green"}
      ]
    },
    {
      "id": "my_tasks",
      "title": "My Tasks",
      "type": "list",
      "data": [
        {
          "title": "Fix login bug",
          "subtitle": "Mobile App • Due today",
          "status": "In Progress",
          "buttons": [
            {"label": "Complete", "action": "complete_task"},
            {"label": "View", "action": "view_task"}
          ]
        }
      ]
    }
  ]
}
```

**Tab 2: Projects**
- List of active projects
- Task count per project
- Quick create new project
- Filter by status/priority

**Tab 3: Team**
- Team member list
- Task assignments per person
- Workload distribution
- Collaboration stats

**Tab 4: Calendar**
- Week/month view of due dates
- Routine schedules
- Milestone tracking
- Export to calendar

**Tab 5: Activity**
- Recent task updates
- Team activity feed
- Comment notifications
- Status changes

**Widget Function Handlers:**
```deluge
// Tab click handler
handler tab_click(tab_name) {
    if(tab_name == "dashboard") {
        return loadDashboard();
    } else if(tab_name == "projects") {
        return loadProjects();
    }
}

// Button click handler
handler button_click(button_id, data) {
    if(button_id == "complete_task") {
        completeTask(data.task_id);
        return refreshWidget();
    }
}

// Form submission handler
handler form_submit(form_data) {
    if(form_data.form_name == "create_task") {
        createTask(form_data);
        return {"type": "banner", "text": "Task created!", "theme": "success"};
    }
}
```

### 5. Functions (Backend Logic)

**Purpose:** Handle all business logic, API calls, and data processing

**Key Functions:**

**Task Management Functions:**
1. `create_task(data)` - Validates and creates task via API
2. `update_task(taskId, updates)` - Updates task fields
3. `delete_task(taskId)` - Soft/hard delete with confirmation
4. `complete_task(taskId)` - Marks complete and triggers notifications
5. `assign_task(taskId, userIds)` - Manages task assignments

**Project Functions:**
6. `list_projects()` - Fetches user's projects
7. `create_project(data)` - Creates new project
8. `add_project_member(projectId, userId)` - Manages members

**Routine Functions:**
9. `list_routines()` - Fetches routines for user
10. `toggle_routine(routineId)` - Enables/disables routine
11. `log_routine_completion(routineId)` - Records completion

**Utility Functions:**
12. `sync_user_data()` - Syncs Cliq user with Tasker account
13. `format_task_card(task)` - Generates rich card UI
14. `send_notification(userId, message)` - Posts message to user
15. `validate_permissions(userId, action)` - Checks user permissions

**API Integration Function Template:**
```deluge
void createTask(taskData) {
    // Validate input
    if(taskData.get("title").isEmpty()) {
        throw "Task title is required";
    }
    
    // Get OAuth token
    connection = zoho.cliq.getConnection("tasker_oauth");
    
    // Call Tasker API
    response = invokeurl [
        url: TASKER_API_URL + "/tasks"
        type: POST
        parameters: taskData.toJSON()
        headers: {
            "Authorization": "Bearer " + connection.get("access_token"),
            "X-Cliq-User-Id": taskData.get("userId")
        }
        connection: "tasker_oauth"
    ];
    
    if(response.get("status") == 201) {
        task = response.get("data");
        
        // Store task mapping in extension DB
        zoho.cliq.updateRecord("tasks", task.get("id"), {
            "cliq_user": taskData.get("userId"),
            "created_at": zoho.currenttime,
            "synced": true
        });
        
        // Post confirmation
        card = formatTaskCard(task);
        zoho.cliq.postToUser(taskData.get("userId"), card);
        
        return task;
    } else {
        throw "Failed to create task: " + response.get("message");
    }
}
```

### 6. Schedulers (Automated Tasks)

**Purpose:** Time-based automations and recurring notifications

**Scheduler Jobs:**

**Daily Digest (Every morning 9 AM)**
```deluge
scheduler daily_digest() {
    users = getAllActiveUsers();
    
    for each user in users {
        tasks = getTasksDueToday(user.id);
        overdue = getOverdueTasks(user.id);
        
        if(tasks.size() > 0 || overdue.size() > 0) {
            message = {
                "text": "🌅 Good morning! Here's your task summary:",
                "card": {
                    "sections": [
                        {"title": "Due Today", "data": formatTaskList(tasks)},
                        {"title": "Overdue", "data": formatTaskList(overdue)}
                    ]
                }
            };
            zoho.cliq.postToUser(user.id, message);
        }
    }
}
```

**Reminder Scheduler (Every 15 minutes)**
```deluge
scheduler task_reminders() {
    now = zoho.currenttime;
    upcoming = getTasksDueSoon(now, 60); // Tasks due in next 60 minutes
    
    for each task in upcoming {
        if(!task.reminder_sent) {
            assignees = task.get("assignees");
            for each assignee in assignees {
                zoho.cliq.postToUser(assignee, {
                    "text": "⏰ Reminder: Task due in " + task.timeUntilDue(),
                    "card": formatTaskCard(task)
                });
            }
            markReminderSent(task.id);
        }
    }
}
```

**Weekly Report (Every Friday 5 PM)**
```deluge
scheduler weekly_report() {
    teams = getAllTeams();
    
    for each team in teams {
        stats = getWeeklyStats(team.id);
        report = generateWeeklyReport(stats);
        
        zoho.cliq.postToChannel(team.channel_id, {
            "text": "📊 Weekly Team Report",
            "card": report
        });
    }
}
```

**Sync Health Check (Every hour)**
```deluge
scheduler sync_health_check() {
    lastSync = zoho.cliq.getProperty("last_sync_time");
    timeSince = (zoho.currenttime - lastSync).minutes();
    
    if(timeSince > 120) { // More than 2 hours
        // Alert admin
        zoho.cliq.postToUser(ADMIN_USER_ID, {
            "text": "⚠️ Tasker sync hasn't occurred in " + timeSince + " minutes"
        });
        
        // Attempt manual sync
        triggerManualSync();
    }
}
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

**Tasker Backend Requirements:**

1. **REST API Endpoints**
   ```
   POST   /api/v1/tasks              - Create task
   GET    /api/v1/tasks              - List tasks (with filters)
   GET    /api/v1/tasks/:id          - Get task details
   PUT    /api/v1/tasks/:id          - Update task
   DELETE /api/v1/tasks/:id          - Delete task
   POST   /api/v1/tasks/:id/complete - Mark complete
   POST   /api/v1/tasks/:id/comments - Add comment
   
   GET    /api/v1/projects           - List projects
   POST   /api/v1/projects           - Create project
   GET    /api/v1/projects/:id       - Get project details
   
   GET    /api/v1/routines           - List routines
   POST   /api/v1/routines/:id/log   - Log completion
   
   POST   /api/v1/auth/cliq          - Authenticate Cliq user
   GET    /api/v1/users/sync         - Sync user data
   ```

2. **Webhook Infrastructure**
   - Implement webhook sender in Cloud Functions
   - Listen to Firestore triggers (onCreate, onUpdate, onDelete)
   - Queue system for reliable delivery
   - Retry logic for failed deliveries

3. **OAuth 2.0 Setup**
   - Register Tasker as OAuth provider
   - Define scopes (tasks:read, tasks:write, projects:read, etc.)
   - Implement authorization flow
   - Token refresh mechanism

**Cliq Extension Setup:**

1. Create extension skeleton
2. Set up OAuth connection to Tasker API
3. Implement basic slash command (`/task create`)
4. Test API connectivity
5. Set up incoming webhook endpoint

### Phase 2: Core Features (Weeks 3-4)

**Task Management:**
- All `/task` commands
- Task card UI components
- Button interactions
- Form handling

**Bot Development:**
- Basic mention handler
- Intent parsing
- Task creation via conversation
- Help command

**Widget Foundation:**
- Dashboard tab with stats
- My Tasks list
- Refresh functionality

### Phase 3: Bidirectional Sync (Weeks 5-6)

**Webhook Handlers:**
- Process incoming task updates
- Post notifications to channels
- Handle user mentions
- Thread replies

**Real-time Updates:**
- Widget auto-refresh on changes
- Live task status updates
- Presence indicators
- Typing indicators for bot

**Data Persistence:**
- Extension database setup
- Cache user preferences
- Store task-message mappings
- Sync state tracking

### Phase 4: Advanced Features (Weeks 7-8)

**Message Actions:**
- Create task from message
- Add to existing task
- Quick reminders

**Schedulers:**
- Daily digest
- Task reminders
- Weekly reports
- Sync health checks

**Project Management:**
- `/project` commands
- Project dashboard in widget
- Team collaboration features

### Phase 5: Polish & Testing (Weeks 9-10)

**User Experience:**
- Error handling
- Loading states
- Confirmation dialogs
- Help documentation

**Performance:**
- API response caching
- Bulk operations
- Rate limiting
- Query optimization

**Testing:**
- Sandbox testing
- User acceptance testing
- Load testing
- Security audit

### Phase 6: Deployment (Week 11-12)

**Preparation:**
- Marketplace submission materials
- Video demo
- Screenshots
- Documentation

**Launch:**
- Publish to Zoho Marketplace
- Internal rollout plan
- Training materials
- Support setup

---

## Technical Architecture

### System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Zoho Cliq Platform                       │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Slash        │  │     Bot      │  │   Widget     │      │
│  │ Commands     │  │  @TaskerBot  │  │  Dashboard   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │               │
│         └──────────────────┴──────────────────┘              │
│                          │                                    │
│                 ┌────────▼─────────┐                         │
│                 │   Extension      │                         │
│                 │   Functions      │                         │
│                 │   (Deluge)       │                         │
│                 └────────┬─────────┘                         │
│                          │                                    │
└──────────────────────────┼────────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   OAuth     │
                    │ Connection  │
                    └──────┬──────┘
                           │
            ┌──────────────┴──────────────┐
            │                             │
     ┌──────▼──────┐             ┌───────▼────────┐
     │   Tasker    │             │   Incoming     │
     │  REST API   │◄────────────┤   Webhooks     │
     │  (Cloud     │             │   (Firebase    │
     │  Functions) │             │   Functions)   │
     └──────┬──────┘             └────────────────┘
            │
     ┌──────▼──────┐
     │  Firebase   │
     │  Firestore  │
     │  (Database) │
     └─────────────┘
```

### Data Flow Examples

**Creating a Task in Cliq:**
```
User: /task create "Fix bug" project:Mobile due:tomorrow
  ↓
[Cliq] Slash command handler invoked
  ↓
[Extension Function] Parse command parameters
  ↓
[Extension Function] invoke.url POST to Tasker API
  ↓
[Tasker API] Validate request & authenticate user
  ↓
[Tasker API] Create task in Firestore
  ↓
[Firestore] onWrite trigger fires
  ↓
[Cloud Function] Evaluate notification rules
  ↓
[Cloud Function] POST to Cliq incoming webhook
  ↓
[Extension Handler] Process webhook
  ↓
[Extension Handler] Post confirmation to channel
  ↓
[Cliq] Display success message with task card
  ↓
User sees: "✅ Task created: Fix bug | Mobile | Due: Tomorrow"
```

**Completing a Task in Mobile App:**
```
User: Taps "Complete" on task in Tasker app
  ↓
[Tasker App] Call updateTask API
  ↓
[Tasker API] Update task status in Firestore
  ↓
[Firestore] onUpdate trigger fires
  ↓
[Cloud Function] Detect status change (pending → completed)
  ↓
[Cloud Function] Get task assignees from DB
  ↓
[Cloud Function] POST to Cliq webhook with payload:
    {
      "event": "task.completed",
      "task_id": "task123",
      "completed_by": "user456",
      "assignees": ["user789", "user012"]
    }
  ↓
[Extension Handler] Receive webhook
  ↓
[Extension Handler] Query Tasker API for full task details
  ↓
[Extension Handler] Format notification card
  ↓
[Extension Handler] zoho.cliq.postToUser for each assignee
  ↓
[Cliq] Assignees receive notification:
    "✅ John completed: Fix bug (Mobile App)"
    [View Details] [Reopen Task]
```

---

## API Endpoints & Webhooks

### Tasker API Specifications

**Base URL:** `https://api.tasker.app/v1`

**Authentication:** Bearer token in Authorization header

#### Task Endpoints

**Create Task**
```http
POST /tasks
Content-Type: application/json
Authorization: Bearer {token}

{
  "title": "Fix login bug",
  "description": "Users can't login with email",
  "projectId": "proj123",
  "assignees": ["user456", "user789"],
  "dueDate": "2024-12-01T17:00:00Z",
  "priority": "high",
  "tags": ["bug", "urgent"],
  "source": "cliq",
  "cliqContext": {
    "channelId": "ch123",
    "messageId": "msg456",
    "createdBy": "cliq-user789"
  }
}

Response 201:
{
  "success": true,
  "task": {
    "id": "task123",
    "title": "Fix login bug",
    "status": "pending",
    "createdAt": "2024-11-22T10:30:00Z",
    ...
  }
}
```

**List Tasks**
```http
GET /tasks?projectId=proj123&assignee=user456&status=pending&limit=50
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "tasks": [...],
  "pagination": {
    "total": 150,
    "page": 1,
    "limit": 50,
    "hasMore": true
  }
}
```

**Update Task**
```http
PUT /tasks/task123
Content-Type: application/json
Authorization: Bearer {token}

{
  "status": "in_progress",
  "assignees": ["user456"],
  "priority": "medium"
}

Response 200:
{
  "success": true,
  "task": {...}
}
```

**Complete Task**
```http
POST /tasks/task123/complete
Content-Type: application/json
Authorization: Bearer {token}

{
  "completedBy": "user456",
  "completionNote": "Fixed and deployed"
}

Response 200:
{
  "success": true,
  "task": {...}
}
```

### Cliq Webhook Specifications

**Incoming Webhook URL:**
```
https://cliq.zoho.com/api/v2/applications/{app_id}/incoming?appkey={app_key}
```

**Webhook Payloads from Tasker:**

**Task Created Event**
```json
{
  "event": "task.created",
  "timestamp": "2024-11-22T10:30:00Z",
  "data": {
    "taskId": "task123",
    "title": "Fix login bug",
    "projectId": "proj123",
    "projectName": "Mobile App",
    "createdBy": "user456",
    "assignees": ["user789"],
    "dueDate": "2024-12-01T17:00:00Z",
    "priority": "high"
  }
}
```

**Task Updated Event**
```json
{
  "event": "task.updated",
  "timestamp": "2024-11-22T11:00:00Z",
  "data": {
    "taskId": "task123",
    "updates": {
      "status": {"old": "pending", "new": "in_progress"},
      "assignees": {"added": ["user012"], "removed": []}
    },
    "updatedBy": "user456"
  }
}
```

**Task Completed Event**
```json
{
  "event": "task.completed",
  "timestamp": "2024-11-22T15:30:00Z",
  "data": {
    "taskId": "task123",
    "title": "Fix login bug",
    "completedBy": "user456",
    "assignees": ["user789"],
    "projectId": "proj123"
  }
}
```

**Comment Added Event**
```json
{
  "event": "comment.added",
  "timestamp": "2024-11-22T12:00:00Z",
  "data": {
    "taskId": "task123",
    "commentId": "cmt456",
    "author": "user789",
    "text": "I'll review this today",
    "mentions": ["user456"]
  }
}
```

**Task Assigned Event**
```json
{
  "event": "task.assigned",
  "timestamp": "2024-11-22T13:00:00Z",
  "data": {
    "taskId": "task123",
    "assignedTo": ["user012"],
    "assignedBy": "user456"
  }
}
```

### Webhook Handler in Extension

```deluge
handler incoming_webhook(payload) {
    event = payload.get("event");
    data = payload.get("data");
    
    if(event == "task.created") {
        handleTaskCreated(data);
    } else if(event == "task.updated") {
        handleTaskUpdated(data);
    } else if(event == "task.completed") {
        handleTaskCompleted(data);
    } else if(event == "comment.added") {
        handleCommentAdded(data);
    } else if(event == "task.assigned") {
        handleTaskAssigned(data);
    }
    
    return {"status": "success"};
}

void handleTaskCompleted(data) {
    taskId = data.get("taskId");
    completedBy = data.get("completedBy");
    assignees = data.get("assignees");
    
    // Get full task details
    task = fetchTaskDetails(taskId);
    
    // Notify assignees
    for each assignee in assignees {
        if(assignee != completedBy) {
            card = {
                "theme": "success",
                "title": "✅ Task Completed",
                "text": completedBy + " completed: " + task.get("title"),
                "buttons": [
                    {
                        "label": "View Details",
                        "action": {
                            "type": "invoke.function",
                            "name": "view_task",
                            "id": taskId
                        }
                    },
                    {
                        "label": "Reopen",
                        "action": {
                            "type": "invoke.function",
                            "name": "reopen_task",
                            "id": taskId
                        }
                    }
                ]
            };
            
            zoho.cliq.postToUser(assignee, card);
        }
    }
    
    // Post to project channel if configured
    projectId = data.get("projectId");
    channelId = getProjectChannel(projectId);
    if(channelId != null) {
        zoho.cliq.postToChannel(channelId, {
            "text": "🎉 " + completedBy + " completed: " + task.get("title")
        });
    }
}
```

---

## Security & Authentication

### OAuth 2.0 Flow

**Step 1: Connection Setup in Cliq**
```deluge
// Register OAuth connection
connection_name = "tasker_oauth"
auth_url = "https://api.tasker.app/oauth/authorize"
token_url = "https://api.tasker.app/oauth/token"
client_id = "cliq_extension_12345"
client_secret = "{secure_secret}"
scopes = ["tasks:read", "tasks:write", "projects:read", "routines:read"]
```

**Step 2: User Authorization**
```
1. User installs extension
2. Extension redirects to Tasker OAuth page
3. User logs in to Tasker
4. User grants permissions
5. Tasker redirects back with authorization code
6. Extension exchanges code for access token
7. Token stored securely in connection
```

**Step 3: Token Usage**
```deluge
// Automatic token handling
response = invokeurl [
    url: "https://api.tasker.app/v1/tasks"
    type: POST
    parameters: taskData
    connection: "tasker_oauth"  // Handles token automatically
];
```

**Step 4: Token Refresh**
```deluge
// Automatic refresh when expired
// Cliq platform handles this automatically with OAuth connection
```

### Security Best Practices

**1. API Key Protection**
- Never expose app keys in client-side code
- Rotate keys quarterly
- Use separate keys for sandbox/production

**2. Data Encryption**
- All API calls over HTTPS
- Sensitive data encrypted at rest
- PII masked in logs

**3. Access Control**
- Verify user permissions before operations
- Validate project membership
- Check task ownership

**4. Rate Limiting**
- Implement exponential backoff
- Cache frequently accessed data
- Batch operations when possible

**5. Audit Logging**
```deluge
void logAction(action, userId, details) {
    zoho.cliq.createRecord("audit_log", {
        "action": action,
        "user_id": userId,
        "timestamp": zoho.currenttime,
        "details": details.toJSON(),
        "ip_address": info.get("ip"),
        "user_agent": info.get("user_agent")
    });
}
```

---

## User Experience Flows

### Flow 1: First-Time User Setup

```
1. User installs "Tasker" extension from Cliq marketplace
   ↓
2. Extension shows welcome message in bot conversation
   "Welcome to Tasker! Let's connect your account."
   [Connect Account Button]
   ↓
3. User clicks button → Redirected to OAuth page
   ↓
4. User logs in / signs up on Tasker
   ↓
5. User grants permissions (Read tasks, Create tasks, etc.)
   ↓
6. Redirect back to Cliq
   ↓
7. Extension confirms: "✅ Connected successfully!"
   Shows tutorial: "Try typing /task list to see your tasks"
   ↓
8. Widget auto-loads with user's dashboard
```

### Flow 2: Creating Task via Slash Command

```
User types: /task create "Review design mockups" project:Marketing due:friday assignee:@john priority:high

1. Cliq triggers slash command handler
   ↓
2. Extension parses parameters
   ↓
3. Validates:
   - Project exists
   - User has permission
   - @john is team member
   - Date is valid
   ↓
4. Shows confirmation card:
   "Creating task... ⏳"
   ↓
5. Calls Tasker API
   ↓
6. Updates message with result:
   "✅ Task created successfully!
   
   📋 Review design mockups
   📁 Marketing
   👤 @john
   📅 Due: Friday, Nov 24
   🔥 Priority: High
   
   [View Details] [Add Comment] [Mark Complete]"
   ↓
7. @john receives notification:
   "📬 You were assigned to: Review design mockups"
```

### Flow 3: Conversational Task Creation with Bot

```
User: @TaskerBot I need to schedule a meeting

Bot: Sure! Let's create a task for that.
     What's the meeting about?

User: Q4 planning with product team

Bot: Got it! "Q4 planning with product team"
     When should this happen?

User: next tuesday at 2pm

Bot: Perfect! Which project should this go in?
     
     [Marketing] [Engineering] [Product] [Other]

User: [Clicks Product]

Bot: Who should attend this meeting?

User: @sarah @mike @alex

Bot: Excellent! Let me create this task:
     
     📋 Q4 planning with product team
     📁 Project: Product
     📅 Due: Tuesday, Nov 28 at 2:00 PM
     👥 Attendees: @sarah @mike @alex
     
     [Create Task] [Edit] [Cancel]

User: [Clicks Create Task]

Bot: ✅ Task created! I've notified @sarah, @mike, and @alex.
     
     [View Details] [Add to Calendar] [Set Reminder]
```

### Flow 4: Widget Dashboard Interaction

```
User opens Cliq → Widget tab shows:

┌─────────────────────────────────────┐
│ Tasker Dashboard                     │
├─────────────────────────────────────┤
│ Today: 5 tasks • 2 overdue          │
├─────────────────────────────────────┤
│ 🔴 Overdue (2)                      │
│   ⚠️ Fix payment bug               │
│      Mobile • Assigned to you       │
│      [Complete] [Snooze] [View]    │
│                                      │
│   ⚠️ Update documentation           │
│      Website • Due 2 days ago       │
│      [Complete] [Reschedule]       │
├─────────────────────────────────────┤
│ 📅 Due Today (3)                    │
│   ✏️ Review PR #245                │
│   ✏️ Team standup                  │
│   ✏️ Client call prep              │
├─────────────────────────────────────┤
│ [+ Create Task] [Refresh]           │
└─────────────────────────────────────┘

User clicks [Complete] on "Fix payment bug"
   ↓
Widget shows loading indicator
   ↓
API call to mark complete
   ↓
Widget refreshes automatically
   ↓
Task moved to "Completed" section
Banner shows: "✅ Task marked complete!"
   ↓
Team members receive notification
```

### Flow 5: Message-to-Task Conversion

```
Team conversation in #mobile-dev channel:

Alice: The login form is throwing errors on iOS 16
       Users can't authenticate properly

Bob: Right-clicks Alice's message
     Context menu appears:
     
     [Reply]
     [Forward]
     [Delete]
     ─────────────────
     [📋 Create Task from Message]  ← Clicks this
     [📎 Add to Existing Task]

Form appears:
┌─────────────────────────────────┐
│ Create Task                      │
├─────────────────────────────────┤
│ Title: *                         │
│ [Login errors on iOS 16       ]│
│                                  │
│ Description:                     │
│ [The login form is throwing   ]│
│ [errors on iOS 16. Users can't]│
│ [authenticate properly         ]│
│                                  │
│ Project: [Mobile App ▼]         │
│ Assign to: [@alice @bob]        │
│ Priority: [High ▼]              │
│ Due date: [Nov 25, 2024]        │
│                                  │
│ [Create Task] [Cancel]          │
└─────────────────────────────────┘

Bob clicks [Create Task]
   ↓
Task created and linked to original message
   ↓
Bot posts in channel:
"📋 Task created: Login errors on iOS 16
Assigned: @alice @bob
Link to message: [View context]
[View Task Details]"
   ↓
Alice receives notification:
"You were assigned to a task created from your message"
```

---

## Development Phases

### Phase 1: MVP (4 weeks)

**Deliverables:**
- Basic slash commands (/task create, /task list, /task complete)
- Simple bot with mention handler
- One-way sync (Cliq → Tasker)
- OAuth connection setup
- Basic widget with task list

**Success Criteria:**
- Users can create tasks from Cliq
- Tasks appear in Tasker mobile app
- Can view task list in widget
- Authentication working

### Phase 2: Bidirectional Sync (3 weeks)

**Deliverables:**
- Webhook infrastructure in Tasker
- Extension webhook handler
- Real-time notifications
- Task update sync
- Widget auto-refresh

**Success Criteria:**
- Changes in app reflect in Cliq within 3 seconds
- Users receive notifications for assignments
- Widget updates automatically
- No manual refresh needed

### Phase 3: Enhanced Features (3 weeks)

**Deliverables:**
- Complete slash command suite
- Conversational bot with NLP
- Message actions
- Project management commands
- Routine integration

**Success Criteria:**
- All major features accessible from Cliq
- Natural language task creation works
- Message-to-task conversion seamless
- Project collaboration smooth

### Phase 4: Automation & Intelligence (2 weeks)

**Deliverables:**
- Daily digest scheduler
- Task reminder scheduler
- Weekly reports
- Smart suggestions
- Bulk operations

**Success Criteria:**
- Users receive helpful digests
- Reminders trigger on time
- Reports provide value
- Suggestions are relevant

### Phase 5: Polish & Launch (2 weeks)

**Deliverables:**
- Error handling
- Loading states
- Help documentation
- Video tutorials
- Marketplace materials

**Success Criteria:**
- App passes Zoho review
- Documentation complete
- Users can self-serve help
- Launch materials ready

---

## Testing Strategy

### Unit Testing

**Extension Functions:**
```deluge
// Test task creation
test_create_task() {
    // Mock data
    taskData = {
        "title": "Test task",
        "projectId": "proj123"
    };
    
    // Call function
    result = createTask(taskData);
    
    // Assert
    assert(result.get("success") == true);
    assert(result.get("task").get("title") == "Test task");
}
```

### Integration Testing

**API Connectivity:**
- Test each API endpoint
- Verify OAuth flow
- Check error responses
- Validate data format

**Webhook Processing:**
- Send test webhooks
- Verify handler execution
- Check notification delivery
- Validate message format

### User Acceptance Testing

**Test Scenarios:**

1. **New User Onboarding**
   - Install extension
   - Connect account
   - Create first task
   - Verify in mobile app

2. **Task Lifecycle**
   - Create task in Cliq
   - Update in mobile app
   - Verify notification in Cliq
   - Complete in Cliq
   - Verify in mobile app

3. **Collaboration**
   - Assign task to team member
   - Member receives notification
   - Member comments
   - Creator sees comment
   - Task completed
   - All notified

4. **Error Handling**
   - Invalid commands
   - Network failures
   - Permission errors
   - Rate limits

### Performance Testing

**Load Tests:**
- 100 concurrent users
- 1000 tasks created per minute
- Widget refresh with 500 tasks
- Bulk operations (50 tasks)

**Benchmarks:**
- Command response < 2 seconds
- Notification delivery < 3 seconds
- Widget load < 1 second
- API call < 500ms

---

## Deployment & Maintenance

### Pre-Launch Checklist

- [ ] All Phase 1-5 features implemented
- [ ] Unit tests pass (100% coverage)
- [ ] Integration tests pass
- [ ] UAT completed
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] Documentation complete
- [ ] Video demo recorded
- [ ] Screenshots captured
- [ ] Marketplace listing prepared
- [ ] Support channels established
- [ ] Monitoring setup
- [ ] Rollback plan ready

### Marketplace Submission

**Required Materials:**

1. **Extension Details**
   - Name: Tasker - Team Task Management
   - Category: Productivity
   - Short description (150 chars)
   - Long description (1000 chars)
   - Tags: tasks, project management, productivity, collaboration

2. **Visual Assets**
   - Icon (512x512 px)
   - Cover image (1200x600 px)
   - 5 screenshots (1280x720 px)
   - Video demo (2-3 minutes)

3. **Documentation**
   - User guide
   - Admin guide
   - API documentation
   - Privacy policy
   - Terms of service

4. **Support Information**
   - Support email
   - Documentation URL
   - FAQ page
   - Community forum link

### Post-Launch Monitoring

**Metrics to Track:**

- **Usage Metrics:**
  - Daily active users
  - Commands per user
  - Widget views
  - Bot conversations

- **Performance Metrics:**
  - API response times
  - Error rates
  - Webhook delivery success
  - Cache hit rates

- **Business Metrics:**
  - New installations
  - Active organizations
  - Task creation rate
  - User retention

**Alerting:**
```deluge
// Monitor critical metrics
scheduler health_check() {
    metrics = getHealthMetrics();
    
    if(metrics.error_rate > 0.05) {
        alertAdmin("High error rate: " + metrics.error_rate);
    }
    
    if(metrics.avg_response_time > 2000) {
        alertAdmin("Slow response time: " + metrics.avg_response_time + "ms");
    }
    
    if(metrics.webhook_failures > 10) {
        alertAdmin("Webhook delivery issues: " + metrics.webhook_failures);
    }
}
```

### Maintenance Plan

**Weekly:**
- Review error logs
- Check performance metrics
- Monitor user feedback
- Update documentation

**Monthly:**
- Security updates
- Performance optimization
- Feature requests review
- User survey

**Quarterly:**
- Major feature releases
- API key rotation
- Security audit
- Capacity planning

### Version Control Strategy

**Versioning:**
- Major.Minor.Patch (e.g., 1.2.3)
- Major: Breaking changes
- Minor: New features
- Patch: Bug fixes

**Release Process:**
1. Develop in sandbox
2. Test thoroughly
3. Create version snapshot
4. Push to production
5. Monitor for issues
6. Communicate changes

---

## Cost & Resource Estimates

### Development Resources

**Team Composition:**
- 1 Backend Developer (Tasker API & webhooks)
- 1 Deluge Developer (Cliq extension)
- 1 Flutter Developer (mobile app updates)
- 1 QA Engineer (testing)
- 1 Technical Writer (documentation)
- 1 Product Manager (coordination)

**Time Estimates:**
- Phase 1: 4 weeks (MVP)
- Phase 2: 3 weeks (Sync)
- Phase 3: 3 weeks (Features)
- Phase 4: 2 weeks (Automation)
- Phase 5: 2 weeks (Polish)
- **Total: 14 weeks (~3.5 months)**

### Infrastructure Costs

**Zoho Cliq:**
- Extension hosting: Free
- API calls: Free (within limits)
- Storage: Free (6 databases)

**Tasker Backend:**
- Firebase Cloud Functions: ~$50/month
- Firestore: ~$30/month
- Cloud Storage: ~$10/month
- Monitoring: ~$20/month
- **Total: ~$110/month**

### Ongoing Costs

**Monthly:**
- Infrastructure: $110
- Support: $200 (part-time)
- Monitoring tools: $50
- **Total: ~$360/month**

**Annual:**
- Infrastructure: $1,320
- Support: $2,400
- Monitoring: $600
- Security audit: $2,000
- **Total: ~$6,320/year**

---

## Success Metrics

### Launch Goals (First 3 Months)

- **Adoption:** 100+ organizations using extension
- **Engagement:** 50% of users active weekly
- **Tasks Created:** 10,000+ tasks via Cliq
- **Satisfaction:** 4.5+ star rating on marketplace
- **Support:** <24 hour response time

### Long-Term Goals (12 Months)

- **Adoption:** 1,000+ organizations
- **Engagement:** 70% weekly active users
- **Tasks Created:** 100,000+ tasks
- **Satisfaction:** 4.8+ star rating
- **Revenue:** (if premium features) $10k MRR

---

## Conclusion

This integration will position Tasker as a comprehensive solution for team task management directly within Zoho Cliq. The two-way communication architecture ensures seamless synchronization, while the rich extension components provide a native Cliq experience.

**Key Success Factors:**
1. Robust bidirectional sync with <3 second latency
2. Intuitive slash commands and bot interactions
3. Comprehensive widget dashboard
4. Reliable webhook delivery
5. Excellent error handling and user feedback

**Next Steps:**
1. Review and approve this technical specification
2. Set up development environment
3. Begin Phase 1 implementation
4. Schedule weekly progress reviews
5. Plan user beta testing program

---

**Document Version:** 1.0  
**Last Updated:** November 22, 2025  
**Author:** Tasker Development Team  
**Status:** Ready for Implementation
