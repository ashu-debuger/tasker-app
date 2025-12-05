import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/mind_map.dart';
import '../notifiers/mind_map_notifier.dart';
import '../widgets/mind_map_canvas.dart';

/// Full-screen mind map canvas with editing capabilities
class MindMapCanvasScreen extends ConsumerStatefulWidget {
  final String mindMapId;
  final String userId;

  const MindMapCanvasScreen({
    super.key,
    required this.mindMapId,
    required this.userId,
  });

  @override
  ConsumerState<MindMapCanvasScreen> createState() =>
      _MindMapCanvasScreenState();
}

class _MindMapCanvasScreenState extends ConsumerState<MindMapCanvasScreen> {
  String? _centeredMindMapId;
  int _focusRequestId = 0;

  @override
  void initState() {
    super.initState();
    // Load mind map on init
    Future.microtask(() {
      ref.read(mindMapProvider.notifier).loadMindMap(widget.mindMapId);
    });
  }

  void _triggerRecenter() {
    setState(() {
      _focusRequestId++;
    });
  }

  void _showAddNodeDialog(String parentId) {
    final textController = TextEditingController();
    NodeColor selectedColor = NodeColor.yellow;
    NodeDirection selectedDirection = NodeDirection.right;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Node'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Node Text',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Direction:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: NodeDirection.values.map((direction) {
                    return ChoiceChip(
                      label: Text(direction.displayName),
                      selected: selectedDirection == direction,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            selectedDirection = direction;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Color:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: NodeColor.values.map((color) {
                    return ChoiceChip(
                      label: Text(color.displayName),
                      selected: selectedColor == color,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            selectedColor = color;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  ref
                      .read(mindMapProvider.notifier)
                      .addNode(
                        parentId: parentId,
                        text: textController.text.trim(),
                        color: selectedColor,
                        direction: selectedDirection,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNodeDialog(MindMapNode node) {
    final textController = TextEditingController(text: node.text);
    NodeColor selectedColor = node.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Node'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Node Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Color:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: NodeColor.values.map((color) {
                  return ChoiceChip(
                    label: Text(color.displayName),
                    selected: selectedColor == color,
                    onSelected: (selected) {
                      if (selected) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  final updatedNode = node.copyWith(
                    text: textController.text.trim(),
                    color: selectedColor,
                  );
                  ref.read(mindMapProvider.notifier).updateNode(updatedNode);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteNodeDialog(MindMapNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Node'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "${node.text}"?'),
            if (node.childIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'This node has children. What would you like to do?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (node.childIds.isNotEmpty) ...[
            TextButton(
              onPressed: () {
                ref
                    .read(mindMapProvider.notifier)
                    .deleteNode(node.id, deleteChildren: false);
                Navigator.pop(context);
              },
              child: const Text('Keep Children'),
            ),
            FilledButton(
              onPressed: () {
                ref
                    .read(mindMapProvider.notifier)
                    .deleteNode(node.id, deleteChildren: true);
                Navigator.pop(context);
              },
              child: const Text('Delete All'),
            ),
          ] else
            FilledButton(
              onPressed: () {
                ref.read(mindMapProvider.notifier).deleteNode(node.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }

  void _showNodeActions(MindMapNode node) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Child Node'),
              onTap: () {
                Navigator.pop(context);
                _showAddNodeDialog(node.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Node'),
              onTap: () {
                Navigator.pop(context);
                _showEditNodeDialog(node);
              },
            ),
            if (node.childIds.isNotEmpty)
              ListTile(
                leading: Icon(
                  node.isCollapsed ? Icons.unfold_more : Icons.unfold_less,
                ),
                title: Text(node.isCollapsed ? 'Expand' : 'Collapse'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mindMapProvider.notifier).toggleCollapse(node.id);
                },
              ),
            if (!node.isRoot)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Node',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteNodeDialog(node);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mindMapProvider);

    if (state.mindMap != null &&
        state.nodes.isNotEmpty &&
        state.mindMap!.id != _centeredMindMapId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _centeredMindMapId = state.mindMap!.id;
          _focusRequestId++;
        });
      });
    }

    Offset? focusPoint;
    String? focusKey;
    if (state.mindMap != null && state.nodes.isNotEmpty) {
      final rootNode = state.nodes.firstWhere(
        (n) => n.id == state.mindMap!.rootNodeId,
        orElse: () => state.nodes.first,
      );
      focusPoint = Offset(rootNode.x + 100, rootNode.y + 50);
      focusKey = '${rootNode.id}_$_focusRequestId';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.mindMap?.title ?? 'Mind Map'),
        actions: [
          if (state.mindMap != null)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Show mind map settings (title, description, collaborators)
              },
              tooltip: 'Settings',
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(mindMapProvider.notifier)
                          .loadMindMap(widget.mindMapId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Canvas
                MindMapCanvas(
                  nodes: ref.read(mindMapProvider.notifier).getVisibleNodes(),
                  selectedNodeId: state.selectedNodeId,
                  onNodeTap: (nodeId) {
                    ref.read(mindMapProvider.notifier).selectNode(nodeId);
                  },
                  onNodeLongPress: (nodeId) {
                    final node = state.nodes.firstWhere((n) => n.id == nodeId);
                    _showNodeActions(node);
                  },
                  onNodeDrag: (nodeId, position) {
                    ref
                        .read(mindMapProvider.notifier)
                        .updateNodePosition(nodeId, position);
                  },
                  focusPoint: focusPoint,
                  focusNodeId: focusKey,
                  focusScale: 0.8,
                ),

                // Floating toolbar
                if (state.selectedNodeId != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                _showAddNodeDialog(state.selectedNodeId!);
                              },
                              tooltip: 'Add child',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                final node = state.nodes.firstWhere(
                                  (n) => n.id == state.selectedNodeId,
                                );
                                _showEditNodeDialog(node);
                              },
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                final node = state.nodes.firstWhere(
                                  (n) => n.id == state.selectedNodeId,
                                );
                                _showNodeActions(node);
                              },
                              tooltip: 'More actions',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (state.mindMap != null && state.nodes.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'center_map',
                          onPressed: _triggerRecenter,
                          tooltip: 'Center on root',
                          child: const Icon(Icons.center_focus_strong),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton(
                          heroTag: 'add_node_fab',
                          onPressed: () {
                            final targetNodeId =
                                state.selectedNodeId ??
                                state.mindMap!.rootNodeId;
                            _showAddNodeDialog(targetNodeId);
                          },
                          tooltip: 'Add node',
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
