# 🤖 Bot & Widgets

TaskerBot and dashboard widgets in Zoho Cliq.

---

## TaskerBot

An intelligent assistant for task management.

### Capabilities

| Feature          | Description               |
| ---------------- | ------------------------- |
| Natural language | Understands task requests |
| Reminders        | Sends due date alerts     |
| Summaries        | Daily/weekly reports      |
| Quick actions    | Interactive buttons       |

---

### Conversation Examples

**Create a task:**
```
You: Create a task to review the PR
Bot: ✅ Created task "Review the PR"
     Would you like to set a due date?
     [Today] [Tomorrow] [Next Week] [Custom]
```

**Check tasks:**
```
You: What's on my plate today?
Bot: 📋 You have 3 tasks due today:

     1. Review PR #42 - High priority
     2. Team standup - 10:00 AM
     3. Update docs - Low priority
     
     [View All] [Add Task]
```

**Get summary:**
```
You: Give me a summary
Bot: 📊 Your Weekly Summary

     ✅ Completed: 8 tasks
     ⏳ In Progress: 3 tasks
     📋 Pending: 5 tasks
     
     Great job! You're 60% through your tasks.
```

---

### Bot Commands

| Phrase                   | Action        |
| ------------------------ | ------------- |
| "show my tasks"          | List tasks    |
| "create task [name]"     | Add task      |
| "what's due today"       | Today's tasks |
| "complete [task]"        | Mark done     |
| "remind me about [task]" | Set reminder  |

---

### Bot Configuration

In Cliq Developer Console:

```javascript
// Bot incoming handler
response = {
  "text": "Hello! I'm TaskerBot 🤖",
  "bot": {
    "name": "TaskerBot",
    "image": "https://example.com/bot-icon.png"
  },
  "buttons": [
    {
      "label": "View Tasks",
      "type": "+",
      "action": {
        "type": "invoke.function",
        "data": { "action": "list_tasks" }
      }
    }
  ]
}
```

---

## Home Widget

Dashboard widget showing task overview.

### Layout

```
┌──────────────────────────────────┐
│  🎯 Tasker                       │
├──────────────────────────────────┤
│                                  │
│  📊 Today's Overview             │
│  ─────────────────               │
│  Tasks Due: 3                    │
│  Completed: 2                    │
│  Overdue: 1 ⚠️                   │
│                                  │
├──────────────────────────────────┤
│  📋 Upcoming Tasks               │
│  ─────────────────               │
│  • Review PR - Due in 2h         │
│  • Team meeting - 3:00 PM        │
│  • Deploy app - Tomorrow         │
│                                  │
├──────────────────────────────────┤
│  [+ Add Task]  [View All]        │
└──────────────────────────────────┘
```

---

### Widget Sections

| Section   | Content          |
| --------- | ---------------- |
| Header    | App branding     |
| Overview  | Daily stats      |
| Task List | Upcoming tasks   |
| Actions   | Quick add button |

---

### Widget Configuration

```javascript
// Widget handler
response = {
  "type": "applet",
  "tabs": [
    {
      "type": "form",
      "title": "Today",
      "name": "today_tab",
      "sections": [
        {
          "id": "overview",
          "elements": [
            {
              "type": "text",
              "name": "stats",
              "text": "Tasks Due: 3 | Completed: 2"
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Button Widget

Quick actions in channels.

### Available Actions

| Button     | Function        |
| ---------- | --------------- |
| ➕ Add Task | Create new task |
| 📋 My Tasks | View task list  |
| 📊 Stats    | Show statistics |
| ⚙️ Settings | Widget settings |

---

## Message Actions

Right-click menu on messages:

| Action       | Description             |
| ------------ | ----------------------- |
| Create Task  | Turn message into task  |
| Add to Task  | Append to existing task |
| Set Reminder | Remind about message    |

---

### Creating Task from Message

1. Right-click any message
2. Select "Create Tasker Task"
3. Edit details in form
4. Click Create

The message content becomes the task description.

---

## Scheduled Messages

TaskerBot sends automated messages:

| Time       | Message            |
| ---------- | ------------------ |
| 9:00 AM    | Daily task summary |
| End of day | Completion report  |
| Task due   | Due date reminder  |

---

## Customization

### Widget Appearance

Configure in extension settings:
- Color theme
- Visible sections
- Number of tasks shown
- Refresh interval

### Bot Personality

Customize bot responses:
- Greeting message
- Emoji usage
- Response style
- Language

---

<div align="center">

**[← Slash Commands](./slash-commands.md)** | **[Back to Docs](../../README.md)**

</div>
