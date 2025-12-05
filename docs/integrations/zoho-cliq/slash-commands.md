# ⚡ Slash Commands Reference

Complete reference for Tasker slash commands in Zoho Cliq.

---

## Basic Usage

```
/tasker [command] [options]
```

---

## Commands

### `/tasker list`

List your tasks.

**Options:**
| Option           | Description       |
| ---------------- | ----------------- |
| `--all`          | Show all tasks    |
| `--today`        | Tasks due today   |
| `--overdue`      | Overdue tasks     |
| `--project [id]` | Filter by project |

**Examples:**
```
/tasker list
/tasker list --today
/tasker list --project abc123
```

**Response:**
```
📋 Your Tasks (5 items)

1. ✅ Review PR #42 [High] - Due: Today
2. ⏳ Update documentation [Medium]
3. ⏳ Fix login bug [Urgent] - Overdue!
4. ✅ Team meeting prep [Low] - Due: Tomorrow
5. ⏳ Deploy v2.0 [High] - Due: Dec 20
```

---

### `/tasker add`

Create a new task.

**Usage:**
```
/tasker add [title]
```

**Examples:**
```
/tasker add Review pull request
/tasker add "Fix bug in login screen"
```

**Response:**
Opens a form to complete task details:
- Title (pre-filled)
- Description
- Priority
- Due date
- Project

---

### `/tasker project`

View project tasks.

**Usage:**
```
/tasker project [project-name|id]
```

**Examples:**
```
/tasker project "Mobile App"
/tasker project abc123
```

**Response:**
```
📁 Mobile App

Progress: ████████░░ 80%

Tasks:
├── ✅ Design mockups
├── ✅ Implement UI
├── ⏳ Add authentication
└── ⏳ Deploy to store
```

---

### `/tasker stats`

View task statistics.

**Usage:**
```
/tasker stats [--week|--month]
```

**Examples:**
```
/tasker stats
/tasker stats --week
```

**Response:**
```
📊 Your Stats (This Week)

Completed: 12 tasks ✅
In Progress: 5 tasks ⏳
Created: 8 tasks 📝

🔥 Streak: 5 days
⭐ Points: 340
```

---

### `/tasker complete`

Mark a task as complete.

**Usage:**
```
/tasker complete [task-id|task-number]
```

**Examples:**
```
/tasker complete 1
/tasker complete abc123
```

---

### `/tasker help`

Show available commands.

**Usage:**
```
/tasker help [command]
```

**Examples:**
```
/tasker help
/tasker help add
```

---

## Response Formats

### Task Card
```
┌────────────────────────────────┐
│ ✅ Task Title                  │
│ Priority: High 🔴               │
│ Due: Dec 15, 2025              │
│ Project: Mobile App            │
│                                │
│ [Mark Done] [Edit] [View]      │
└────────────────────────────────┘
```

### List View
```
📋 Tasks (3 items)

1. Task one [High]
2. Task two [Medium] - Due: Today
3. Task three [Low]
```

---

## Interactive Elements

Commands return interactive buttons:

| Button        | Action         |
| ------------- | -------------- |
| ✅ Mark Done   | Complete task  |
| ✏️ Edit        | Open edit form |
| 👁️ View        | Show details   |
| ➕ Add Subtask | Create subtask |
| 🗑️ Delete      | Remove task    |

---

## Error Messages

| Error                | Meaning                   |
| -------------------- | ------------------------- |
| `Account not linked` | Link Cliq to Tasker first |
| `Task not found`     | Invalid task ID           |
| `Permission denied`  | Not authorized            |
| `Invalid command`    | Check syntax              |

---

## Tips

- Use quotes for multi-word values
- Task numbers refer to list order
- Commands are case-insensitive
- Use `--help` on any command

---

<div align="center">

**[← Setup Guide](./setup-guide.md)** | **[Bot & Widgets →](./bot-widgets.md)**

</div>
