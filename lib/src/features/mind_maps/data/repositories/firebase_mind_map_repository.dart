import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../domain/models/mind_map.dart';
import '../../../../core/utils/app_logger.dart';
import 'mind_map_repository.dart';

/// Firebase implementation of MindMapRepository with offline-first caching
class FirebaseMindMapRepository implements MindMapRepository {
  final FirebaseFirestore _firestore;
  final Box<dynamic> _mindMapBox;
  final Box<dynamic> _nodeBox;

  FirebaseMindMapRepository({
    required FirebaseFirestore firestore,
    required Box<dynamic> mindMapBox,
    required Box<dynamic> nodeBox,
  }) : _firestore = firestore,
       _mindMapBox = mindMapBox,
       _nodeBox = nodeBox;

  CollectionReference get _mindMapsCollection =>
      _firestore.collection('mindMaps');

  CollectionReference _nodesCollection(String mindMapId) =>
      _mindMapsCollection.doc(mindMapId).collection('nodes');

  @override
  Future<MindMap?> getMindMapById(String id) async {
    // Check cache first
    if (_mindMapBox.containsKey(id)) {
      return _mindMapBox.get(id);
    }

    // Fetch from Firestore
    final doc = await _mindMapsCollection.doc(id).get();
    if (!doc.exists) return null;

    final mindMap = MindMap.fromJson(doc.data() as Map<String, dynamic>);

    // Cache for offline access
    await _mindMapBox.put(id, mindMap);

    return mindMap;
  }

  @override
  Stream<List<MindMap>> streamMindMapsForUser(String userId) {
    return _mindMapsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final mindMaps = snapshot.docs
              .map(
                (doc) => MindMap.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();

          // Cache all mind maps
          for (final mindMap in mindMaps) {
            _mindMapBox.put(mindMap.id, mindMap);
          }

          return mindMaps;
        });
  }

  @override
  Future<void> createMindMap(MindMap mindMap, MindMapNode rootNode) async {
    appLogger.i(
      'Creating mind map in Firestore: id=${mindMap.id}, userId=${mindMap.userId}',
    );

    try {
      // CRITICAL: Check current Firebase Auth user
      final currentUser = FirebaseAuth.instance.currentUser;
      appLogger.i(
        'Firebase Auth currentUser: uid=${currentUser?.uid}, email=${currentUser?.email}',
      );

      if (currentUser == null) {
        appLogger.e('PERMISSION ERROR: Firebase Auth currentUser is NULL!');
        throw Exception('User not authenticated. Please sign in again.');
      }

      if (currentUser.uid != mindMap.userId) {
        appLogger.e(
          'PERMISSION ERROR: Auth UID mismatch! currentUser.uid=${currentUser.uid} != mindMap.userId=${mindMap.userId}',
        );
        throw Exception('User ID mismatch. Please sign in again.');
      }

      final mindMapData = mindMap.toJson();
      final rootNodeData = rootNode.toJson();

      appLogger.d('Mind map data: $mindMapData');
      appLogger.d('Root node data: $rootNodeData');

      // Create mind map document first (not in batch) to ensure it exists
      await _mindMapsCollection.doc(mindMap.id).set(mindMapData);
      appLogger.i('Mind map document created');

      // Then create root node (now parent document exists for security rules)
      await _nodesCollection(mindMap.id).doc(rootNode.id).set(rootNodeData);
      appLogger.i('Root node created');

      // Cache offline
      await _mindMapBox.put(mindMap.id, mindMap);
      await _nodeBox.put('${mindMap.id}_${rootNode.id}', rootNode);
      appLogger.i('Mind map cached offline');
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to create mind map in Firestore',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateMindMap(MindMap mindMap) async {
    final updatedMindMap = mindMap.copyWith(updatedAt: DateTime.now());

    await _mindMapsCollection.doc(mindMap.id).update(updatedMindMap.toJson());

    // Update cache
    await _mindMapBox.put(mindMap.id, updatedMindMap);
  }

  @override
  Future<void> deleteMindMap(String mindMapId) async {
    // Delete mind map document
    await _mindMapsCollection.doc(mindMapId).delete();

    // Delete all nodes (Firestore will handle subcollection deletion in production with Cloud Functions)
    final nodesSnapshot = await _nodesCollection(mindMapId).get();
    final batch = _firestore.batch();
    for (final doc in nodesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Remove from cache
    await _mindMapBox.delete(mindMapId);

    // Remove all cached nodes for this mind map
    final nodeKeys = _nodeBox.keys
        .where((key) => key.toString().startsWith('${mindMapId}_'))
        .toList();
    await _nodeBox.deleteAll(nodeKeys);
  }

  @override
  Future<MindMapNode?> getNodeById(String mindMapId, String nodeId) async {
    final cacheKey = '${mindMapId}_$nodeId';

    // Check cache first
    if (_nodeBox.containsKey(cacheKey)) {
      return _nodeBox.get(cacheKey);
    }

    // Fetch from Firestore
    final doc = await _nodesCollection(mindMapId).doc(nodeId).get();
    if (!doc.exists) return null;

    final node = MindMapNode.fromJson(doc.data() as Map<String, dynamic>);

    // Cache for offline access
    await _nodeBox.put(cacheKey, node);

    return node;
  }

  @override
  Future<List<MindMapNode>> getNodesForMindMap(String mindMapId) async {
    final snapshot = await _nodesCollection(mindMapId).get();

    final nodes = snapshot.docs
        .map((doc) => MindMapNode.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    // Cache all nodes
    for (final node in nodes) {
      await _nodeBox.put('${mindMapId}_${node.id}', node);
    }

    return nodes;
  }

  @override
  Stream<List<MindMapNode>> streamNodesForMindMap(String mindMapId) {
    return _nodesCollection(mindMapId).orderBy('createdAt').snapshots().map((
      snapshot,
    ) {
      final nodes = snapshot.docs
          .map(
            (doc) => MindMapNode.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      // Cache all nodes
      for (final node in nodes) {
        _nodeBox.put('${mindMapId}_${node.id}', node);
      }

      return nodes;
    });
  }

  @override
  Future<void> createNode(MindMapNode node) async {
    await _nodesCollection(node.mindMapId).doc(node.id).set(node.toJson());

    // Update parent's childIds if this node has a parent
    if (node.parentId != null) {
      final parent = await getNodeById(node.mindMapId, node.parentId!);
      if (parent != null && !parent.childIds.contains(node.id)) {
        final updatedParent = parent.copyWith(
          childIds: [...parent.childIds, node.id],
          updatedAt: DateTime.now(),
        );
        await updateNode(updatedParent);
      }
    }

    // Cache offline
    await _nodeBox.put('${node.mindMapId}_${node.id}', node);
  }

  @override
  Future<void> updateNode(MindMapNode node) async {
    final updatedNode = node.copyWith(updatedAt: DateTime.now());

    await _nodesCollection(
      node.mindMapId,
    ).doc(node.id).update(updatedNode.toJson());

    // Update cache
    await _nodeBox.put('${node.mindMapId}_${node.id}', updatedNode);
  }

  @override
  Future<void> deleteNode(
    String mindMapId,
    String nodeId, {
    bool deleteChildren = false,
  }) async {
    final node = await getNodeById(mindMapId, nodeId);
    if (node == null) return;

    if (deleteChildren && node.childIds.isNotEmpty) {
      // Recursively delete children
      for (final childId in node.childIds) {
        await deleteNode(mindMapId, childId, deleteChildren: true);
      }
    } else if (node.childIds.isNotEmpty) {
      // Re-parent children to this node's parent
      for (final childId in node.childIds) {
        final child = await getNodeById(mindMapId, childId);
        if (child != null) {
          final updatedChild = child.copyWith(parentId: node.parentId);
          await updateNode(updatedChild);
        }
      }
    }

    // Remove this node from parent's childIds
    if (node.parentId != null) {
      final parent = await getNodeById(mindMapId, node.parentId!);
      if (parent != null) {
        final updatedParent = parent.copyWith(
          childIds: parent.childIds.where((id) => id != nodeId).toList(),
          updatedAt: DateTime.now(),
        );
        await updateNode(updatedParent);
      }
    }

    // Delete the node
    await _nodesCollection(mindMapId).doc(nodeId).delete();

    // Remove from cache
    await _nodeBox.delete('${mindMapId}_$nodeId');
  }

  @override
  Future<void> updateNodes(List<MindMapNode> nodes) async {
    final batch = _firestore.batch();

    for (final node in nodes) {
      final updatedNode = node.copyWith(updatedAt: DateTime.now());
      batch.update(
        _nodesCollection(node.mindMapId).doc(node.id),
        updatedNode.toJson(),
      );

      // Update cache
      await _nodeBox.put('${node.mindMapId}_${node.id}', updatedNode);
    }

    await batch.commit();
  }

  @override
  Future<void> syncOfflineMindMaps() async {
    // Sync cached mind maps to Firestore
    final mindMaps = _mindMapBox.values.toList();

    for (final mindMap in mindMaps) {
      try {
        await _mindMapsCollection.doc(mindMap.id).set(mindMap.toJson());
      } catch (e) {
        appLogger.e('Error syncing mind map ${mindMap.id}', error: e);
      }
    }

    // Sync cached nodes to Firestore
    final nodes = _nodeBox.values.toList();

    for (final node in nodes) {
      try {
        await _nodesCollection(node.mindMapId).doc(node.id).set(node.toJson());
      } catch (e) {
        appLogger.e('Error syncing node ${node.id}', error: e);
      }
    }
  }
}
