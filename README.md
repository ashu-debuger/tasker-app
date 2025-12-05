<div align="center">

# 🎯 Tasker

**A powerful task management application for individuals and teams**

Built with Flutter • Firebase • Riverpod

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-orange?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](#license)

[📚 Documentation](./docs/README.md) • [🚀 Quick Start](#-quick-start) • [✨ Features](#-features)

</div>

---

## 📖 Overview

Tasker is a comprehensive productivity app combining task management, project collaboration, and personal tools in one place. Built with Flutter for Android and iOS, it offers offline-first architecture with cloud sync.

---

## ✨ Features

| Category              | Features                                                |
| --------------------- | ------------------------------------------------------- |
| **📋 Task Management** | Tasks, subtasks, priorities, due dates, status tracking |
| **📁 Projects**        | Team collaboration, role-based access, real-time sync   |
| **💬 Communication**   | Project chat, notifications, team updates               |
| **📝 Productivity**    | Diary, sticky notes, mind maps, routines                |
| **🔗 Integrations**    | Zoho Cliq, push notifications                           |
| **🔒 Security**        | Optional encryption, secure storage                     |

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/ashu-debuger/tasker-app.git
cd tasker-app

# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Configure environment
cp .env.example .env
# Edit .env with your API keys

# Run the app
flutter run
```

📖 See the [Setup Guide](./docs/getting-started/setup-guide.md) for detailed instructions.

---

## 🏗️ Tech Stack

| Layer                | Technology                  |
| -------------------- | --------------------------- |
| **Framework**        | Flutter 3.x                 |
| **Language**         | Dart                        |
| **State Management** | Riverpod (code generation)  |
| **Navigation**       | GoRouter                    |
| **Backend**          | Firebase (Auth, Firestore)  |
| **Local Storage**    | Hive                        |
| **Notifications**    | flutter_local_notifications |

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
└── src/
    ├── core/                    # Shared utilities
    │   ├── config/              # Environment config
    │   ├── routing/             # GoRouter setup
    │   └── services/            # Core services
    └── features/                # Feature modules
        ├── auth/                # Authentication
        ├── projects/            # Projects
        ├── tasks/               # Tasks
        ├── diary/               # Personal diary
        ├── mind_maps/           # Mind mapping
        └── ...                  # More features
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter test integration_test/
```

**Coverage**: 74+ tests across auth, projects, tasks, and integrations.

---

## 📚 Documentation

Comprehensive documentation is available in the [`docs/`](./docs/README.md) folder:

| Section                                               | Description                      |
| ----------------------------------------------------- | -------------------------------- |
| [🚀 Getting Started](./docs/getting-started/README.md) | Setup, environment, Firebase     |
| [🏗️ Architecture](./docs/architecture/README.md)       | Tech stack, patterns, data layer |
| [✨ Features](./docs/features/README.md)               | All feature documentation        |
| [🔌 Integrations](./docs/integrations/README.md)       | Zoho Cliq, Firebase              |
| [📋 Development](./docs/development/README.md)         | Roadmap, phases, contributing    |

---

## 🗺️ Roadmap

| Phase       | Focus                                            | Status        |
| ----------- | ------------------------------------------------ | ------------- |
| **Phase 1** | Core functionality (auth, tasks, projects, chat) | ✅ Complete    |
| **Phase 2** | Advanced features (diary, mind maps, offline)    | ✅ Complete    |
| **Phase 3** | Extensibility & AI (plugins, themes, AI)         | 🚧 In Progress |

See [Development Phases](./docs/development/phases-overview.md) for details.

---

## 🔗 Integrations

### Zoho Cliq
Manage tasks directly from Zoho Cliq:
- Slash commands (`/tasker list`, `/tasker add`)
- TaskerBot for natural language
- Home widget dashboard

📖 [Zoho Cliq Integration Guide](./docs/integrations/zoho-cliq/overview.md)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `flutter test`
5. Submit a pull request

---

## 🔗 Related Repositories

| Repository | Description |
|------------|-------------|
| [📱 Tasker App](https://github.com/ashu-debuger/tasker-app) | Flutter mobile application (this repo) |
| [⚙️ Tasker Backend](https://github.com/ashu-debuger/tasker-backend) | Node.js API & Zoho Cliq integration |
| [📥 Download APK](https://github.com/End-side-Developer/ESD-App_download) | Latest Android release |

---

## 📄 License

Proprietary - All rights reserved

---

<div align="center">

**Built with ❤️ using Flutter**

[📚 Documentation](./docs/README.md) • [⭐ Star this repo](https://github.com/ashu-debuger/tasker-app) • [📥 Download](https://github.com/End-side-Developer/ESD-App_download)

</div>
