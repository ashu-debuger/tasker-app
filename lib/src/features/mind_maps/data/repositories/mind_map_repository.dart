import '../../domain/models/mind_map.dart';

/// Repository interface for mind map operations
abstract class MindMapRepository {
  /// Get a mind map by ID
  Future<MindMap?> getMindMapById(String id);

  /// Stream mind maps for a user
  Stream<List<MindMap>> streamMindMapsForUser(String userId);

  /// Create a new mind map with root node
  Future<void> createMindMap(MindMap mindMap, MindMapNode rootNode);

  /// Update an existing mind map
  Future<void> updateMindMap(MindMap mindMap);

  /// Delete a mind map and all its nodes
  Future<void> deleteMindMap(String mindMapId);

  /// Get a node by ID
  Future<MindMapNode?> getNodeById(String mindMapId, String nodeId);

  /// Get all nodes for a mind map
  Future<List<MindMapNode>> getNodesForMindMap(String mindMapId);

  /// Stream nodes for a mind map
  Stream<List<MindMapNode>> streamNodesForMindMap(String mindMapId);

  /// Create a new node
  Future<void> createNode(MindMapNode node);

  /// Update an existing node
  Future<void> updateNode(MindMapNode node);

  /// Delete a node (and optionally its children)
  Future<void> deleteNode(
    String mindMapId,
    String nodeId, {
    bool deleteChildren = false,
  });

  /// Update multiple nodes (for batch operations like drag)
  Future<void> updateNodes(List<MindMapNode> nodes);

  /// Sync offline mind maps to Firestore
  Future<void> syncOfflineMindMaps();
}
