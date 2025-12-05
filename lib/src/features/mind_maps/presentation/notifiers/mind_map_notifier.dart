import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/mind_map.dart';
import '../../data/repositories/mind_map_repository.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/app_logger.dart';

part 'mind_map_notifier.g.dart';

/// State class for mind map operations
@immutable
class MindMapState {
  final MindMap? mindMap;
  final List<MindMapNode> nodes;
  final String? selectedNodeId;
  final bool isLoading;
  final String? error;

  const MindMapState({
    this.mindMap,
    this.nodes = const [],
    this.selectedNodeId,
    this.isLoading = false,
    this.error,
  });

  MindMapState copyWith({
    MindMap? mindMap,
    List<MindMapNode>? nodes,
    String? selectedNodeId,
    bool? isLoading,
    String? error,
  }) {
    return MindMapState(
      mindMap: mindMap ?? this.mindMap,
      nodes: nodes ?? this.nodes,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing mind map state and operations
@riverpod
class MindMapNotifier extends _$MindMapNotifier {
  late MindMapRepository _repository;

  @override
  MindMapState build() {
    _repository = ref.watch(mindMapRepositoryProvider);
    return const MindMapState();
  }

  /// Load mind map and its nodes
  Future<void> loadMindMap(String mindMapId) async {
    appLogger.i('Loading mind map: $mindMapId');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final mindMap = await _repository.getMindMapById(mindMapId);

      if (!ref.mounted) {
        appLogger.w(
          'MindMapNotifier disposed during loadMindMap (after getMindMapById)',
        );
        return;
      }

      if (mindMap == null) {
        appLogger.w('Mind map not found: $mindMapId');
        state = state.copyWith(isLoading: false, error: 'Mind map not found');
        return;
      }

      final nodes = await _repository.getNodesForMindMap(mindMapId);

      if (!ref.mounted) {
        appLogger.w(
          'MindMapNotifier disposed during loadMindMap (after getNodesForMindMap)',
        );
        return;
      }

      state = state.copyWith(mindMap: mindMap, nodes: nodes, isLoading: false);
      appLogger.i('Mind map loaded successfully: ${nodes.length} nodes');
    } catch (e, stackTrace) {
      appLogger.e('Failed to load mind map', error: e, stackTrace: stackTrace);

      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load mind map: $e',
        );
      }
    }
  }

  /// Create a new mind map with root node
  Future<String?> createMindMap(
    String userId,
    String title,
    String rootText,
  ) async {
    appLogger.i('Creating mind map: title=$title, userId=$userId');

    try {
      final mindMapId = FirebaseFirestore.instance
          .collection('mindMaps')
          .doc()
          .id;
      final rootNodeId = FirebaseFirestore.instance
          .collection('nodes')
          .doc()
          .id;

      final mindMap = MindMap(
        id: mindMapId,
        title: title,
        userId: userId,
        rootNodeId: rootNodeId,
        createdAt: DateTime.now(),
      );

      final rootNode = MindMapNode(
        id: rootNodeId,
        mindMapId: mindMapId,
        text: rootText,
        x: 1800, // Center of 4000x4000 canvas
        y: 1900,
        color: NodeColor.blue,
        createdAt: DateTime.now(),
      );

      await _repository.createMindMap(mindMap, rootNode);

      // Check if ref is still mounted after async operation
      if (!ref.mounted) {
        appLogger.w(
          'MindMapNotifier disposed during createMindMap, skipping state update',
        );
        return mindMapId;
      }

      appLogger.i('Mind map created successfully: $mindMapId');
      return mindMapId;
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to create mind map',
        error: e,
        stackTrace: stackTrace,
      );

      // Check if ref is still mounted before updating state
      if (ref.mounted) {
        state = state.copyWith(error: 'Failed to create mind map: $e');
      }
      return null;
    }
  }

  /// Update mind map title or description
  Future<void> updateMindMap(MindMap mindMap) async {
    appLogger.i('Updating mind map: ${mindMap.id}');

    try {
      await _repository.updateMindMap(mindMap);

      if (!ref.mounted) {
        appLogger.w('MindMapNotifier disposed during updateMindMap');
        return;
      }

      state = state.copyWith(mindMap: mindMap);
      appLogger.i('Mind map updated successfully');
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to update mind map',
        error: e,
        stackTrace: stackTrace,
      );

      if (ref.mounted) {
        state = state.copyWith(error: 'Failed to update mind map: $e');
      }
    }
  }

  /// Delete mind map and all nodes
  Future<void> deleteMindMap(String mindMapId) async {
    appLogger.i('Deleting mind map: $mindMapId');

    try {
      await _repository.deleteMindMap(mindMapId);

      if (!ref.mounted) {
        appLogger.w('MindMapNotifier disposed during deleteMindMap');
        return;
      }

      state = const MindMapState();
      appLogger.i('Mind map deleted successfully');
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to delete mind map',
        error: e,
        stackTrace: stackTrace,
      );

      if (ref.mounted) {
        state = state.copyWith(error: 'Failed to delete mind map: $e');
      }
    }
  }

  /// Add a new child node
  Future<void> addNode({
    required String parentId,
    required String text,
    NodeColor color = NodeColor.yellow,
    NodeDirection direction = NodeDirection.right,
  }) async {
    if (state.mindMap == null) {
      appLogger.w('Cannot add node: no mind map loaded');
      return;
    }

    appLogger.i(
      'Adding node: parentId=$parentId, text=$text, direction=${direction.name}',
    );

    try {
      final parent = state.nodes.firstWhere((n) => n.id == parentId);

      // Calculate position relative to parent using direction
      final childCount = parent.childIds.length;
      final offset = direction.getOffset(
        spacing: 300.0,
        verticalSpread: 120.0,
        childIndex: childCount,
      );

      final nodeId = FirebaseFirestore.instance.collection('nodes').doc().id;
      final node = MindMapNode(
        id: nodeId,
        mindMapId: state.mindMap!.id,
        text: text,
        parentId: parentId,
        x: parent.x + offset.dx,
        y: parent.y + offset.dy,
        color: color,
        createdAt: DateTime.now(),
      );

      await _repository.createNode(node);

      if (!ref.mounted) {
        appLogger.w(
          'MindMapNotifier disposed during addNode (after createNode)',
        );
        return;
      }

      // Refresh nodes
      final updatedNodes = await _repository.getNodesForMindMap(
        state.mindMap!.id,
      );

      if (!ref.mounted) {
        appLogger.w(
          'MindMapNotifier disposed during addNode (after getNodesForMindMap)',
        );
        return;
      }

      state = state.copyWith(nodes: updatedNodes);
      appLogger.i('Node added successfully: $nodeId');
    } catch (e, stackTrace) {
      appLogger.e('Failed to add node', error: e, stackTrace: stackTrace);

      if (ref.mounted) {
        state = state.copyWith(error: 'Failed to add node: $e');
      }
    }
  }

  /// Update node text or properties
  Future<void> updateNode(MindMapNode node) async {
    appLogger.i('Updating node: ${node.id}');

    try {
      await _repository.updateNode(node);

      if (!ref.mounted) {
        appLogger.w('MindMapNotifier disposed during updateNode');
        return;
      }

      // Update local state
      final updatedNodes = state.nodes.map((n) {
        return n.id == node.id ? node : n;
      }).toList();

      state = state.copyWith(nodes: updatedNodes);
      appLogger.i('Node updated successfully');
    } catch (e, stackTrace) {
      appLogger.e('Failed to update node', error: e, stackTrace: stackTrace);

      if (ref.mounted) {
        state = state.copyWith(error: 'Failed to update node: $e');
      }
    }
  }

  /// Delete node (with cascade or re-parent option)
  Future<void> deleteNode(String nodeId, {bool deleteChildren = false}) async {
    if (state.mindMap == null) {
      appLogger.w('Cannot delete node: no mind map loaded');
      return;
    }

    appLogger.i('Deleting node: $nodeId (deleteChildren: $deleteChildren)');

    try {
      await _repository.deleteNode(
        state.mindMap!.id,
        nodeId,
        deleteChildren: deleteChildren,
      );

      if (!ref.mounted) {
        appLogger.w(
          'MindMapNotifier disposed during deleteNode (after deleteNode)',
        );
        return;
      }

      // Refresh nodes
      final updatedNodes = await _repository.getNodesForMindMap(
        state.mindMap!.id,
      );

      if (!ref.mounted) {
        appLogger.w(
          'MindMapNotifier disposed during deleteNode (after getNodesForMindMap)',
        );
        return;
      }

      state = state.copyWith(nodes: updatedNodes, selectedNodeId: null);
      appLogger.i('Node deleted successfully');
    } catch (e, stackTrace) {
      appLogger.e('Failed to delete node', error: e, stackTrace: stackTrace);

      if (ref.mounted) {
        state = state.copyWith(error: 'Failed to delete node: $e');
      }
    }
  }

  /// Update node position (for drag operations)
  Future<void> updateNodePosition(String nodeId, Offset position) async {
    final node = state.nodes.firstWhere((n) => n.id == nodeId);
    final updatedNode = node.copyWith(x: position.dx, y: position.dy);

    // Update local state immediately for smooth dragging
    final updatedNodes = state.nodes.map((n) {
      return n.id == nodeId ? updatedNode : n;
    }).toList();
    state = state.copyWith(nodes: updatedNodes);

    // Update in repository (async)
    try {
      await _repository.updateNode(updatedNode);

      if (!ref.mounted) {
        appLogger.w('MindMapNotifier disposed during updateNodePosition');
        return;
      }

      appLogger.d('Node position updated: $nodeId');
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to update position',
        error: e,
        stackTrace: stackTrace,
      );

      if (ref.mounted) {
        state = state.copyWith(error: 'Failed to update position: $e');
      }
    }
  }

  /// Toggle node collapse state
  Future<void> toggleCollapse(String nodeId) async {
    final node = state.nodes.firstWhere((n) => n.id == nodeId);
    final updatedNode = node.copyWith(isCollapsed: !node.isCollapsed);

    await updateNode(updatedNode);
  }

  /// Select a node
  void selectNode(String? nodeId) {
    state = state.copyWith(selectedNodeId: nodeId);
  }

  /// Get visible nodes (filtering collapsed children)
  List<MindMapNode> getVisibleNodes() {
    if (state.mindMap == null) return [];

    final visibleIds = <String>{};
    final nodeMap = {for (var node in state.nodes) node.id: node};

    // Start with root node
    final rootNode = state.nodes.firstWhere(
      (n) => n.id == state.mindMap!.rootNodeId,
    );

    void addVisibleDescendants(MindMapNode node) {
      visibleIds.add(node.id);

      // If collapsed, don't add children
      if (node.isCollapsed) return;

      // Add visible children recursively
      for (final childId in node.childIds) {
        final child = nodeMap[childId];
        if (child != null) {
          addVisibleDescendants(child);
        }
      }
    }

    addVisibleDescendants(rootNode);

    return state.nodes.where((n) => visibleIds.contains(n.id)).toList();
  }
}

/// Provider for streaming mind maps for a user
@riverpod
Stream<List<MindMap>> userMindMaps(Ref ref, String userId) {
  final repository = ref.watch(mindMapRepositoryProvider);
  return repository.streamMindMapsForUser(userId);
}
