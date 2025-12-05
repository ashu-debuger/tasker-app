# 🔥 Firebase Setup

Complete guide to configuring Firebase for Tasker.

---

## Prerequisites

- [Firebase CLI](https://firebase.google.com/docs/cli) installed
- Google account
- Flutter development environment set up

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Add project**
3. Enter project name (e.g., "Tasker")
4. Enable/disable Google Analytics (optional)
5. Click **Create project**

---

## Step 2: Add Android App

1. In Firebase Console, click **Add app** → **Android**
2. Enter package name: `com.yourname.tasker`
   - Find in `android/app/build.gradle.kts` → `applicationId`
3. Enter app nickname (optional)
4. Download `google-services.json`
5. Place in `android/app/google-services.json`

### Verify Android Configuration

In `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

In `android/build.gradle.kts`:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

---

## Step 3: Add iOS App (Optional)

1. In Firebase Console, click **Add app** → **iOS**
2. Enter bundle ID: `com.yourname.tasker`
   - Find in Xcode or `ios/Runner.xcodeproj`
3. Download `GoogleService-Info.plist`
4. Place in `ios/Runner/GoogleService-Info.plist`

### Add to Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click **Runner** → **Add Files to "Runner"**
3. Select `GoogleService-Info.plist`
4. Ensure "Copy items if needed" is checked

---

## Step 4: Enable Services

### Authentication

1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**
3. (Optional) Enable other providers as needed

### Cloud Firestore

1. Go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select a region close to your users

### Storage (if needed)

1. Go to **Storage**
2. Click **Get started**
3. Start in test mode

---

## Step 5: Firestore Security Rules

For development, use permissive rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

For production, use proper rules. See [Firestore Security Rules](../architecture/firestore-rules.md).

---

## Step 6: Firestore Indexes

Deploy indexes for complex queries:

```bash
firebase deploy --only firestore:indexes
```

Indexes are defined in `firestore.indexes.json`.

---

## Firebase CLI Commands

```bash
# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes

# View current project
firebase use
```

---

## Project Configuration Files

| File                                  | Purpose                        |
| ------------------------------------- | ------------------------------ |
| `firebase.json`                       | Firebase project configuration |
| `firestore.rules`                     | Firestore security rules       |
| `firestore.indexes.json`              | Firestore composite indexes    |
| `android/app/google-services.json`    | Android Firebase config        |
| `ios/Runner/GoogleService-Info.plist` | iOS Firebase config            |

---

## Firestore Structure

Tasker uses the following collections:

```
users/
  {userId}/
    email, displayName, createdAt
    
projects/
  {projectId}/
    name, description, ownerId, createdAt
    members/
      {memberId}/
        userId, role, joinedAt
    chat/
      {messageId}/
        
tasks/
  {taskId}/
    title, description, status, priority, dueDate
    
diary_entries/
  {userId}/
    entries/
      {entryId}/
```

See [Firestore Structure](../architecture/firebase-firestore-structure.md) for complete schema.

---

## Troubleshooting

### Missing google-services.json

Error: `File google-services.json is missing`

**Solution:** Download from Firebase Console and place in `android/app/`

### Firebase Initialization Failed

Error: `[core/no-app] No Firebase App`

**Solution:** Ensure `Firebase.initializeApp()` is called in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### Permission Denied

Error: `PERMISSION_DENIED: Missing or insufficient permissions`

**Solution:** Check Firestore rules allow the operation for the current user.

---

## Next Steps

- [Firestore Structure](../architecture/firebase-firestore-structure.md) - Database schema
- [Security Rules](../architecture/firestore-rules.md) - Access control
- [Project Overview](../architecture/overview.md) - App architecture

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Environment Config →](./environment-config.md)**

</div>
