# 🧠 Mind Maps

Visual idea organization in Tasker.

---

## Overview

Mind Maps allow users to:
- 🎯 Create visual brainstorming diagrams
- 🔗 Connect related ideas
- 🎨 Color-code nodes
- ↔️ Arrange nodes in 4 directions
- 📱 Touch-friendly editing

---

## Features

### Node Creation
- Create root node
- Add child nodes in any direction
- Drag-and-drop positioning
- Double-tap to edit

### Visual Connections
- Curved connection lines
- Color-coded arrows
- Gradient effects
- Clear visual hierarchy

### 4-Direction Support
- Add nodes left, right, up, or down
- Flexible tree structures
- Non-traditional layouts

### Canvas Navigation
- Pan and zoom
- Pinch-to-zoom
- Separate node dragging from canvas panning

---

## Usage

### Navigate to Mind Maps
```dart
context.go('/mind-maps');
```

### Create New Mind Map
```dart
context.go('/mind-maps/editor');
```

---

## Data Model

```dart
class MindMap {
  final String id;
  final String name;
  final String? description;
  final List<MindMapNode> nodes;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

class MindMapNode {
  final String id;
  final String text;
  final double x;           // Position X
  final double y;           // Position Y
  final Color color;
  final String? parentId;   // Connection to parent
}
```

---

## Improvements Roadmap

### ✅ Completed
| Feature           | Description                   |
| ----------------- | ----------------------------- |
| Initial centering | Root node appears centered    |
| 4-direction nodes | Create nodes in any direction |
| Node dragging fix | Separate from canvas panning  |
| Arrow enhancement | Colored, gradient arrows      |

### 🚧 Planned
| Feature               | Priority |
| --------------------- | -------- |
| Auto-layout algorithm | Medium   |
| Zoom controls         | Low      |
| Undo/Redo             | Medium   |
| Export to image       | Medium   |
| Node icons            | Low      |
| Connection labels     | Low      |
| Search nodes          | Medium   |
| Minimap               | Low      |
| Keyboard shortcuts    | Medium   |

---

## Technical Details

### Canvas System
- Uses `InteractiveViewer` for pan/zoom
- Custom `CustomPainter` for connections
- `GestureDetector` for node interactions

### Node Positioning
- Absolute positioning on infinite canvas
- Nodes store their own x,y coordinates
- Auto-layout calculates optimal positions

---

## Related Docs

- [Tasks Guide](./tasks.md) - Link mind maps to tasks
- [Projects Guide](./projects.md) - Project mind maps

---

<div align="center">

**[← Back to Docs](../README.md)** | **[Features Index](../README.md#-features)**

</div>
