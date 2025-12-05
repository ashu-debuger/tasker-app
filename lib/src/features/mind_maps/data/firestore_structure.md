# Mind Maps Firestore Structure

## Collections

### mindMaps (Root Collection)

Collection path: `mindMaps/{mindMapId}`

**Document Fields:**

- `id` (string): Mind map unique identifier
- `title` (string): Mind map title
- `description` (string, optional): Mind map description
- `userId` (string): Owner's user ID
- `rootNodeId` (string): ID of the root node
- `createdAt` (timestamp): Creation timestamp
- `updatedAt` (timestamp, optional): Last update timestamp
- `collaboratorIds` (array of strings): List of collaborator user IDs

**Subcollections:**

- `nodes`: Contains all nodes for this mind map

### nodes (Subcollection)

Collection path: `mindMaps/{mindMapId}/nodes/{nodeId}`

**Document Fields:**

- `id` (string): Node unique identifier
- `mindMapId` (string): Parent mind map ID
- `text` (string): Node content/text
- `parentId` (string, optional): Parent node ID (null for root node)
- `childIds` (array of strings): List of child node IDs
- `x` (number): X coordinate for canvas positioning
- `y` (number): Y coordinate for canvas positioning
- `color` (string): Node color (enum: blue, green, yellow, orange, red, purple, pink, gray)
- `isCollapsed` (boolean): Whether children are collapsed
- `createdAt` (timestamp): Creation timestamp
- `updatedAt` (timestamp, optional): Last update timestamp

## Security Rules Example

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Mind maps collection
    match /mindMaps/{mindMapId} {
      // Allow read if user is owner or collaborator
      allow read: if request.auth != null &&
        (resource.data.userId == request.auth.uid ||
         request.auth.uid in resource.data.collaboratorIds);

      // Allow create if user is authenticated and is the owner
      allow create: if request.auth != null &&
        request.resource.data.userId == request.auth.uid;

      // Allow update if user is owner or collaborator
      allow update: if request.auth != null &&
        (resource.data.userId == request.auth.uid ||
         request.auth.uid in resource.data.collaboratorIds);

      // Allow delete only if user is owner
      allow delete: if request.auth != null &&
        resource.data.userId == request.auth.uid;

      // Nodes subcollection
      match /nodes/{nodeId} {
        // Inherit permissions from parent mind map
        allow read: if request.auth != null &&
          (get(/databases/$(database)/documents/mindMaps/$(mindMapId)).data.userId == request.auth.uid ||
           request.auth.uid in get(/databases/$(database)/documents/mindMaps/$(mindMapId)).data.collaboratorIds);

        allow write: if request.auth != null &&
          (get(/databases/$(database)/documents/mindMaps/$(mindMapId)).data.userId == request.auth.uid ||
           request.auth.uid in get(/databases/$(database)/documents/mindMaps/$(mindMapId)).data.collaboratorIds);
      }
    }
  }
}
```

## Indexes

### Composite Indexes

1. **User's Mind Maps (ordered by update time)**

   - Collection: `mindMaps`
   - Fields: `userId` (Ascending), `updatedAt` (Descending)

2. **Mind Map Nodes (ordered by creation time)**
   - Collection: `mindMaps/{mindMapId}/nodes`
   - Fields: `createdAt` (Ascending)

## Query Examples

### Get user's mind maps

```dart
_firestore
  .collection('mindMaps')
  .where('userId', isEqualTo: userId)
  .orderBy('updatedAt', descending: true)
  .snapshots()
```

### Get all nodes for a mind map

```dart
_firestore
  .collection('mindMaps')
  .doc(mindMapId)
  .collection('nodes')
  .orderBy('createdAt')
  .snapshots()
```

### Get specific node

```dart
_firestore
  .collection('mindMaps')
  .doc(mindMapId)
  .collection('nodes')
  .doc(nodeId)
  .get()
```

## Data Flow

1. **Create Mind Map**: Create mind map document and root node in a batch operation
2. **Add Node**: Create node document and update parent's `childIds` array
3. **Delete Node**:
   - If `deleteChildren = true`: Recursively delete all children
   - If `deleteChildren = false`: Re-parent children to deleted node's parent
   - Update parent's `childIds` array
4. **Update Node Position**: Batch update multiple nodes for drag operations
5. **Offline Sync**: Cache all mind maps and nodes in Hive for offline access

## Caching Strategy

- **Mind Maps**: Cached in Hive box with key = `mindMapId`
- **Nodes**: Cached in Hive box with key = `{mindMapId}_{nodeId}`
- **Stream Updates**: Automatically update cache when Firestore stream emits new data
- **Offline Mode**: Serve from cache, queue writes for sync when online
