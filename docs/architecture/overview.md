# 🏗️ Project Overview

High-level architecture and tech stack for the Tasker application.

---

## What is Tasker?

Tasker is a comprehensive **task management and productivity application** built with Flutter for Android and iOS. It combines task management, project collaboration, personal journaling, and productivity tools in a single app.

---

## Tech Stack

| Layer                | Technology                      |
| -------------------- | ------------------------------- |
| **Framework**        | Flutter 3.x                     |
| **Language**         | Dart                            |
| **State Management** | Riverpod (with code generation) |
| **Navigation**       | GoRouter                        |
| **Backend**          | Firebase (Auth, Firestore)      |
| **Local Storage**    | Hive                            |
| **Notifications**    | flutter_local_notifications     |

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                    Presentation Layer                     │
│  (Widgets, Screens, ConsumerWidget, ConsumerStatefulWidget) │
├──────────────────────────────────────────────────────────┤
│                    Application Layer                      │
│         (Riverpod Notifiers, Business Logic)              │
├──────────────────────────────────────────────────────────┤
│                      Data Layer                           │
│        (Repositories, Firebase, Hive Adapters)            │
├──────────────────────────────────────────────────────────┤
│                     Domain Layer                          │
│         (Models, Entities, Value Objects)                 │
└──────────────────────────────────────────────────────────┘
```

---

## Key Features

### Core Productivity
- ✅ **Task Management** - Create, organize, and track tasks with subtasks
- 📁 **Projects** - Collaborative workspaces with role-based access
- 💬 **Real-time Chat** - In-project communication
- 📅 **Calendar View** - Visual scheduling

### Personal Tools
- 📝 **Diary** - Personal journal with mood tracking
- 📌 **Sticky Notes** - Quick notes with rich text
- 🧠 **Mind Maps** - Visual idea organization
- 🔄 **Routines** - Daily habit tracking

### Integrations
- 🔗 **Zoho Cliq** - Slash commands and bots
- 🔔 **Push Notifications** - Reminders and updates
- ☁️ **Cloud Sync** - Cross-device synchronization

---

## Development Phases

### Phase 1: Core Functionality ✅
- User authentication (Email/Password)
- Project and task management
- Real-time chat
- Basic UI/UX

### Phase 2: Advanced Features ✅
- End-to-end encryption
- Sticky notes and mind maps
- Personal routines
- Offline-first architecture

### Phase 3: Extensibility 🚧
- Plugin system
- AI-powered suggestions
- Platform-specific features
- Advanced integrations

See [Development Phases](../development/phases-overview.md) for details.

---

## Core Principles

### 1. Offline-First
- Local data stored in Hive
- Firebase sync when online
- Graceful degradation without network

### 2. Feature-Based Architecture
- Each feature is self-contained
- Clear separation of concerns
- Easy to add/modify features

### 3. Type Safety
- Freezed for immutable models
- Riverpod for type-safe state
- Null safety throughout

### 4. Security
- Firebase security rules
- Environment variable management
- Optional encryption for sensitive data

---

## Related Docs

- [Folder Structure](./folder-structure.md) - Codebase organization
- [State Management](./state-management.md) - Riverpod patterns
- [Data Layer](./data-layer.md) - Repositories and models

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Folder Structure →](./folder-structure.md)**

</div>
