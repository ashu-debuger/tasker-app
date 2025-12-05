# 📚 Tasker Documentation

Welcome to the Tasker documentation! This guide will help you understand, set up, and contribute to the Tasker app.

---

## 🗂️ Quick Navigation

| Section                                | Description                                    |
| -------------------------------------- | ---------------------------------------------- |
| [🚀 Getting Started](#-getting-started) | Setup and installation guides                  |
| [🏗️ Architecture](#️-architecture)       | App structure and design patterns              |
| [✨ Features](#-features)               | Feature-specific documentation                 |
| [🔌 Integrations](#-integrations)       | Third-party integrations (Zoho Cliq, Firebase) |
| [📋 Development](#-development)         | Development guides and roadmaps                |
| [🔒 Security](#-security)               | Security and data protection                   |

---

## 🚀 Getting Started

New to Tasker? Start here!

- **[Setup Guide](./getting-started/setup-guide.md)** - Complete installation and configuration
- **[Environment Configuration](./getting-started/environment-config.md)** - Setting up `.env` and secrets
- **[Firebase Setup](./getting-started/firebase-setup.md)** - Firebase project configuration

---

## 🏗️ Architecture

Understand how Tasker is built.

- **[Project Overview](./architecture/overview.md)** - High-level architecture and tech stack
- **[Folder Structure](./architecture/folder-structure.md)** - Codebase organization
- **[State Management](./architecture/state-management.md)** - Riverpod patterns and providers
- **[Data Layer](./architecture/data-layer.md)** - Repositories, models, and Firebase

### Database & Storage
- **[Firestore Structure](./architecture/firebase-firestore-structure.md)** - Database schema and collections
- **[Firestore Security Rules](./architecture/firestore-rules.md)** - Security rules documentation
- **[Local Storage (Hive)](./architecture/local-storage.md)** - Offline data with Hive

---

## ✨ Features

Detailed documentation for each feature.

### Core Features
| Feature          | Description                               | Docs                                       |
| ---------------- | ----------------------------------------- | ------------------------------------------ |
| 🔐 Authentication | Email/password, persistent sessions       | [Auth Guide](./features/authentication.md) |
| 📁 Projects       | Create, manage, collaborate on projects   | [Projects Guide](./features/projects.md)   |
| ✅ Tasks          | Task management with subtasks, priorities | [Tasks Guide](./features/tasks.md)         |
| 💬 Chat           | Real-time project chat                    | [Chat Guide](./features/chat.md)           |

### Productivity Features
| Feature        | Description                         | Docs                                             |
| -------------- | ----------------------------------- | ------------------------------------------------ |
| 📝 Diary        | Personal journal with mood tracking | [Diary Guide](./features/diary.md)               |
| 📌 Sticky Notes | Quick notes with rich text          | [Sticky Notes Guide](./features/sticky-notes.md) |
| 🧠 Mind Maps    | Visual idea organization            | [Mind Maps Guide](./features/mind-maps.md)       |
| 🔄 Routines     | Daily routines and habits           | [Routines Guide](./features/routines.md)         |
| ⏰ Reminders    | Task reminders and notifications    | [Reminders Guide](./features/reminders.md)       |

### Advanced Features
| Feature         | Description                  | Docs                                               |
| --------------- | ---------------------------- | -------------------------------------------------- |
| 📅 Calendar      | Calendar view and scheduling | [Calendar Guide](./features/calendar.md)           |
| 🔔 Notifications | Push notifications system    | [Notifications Guide](./features/notifications.md) |
| 🔌 Plugins       | Extensibility system         | [Plugin System](./features/plugins.md)             |

---

## 🔌 Integrations

Connect Tasker with external services.

### Zoho Cliq Integration
- **[Integration Overview](./integrations/zoho-cliq/overview.md)** - What's possible with Cliq
- **[Step-by-Step Setup](./integrations/zoho-cliq/setup-guide.md)** - Complete setup instructions
- **[Slash Commands](./integrations/zoho-cliq/slash-commands.md)** - Available commands reference
- **[Bot & Widgets](./integrations/zoho-cliq/bot-widgets.md)** - TaskerBot and dashboard widgets

### Firebase
- **[Firebase Configuration](./getting-started/firebase-setup.md)** - Project setup
- **[Firestore Structure](./architecture/firebase-firestore-structure.md)** - Database design
- **[Security Rules](./architecture/firestore-rules.md)** - Access control

---

## 📋 Development

For contributors and developers.

### Roadmap & Planning
- **[Development Phases](./development/phases-overview.md)** - Project roadmap
- **[Phase 1: Core](./development/phase-1-core.md)** - Authentication, tasks, projects ✅
- **[Phase 2: Advanced](./development/phase-2-advanced.md)** - Encryption, offline, UI ✅
- **[Phase 3: AI & Plugins](./development/phase-3-ai-plugins.md)** - Extensibility

### Technical Guides
- **[Task Reminder Architecture](./development/task-reminder-architecture.md)** - Reminder system design
- **[Notification System](./development/notifications-guide.md)** - Push notification implementation
- **[Collaboration Features](./development/collaboration-features.md)** - Multi-user features

### Reports
- **[Phase 1 Completion Report](./development/reports/phase-1-completion.md)** - Phase 1 summary
- **[Phase 2 Completion Report](./development/reports/phase-2-completion.md)** - Phase 2 summary

---

## 🔒 Security

Security best practices and implementation.

- **[Firestore Security Rules](./architecture/firestore-rules.md)** - Database access control
- **[Environment Variables](./getting-started/environment-config.md)** - Secrets management
- **[Encryption](./security/encryption.md)** - Data encryption practices

---

## 🔍 Search by Topic

Looking for something specific?

| Topic                    | Related Docs                                                                                                               |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| **Setup & Installation** | [Setup Guide](./getting-started/setup-guide.md), [Firebase Setup](./getting-started/firebase-setup.md)                     |
| **Tasks & Subtasks**     | [Tasks Guide](./features/tasks.md), [Reminders](./features/reminders.md)                                                   |
| **Projects & Teams**     | [Projects Guide](./features/projects.md), [Collaboration](./development/collaboration-features.md)                         |
| **Zoho Cliq**            | [Cliq Overview](./integrations/zoho-cliq/overview.md), [Slash Commands](./integrations/zoho-cliq/slash-commands.md)        |
| **Notifications**        | [Reminders](./features/reminders.md), [Notification System](./development/notifications-guide.md)                          |
| **Database**             | [Firestore Structure](./architecture/firebase-firestore-structure.md), [Security Rules](./architecture/firestore-rules.md) |
| **State Management**     | [Riverpod Patterns](./architecture/state-management.md), [Providers](./architecture/data-layer.md)                         |

---

## 📖 Document Status

| Document              | Status     | Last Updated |
| --------------------- | ---------- | ------------ |
| Getting Started       | ✅ Complete | Dec 2025     |
| Architecture          | ✅ Complete | Dec 2025     |
| Features              | ✅ Complete | Dec 2025     |
| Zoho Cliq Integration | ✅ Complete | Dec 2025     |
| Development Roadmap   | ✅ Complete | Dec 2025     |

---

## 🤝 Contributing to Docs

Found an issue or want to improve the docs?

1. Check existing docs for the topic
2. Follow the folder structure conventions
3. Use proper Markdown formatting
4. Add hyperlinks for cross-references
5. Update this index if adding new docs

---

<div align="center">

**[← Back to Main README](../README.md)** | **[Report an Issue](https://github.com/ashu-debuger/tasker-app/issues)**

</div>
