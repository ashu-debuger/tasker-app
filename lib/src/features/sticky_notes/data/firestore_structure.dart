/// Firestore Structure Documentation for Sticky Notes
///
/// This file documents the Firestore collection structure for the sticky notes feature.
/// It is not executable code but serves as reference documentation.
///
/// Collection Path: users/{userId}/sticky_notes/{noteId}
///
/// Document Structure:
/// {
///   "id": String,                  // Unique note identifier (same as document ID)
///   "title": String?,              // Optional note title
///   "content": String,             // Note content (encrypted)
///   "color": String,               // Color preset: 'yellow', 'pink', 'blue', 'green', 'purple', 'orange'
///   "position": {                  // Position on canvas
///     "x": double,                 // X coordinate
///     "y": double                  // Y coordinate
///   },
///   "userId": String,              // Owner user ID (for query optimization)
///   "createdAt": Timestamp,        // Creation timestamp
///   "updatedAt": Timestamp?,       // Last update timestamp
///   "zIndex": int,                 // Z-index for layering (default: 0)
///   "width": double,               // Note width in pixels (default: 200.0)
///   "height": double               // Note height in pixels (default: 200.0)
/// }
///
/// Indexes:
/// - Composite index: userId ASC, zIndex ASC (for ordered retrieval)
/// - Single field: userId (already indexed via query)
///
/// Security Rules (Firestore):
/// ```
/// match /users/{userId}/sticky_notes/{noteId} {
///   // Users can only read/write their own notes
///   allow read, write: if request.auth != null && request.auth.uid == userId;
///
///   // Validate document structure on create/update
///   allow create: if request.resource.data.keys().hasAll(['id', 'content', 'color', 'position', 'userId', 'createdAt'])
///                 && request.resource.data.userId == userId
///                 && request.resource.data.id == noteId;
///
///   allow update: if request.resource.data.userId == userId
///                 && request.resource.data.updatedAt is timestamp;
/// }
/// ```
///
/// Query Examples:
///
/// 1. Get all notes for a user (ordered by z-index):
///    ```dart
///    firestore.collection('users/$userId/sticky_notes')
///      .orderBy('zIndex')
///      .snapshots();
///    ```
///
/// 2. Get a specific note:
///    ```dart
///    firestore.collection('users/$userId/sticky_notes')
///      .doc(noteId)
///      .get();
///    ```
///
/// 3. Batch update multiple notes (e.g., position changes):
///    ```dart
///    final batch = firestore.batch();
///    for (final note in notes) {
///      batch.update(
///        firestore.collection('users/${note.userId}/sticky_notes').doc(note.id),
///        note.toJson()
///      );
///    }
///    await batch.commit();
///    ```
///
/// Notes:
/// - Content is encrypted using EncryptionService before storage
/// - Offline-first architecture: changes are cached in Hive and synced when online
/// - User-scoped subcollection ensures data isolation and efficient querying
/// - Z-index allows layering control (higher values appear on top)
/// - Position uses canvas coordinates (0,0 is top-left)
library;
