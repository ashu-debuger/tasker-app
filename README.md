# Tasker by Mantra

A powerful task management application for individuals and teams, built with Flutter and Firebase.

## 🎯 Project Status

**Phase 1: COMPLETE** ✅ (35/35 tasks)

All core functionality implemented, tested, and production-ready.

## 🚀 Features

### Authentication

- Email/password authentication via Firebase
- User registration and sign-in
- Password reset functionality
- Persistent authentication state

### Project Management

- Create, read, update, and delete projects
- Multi-user project collaboration
- Real-time project synchronization
- Member management

### Task Management

- Hierarchical task structure with subtasks
- Task status tracking (todo, inProgress, done)
- Priority levels (low, medium, high)
- Due dates and assignees
- Cascade delete (deleting a task removes all subtasks)

### Real-time Chat

- Project-based chat rooms
- Real-time message streaming
- Message persistence with Firestore

## 🏗️ Architecture

### Tech Stack

- **Framework**: Flutter 3.27.2
- **State Management**: Riverpod with code generation
- **Backend**: Firebase (Auth + Firestore)
- **Local Storage**: Hive (configured, not yet integrated)
- **Navigation**: GoRouter with authentication guards
- **Testing**: flutter_test, mockito, fake_cloud_firestore

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase config
└── src/
    ├── core/                    # Shared infrastructure
    │   ├── error/              # Error handling
    │   ├── logging/            # Structured logging
    │   ├── providers/          # Shared providers
    │   └── routing/            # GoRouter config
    └── features/               # Feature modules
        ├── auth/               # Authentication
        ├── projects/           # Project management
        ├── tasks/              # Task management
        └── chat/               # Real-time chat
```

Each feature follows clean architecture:

- `data/models/` - Data models with JSON serialization
- `data/repositories/` - Firebase data access
- `presentation/notifiers/` - Riverpod state management
- `presentation/screens/` - UI components

## 🧪 Testing

**Total Test Coverage**: 74 tests (100% passing)

- **Auth Tests**: 27 (19 repository + 8 notifier)
- **Project Tests**: 20 (13 repository + 7 notifier)
- **Task Tests**: 24 (18 repository + 6 notifier)
- **Integration Tests**: 3 (end-to-end workflows)

### Run Tests

```powershell
# All unit tests
flutter test

# Integration tests only
flutter test integration_test/app_test.dart

# With coverage
flutter test --coverage
```

## 🔧 Development

### Prerequisites

- Flutter SDK 3.27.2 or higher
- Dart SDK 3.9.2 or higher
- Firebase project configured
- Android Studio / VS Code with Flutter extension

### Setup

1. Clone the repository

```powershell
git clone <repository-url>
cd tasker
```

2. Install dependencies

```powershell
flutter pub get
```

3. Configure Firebase

- Add `google-services.json` to `android/app/`
- Add `GoogleService-Info.plist` to `ios/Runner/`
- Ensure `lib/firebase_options.dart` is configured

4. Set up environment variables

```powershell
# Copy the example env file
cp .env.example .env

# Edit .env and add your CLIQ_API_KEY
# Then set as environment variable:
$env:CLIQ_API_KEY="your_api_key_here"
```

5. Run code generation

```powershell
dart run build_runner build
```

6. Run the app

```powershell
# With environment variable
flutter run --dart-define=CLIQ_API_KEY=$env:CLIQ_API_KEY

# Or if CLIQ_API_KEY is set in environment, VS Code launch configs will use it automatically
```

### Code Quality

```powershell
# Format code
flutter format .

# Analyze code
flutter analyze

# Run all quality checks (CI pipeline)
flutter format --set-exit-if-changed .
flutter analyze
flutter test
```

## 📋 CI/CD

GitHub Actions workflow configured at `.github/workflows/ci.yml`

**Pipeline Steps:**

1. Checkout code
2. Set up Flutter
3. Install dependencies
4. Verify formatting
5. Analyze code
6. Run unit tests with coverage
7. Run integration tests
8. Upload coverage to Codecov (optional)

## 📚 Documentation

- **[docs/overview.md](docs/overview.md)** - Project overview and architecture
- **[docs/task-board.md](docs/task-board.md)** - Development roadmap and task tracking
- **[docs/phase-1-completion-report.md](docs/phase-1-completion-report.md)** - Phase 1 completion details
- **[docs/phase-1-core-functionality.md](docs/phase-1-core-functionality.md)** - Phase 1 requirements
- **[docs/phase-2-advanced-features.md](docs/phase-2-advanced-features.md)** - Phase 2 roadmap
- **[docs/phase-3-extensibility-and-ai.md](docs/phase-3-extensibility-and-ai.md)** - Phase 3 roadmap

## 🗺️ Roadmap

### Phase 2: Advanced Features (Upcoming)

- End-to-end encryption for chat
- Offline mode with Hive synchronization
- Recurring tasks and task templates
- File attachments
- Push notifications
- Enhanced UI/UX with Material Design 3

### Phase 3: Extensibility & AI

- Plugin system for third-party integrations
- AI-powered task suggestions
- Natural language task creation
- Analytics dashboard
- Calendar integration

## 🤝 Contributing

This is a private project. Contributions are not currently accepted.

## 📄 License

Proprietary - All rights reserved

## 🏆 Achievements

- ✅ 35 tasks completed in Phase 1
- ✅ 74 tests with 100% pass rate
- ✅ Clean architecture with separation of concerns
- ✅ Automated CI/CD pipeline
- ✅ Production-ready codebase

---

**Built with ❤️ using Flutter**
