# 🔒 Firestore Security Rules

Access control rules for Tasker's Firestore database.

---

## Overview

Firestore security rules control who can read and write data. Rules are defined in `firestore.rules` at the project root.

---

## Rules Summary

### Users Collection
| Operation | Rule                              |
| --------- | --------------------------------- |
| Read      | Own document only                 |
| Create    | Own document, matching UID        |
| Update    | Own document, cannot change email |
| Delete    | Own document                      |

### Projects Collection
| Operation | Rule                              |
| --------- | --------------------------------- |
| Read      | Members only                      |
| Create    | Authenticated, must be in members |
| Update    | Members only                      |
| Delete    | Owner only                        |

### Tasks Collection
| Operation | Rule            |
| --------- | --------------- |
| Read      | Project members |
| Create    | Project members |
| Update    | Project members |
| Delete    | Project members |

### Chat Messages
| Operation | Rule                                 |
| --------- | ------------------------------------ |
| Read      | Project members                      |
| Create    | Project members, senderId = auth.uid |
| Update    | Not allowed (immutable)              |
| Delete    | Sender only                          |

---

## Example Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Projects require membership
    match /projects/{projectId} {
      allow read: if request.auth.uid in resource.data.members;
      allow create: if request.auth.uid in request.resource.data.members;
      allow update: if request.auth.uid in resource.data.members;
      allow delete: if request.auth.uid == resource.data.ownerId;
    }
    
    // Tasks inherit project membership
    match /tasks/{taskId} {
      allow read, write: if isProjectMember(resource.data.projectId);
    }
    
    // Helper function
    function isProjectMember(projectId) {
      return request.auth.uid in 
        get(/databases/$(database)/documents/projects/$(projectId)).data.members;
    }
  }
}
```

---

## Deployment

### Deploy Rules
```bash
firebase deploy --only firestore:rules
```

### Test Locally
```bash
firebase emulators:start
```

---

## Best Practices

### ✅ Do
- Validate data types in rules
- Use helper functions for common checks
- Test rules with emulator
- Limit query results

### ❌ Don't
- Trust client-side validation alone
- Allow unrestricted reads
- Forget to secure subcollections
- Deploy without testing

---

## Common Patterns

### Check Authentication
```javascript
allow read: if request.auth != null;
```

### Check Document Owner
```javascript
allow write: if request.auth.uid == resource.data.ownerId;
```

### Validate Fields
```javascript
allow create: if request.resource.data.title is string
              && request.resource.data.title.size() > 0;
```

### Check Array Membership
```javascript
allow read: if request.auth.uid in resource.data.members;
```

---

## Related Docs

- [Firestore Structure](./firebase-firestore-structure.md) - Database schema
- [Firebase Setup](../getting-started/firebase-setup.md) - Initial configuration

---

<div align="center">

**[← Firestore Structure](./firebase-firestore-structure.md)** | **[Back to Docs](../README.md)**

</div>
