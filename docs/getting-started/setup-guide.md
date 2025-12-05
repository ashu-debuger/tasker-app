# 🚀 Setup Guide

Complete guide to get Tasker running on your machine.

---

## Prerequisites

Before you begin, ensure you have:

- **Flutter SDK** (3.x or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase CLI** - [Install Firebase CLI](https://firebase.google.com/docs/cli)
- **Git** - [Install Git](https://git-scm.com/)

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/ashu-debuger/tasker-app.git
cd tasker-app

# 2. Install dependencies
flutter pub get

# 3. Generate code (providers, models)
dart run build_runner build --delete-conflicting-outputs

# 4. Set up environment variables
cp .env.example .env
# Edit .env with your API keys

# 5. Run the app
flutter run
```

---

## Step-by-Step Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/ashu-debuger/tasker-app.git
cd tasker-app
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

### Step 3: Code Generation

Tasker uses code generation for Riverpod providers and Freezed models. Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

> 💡 **Tip:** Use `watch` for continuous generation during development:
> ```bash
> dart run build_runner watch --delete-conflicting-outputs
> ```

### Step 4: Environment Configuration

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
# Backend API Configuration
TASKER_API_BASE_URL=https://your-backend-url/api
TASKER_API_KEY=your-api-key-here
```

See [Environment Configuration](./environment-config.md) for details.

### Step 5: Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Add Android and iOS apps to your project
3. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

See [Firebase Setup Guide](./firebase-setup.md) for detailed instructions.

### Step 6: Run the App

```bash
# Run on connected device
flutter run

# Run on specific device
flutter devices  # List devices
flutter run -d <device_id>
```

---

## IDE Setup

### VS Code

1. Install the **Flutter** extension
2. Install the **Dart** extension
3. Open the project folder
4. Press `F5` to run

Recommended extensions:
- Flutter
- Dart
- Error Lens
- GitLens

### Android Studio

1. Install the **Flutter** plugin
2. Install the **Dart** plugin
3. Open the project as a Flutter project
4. Click the **Run** button

---

## Common Issues

### Build Runner Errors

If code generation fails:

```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Firebase Configuration Missing

Ensure you have:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### Environment Variables Not Loading

Check that:
1. `.env` file exists in project root
2. `.env` is listed in `pubspec.yaml` assets
3. `EnvConfig.init()` is called before app start

---

## Next Steps

- [Environment Configuration](./environment-config.md) - Detailed env setup
- [Firebase Setup](./firebase-setup.md) - Complete Firebase configuration
- [Project Overview](../architecture/overview.md) - Understand the codebase

---

<div align="center">

**[← Back to Docs](../README.md)**

</div>
