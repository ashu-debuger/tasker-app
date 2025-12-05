# Firestore Security Rules

This directory contains the Firestore security rules for the Tasker application.

## Rules Overview

### Users Collection

- **Read**: Users can only read their own user document
- **Create**: Users can only create their own user document (uid must match)
- **Update**: Users can update their own profile, but cannot change email
- **Delete**: Users can delete their own account

### Projects Collection

- **Read**: Only project members can read project data
- **Create**: Authenticated users can create projects and must be in the members list
- **Update**: Only project members can update project data
- **Delete**: Only project members can delete projects

### Tasks Collection

- **Read**: Only members of the associated project can read tasks
- **Create**: Only project members can create tasks for that project
- **Update**: Only project members can update tasks
- **Delete**: Only project members can delete tasks

### Subtasks Collection

- **Read**: All authenticated users can read subtasks
- **Create**: Authenticated users can create subtasks
- **Update**: Authenticated users can update subtasks
- **Delete**: Authenticated users can delete subtasks

### Chat Messages Collection

- **Read**: Only project members can read chat messages
- **Create**: Only project members can create messages (senderId must match auth.uid)
- **Update**: Messages cannot be updated (immutable)
- **Delete**: Only the sender can delete their own messages

## Deploying Rules

To deploy the Firestore security rules to Firebase:

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy rules only
firebase deploy --only firestore:rules

# Or deploy all Firebase resources
firebase deploy
```

## Testing Rules

You can test the rules locally using the Firebase Emulator Suite:

```bash
# Install emulators
firebase init emulators

# Start emulators
firebase emulators:start
```

## Notes

- These rules are a **draft** and should be reviewed and tested thoroughly before production use
- Consider adding more granular permissions as features are implemented
- Encryption and advanced security features will be added in Phase 2
- Rules should be tested with the Firebase Emulator Suite before deploying to production
