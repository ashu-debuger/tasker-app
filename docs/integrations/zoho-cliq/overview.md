# 🔗 Zoho Cliq Integration

Overview of Tasker's integration with Zoho Cliq.

---

## What is Zoho Cliq?

[Zoho Cliq](https://www.zoho.com/cliq/) is a team communication platform similar to Slack. Tasker integrates with Cliq to bring task management directly into your team's communication workflow.

---

## Features

### Slash Commands
Execute Tasker commands directly in Cliq:

| Command           | Description         |
| ----------------- | ------------------- |
| `/tasker list`    | List your tasks     |
| `/tasker add`     | Create a new task   |
| `/tasker project` | View project tasks  |
| `/tasker stats`   | See task statistics |

### TaskerBot
An intelligent bot that:
- 📝 Creates tasks from messages
- 🔔 Sends reminders
- 📊 Shows daily summaries
- 💬 Responds to queries

### Home Widget
Dashboard showing:
- Today's tasks
- Overdue items
- Quick actions
- Project overview

---

## Architecture

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Zoho Cliq      │────▶│  Tasker Backend  │────▶│    Firebase      │
│   (Commands,     │     │    (Node.js)     │     │   (Firestore)    │
│    Widgets)      │◀────│                  │◀────│                  │
└──────────────────┘     └──────────────────┘     └──────────────────┘
                                  ▲
                                  │
                                  ▼
                         ┌──────────────────┐
                         │   Flutter App    │
                         │    (Tasker)      │
                         └──────────────────┘
```

---

## Setup

For detailed setup instructions, see:

1. **[Setup Guide](./setup-guide.md)** - Complete step-by-step setup
2. **[Slash Commands](./slash-commands.md)** - Command reference
3. **[Bot & Widgets](./bot-widgets.md)** - TaskerBot configuration

---

## User Mapping

Cliq users must be linked to Tasker accounts:

```
Cliq User ID  ──▶  Tasker User ID
```

This mapping is stored in Firebase and managed via:
- In-app linking screen
- OAuth flow
- Backend API

---

## Quick Links

| Topic              | Link                                                            |
| ------------------ | --------------------------------------------------------------- |
| Setup from scratch | [Setup Guide](./setup-guide.md)                                 |
| Command reference  | [Slash Commands](./slash-commands.md)                           |
| Bot configuration  | [Bot & Widgets](./bot-widgets.md)                               |
| Backend API        | [API Reference](../../Tasker%20Backend/docs/API_INTEGRATION.md) |

---

## Related Docs

- [Backend Integration](../../Tasker%20Backend/README.md) - Node.js backend
- [Environment Config](../getting-started/environment-config.md) - API configuration

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Setup Guide →](./setup-guide.md)**

</div>
