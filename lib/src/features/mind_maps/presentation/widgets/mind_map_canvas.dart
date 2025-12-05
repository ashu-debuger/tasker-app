import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/mind_map.dart';

/// Custom painter for rendering mind map nodes and connections
class MindMapPainter extends CustomPainter {
  final List<MindMapNode> nodes;
  final String? selectedNodeId;
  final VoidCallback? onRepaint;

  MindMapPainter({required this.nodes, this.selectedNodeId, this.onRepaint});

  @override
  void paint(Canvas canvas, Size size) {
    // Build node lookup map for efficient parent-child traversal
    final nodeMap = {for (var node in nodes) node.id: node};

    // First pass: Draw connection lines (behind nodes)
    for (final node in nodes) {
      if (node.parentId != null) {
        final parent = nodeMap[node.parentId];
        if (parent != null) {
          _drawConnection(canvas, parent, node);
        }
      }
    }

    // Second pass: Draw nodes (on top of connections)
    for (final node in nodes) {
      _drawNode(canvas, node, node.id == selectedNodeId);
    }
  }

  /// Draw connection line from parent to child node
  void _drawConnection(Canvas canvas, MindMapNode parent, MindMapNode child) {
    // Use child node color for connection (makes it easier to trace branches)
    final connectionColor = _getNodeColor(child.color).withValues(alpha: 0.6);

    final paint = Paint()
      ..color = connectionColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Calculate center points of nodes
    final parentCenter = Offset(
      parent.x + 100,
      parent.y + 50,
    ); // Node size: 200x100
    final childCenter = Offset(child.x + 100, child.y + 50);

    // Draw curved bezier line for organic feel
    final path = Path();
    path.moveTo(parentCenter.dx, parentCenter.dy);

    // Calculate control points for smooth curve
    final dx = childCenter.dx - parentCenter.dx;
    final controlPoint1 = Offset(parentCenter.dx + dx * 0.5, parentCenter.dy);
    final controlPoint2 = Offset(childCenter.dx - dx * 0.5, childCenter.dy);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      childCenter.dx,
      childCenter.dy,
    );

    canvas.drawPath(path, paint);

    // Draw arrowhead at child node end
    _drawArrowhead(canvas, controlPoint2, childCenter, connectionColor);
  }

  /// Draw arrowhead pointing from 'from' to 'to' position
  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Color color) {
    const arrowSize = 12.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Calculate angle of the line
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);

    // Calculate arrowhead points
    final tipPoint = to;
    final leftPoint = Offset(
      to.dx - arrowSize * math.cos(angle) + arrowSize * 0.5 * math.sin(angle),
      to.dy - arrowSize * math.sin(angle) - arrowSize * 0.5 * math.cos(angle),
    );
    final rightPoint = Offset(
      to.dx - arrowSize * math.cos(angle) - arrowSize * 0.5 * math.sin(angle),
      to.dy - arrowSize * math.sin(angle) + arrowSize * 0.5 * math.cos(angle),
    );

    // Draw filled triangle
    final arrowPath = Path()
      ..moveTo(tipPoint.dx, tipPoint.dy)
      ..lineTo(leftPoint.dx, leftPoint.dy)
      ..lineTo(rightPoint.dx, rightPoint.dy)
      ..close();

    canvas.drawPath(arrowPath, paint);
  }

  /// Draw individual node with rounded rectangle and text
  void _drawNode(Canvas canvas, MindMapNode node, bool isSelected) {
    const nodeWidth = 200.0;
    const nodeHeight = 100.0;
    final rect = Rect.fromLTWH(node.x, node.y, nodeWidth, nodeHeight);

    // Get color from enum
    final color = _getNodeColor(node.color);

    // Draw shadow for depth
    if (!isSelected) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(2, 2)),
          const Radius.circular(12),
        ),
        shadowPaint,
      );
    }

    // Draw node background
    final backgroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      backgroundPaint,
    );

    // Draw border (thicker if selected)
    final borderPaint = Paint()
      ..color = isSelected ? Colors.blue : Colors.grey.shade300
      ..strokeWidth = isSelected ? 3.0 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );

    // Draw text
    final textSpan = TextSpan(
      text: node.text,
      style: TextStyle(
        color: Colors.grey.shade900,
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 4,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: nodeWidth - 16);

    // Center text vertically and horizontally
    final textX = node.x + (nodeWidth - textPainter.width) / 2;
    final textY = node.y + (nodeHeight - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(textX, textY));

    // Draw collapse indicator if node has children
    if (node.childIds.isNotEmpty) {
      _drawCollapseIndicator(canvas, node, rect);
    }
  }

  /// Draw collapse/expand indicator for nodes with children
  void _drawCollapseIndicator(Canvas canvas, MindMapNode node, Rect rect) {
    const indicatorSize = 20.0;
    final indicatorRect = Rect.fromLTWH(
      rect.right - indicatorSize - 8,
      rect.bottom - indicatorSize - 8,
      indicatorSize,
      indicatorSize,
    );

    // Draw circle background
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(indicatorRect.center, indicatorSize / 2, circlePaint);

    // Draw circle border
    final borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(indicatorRect.center, indicatorSize / 2, borderPaint);

    // Draw +/- icon
    final iconPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final center = indicatorRect.center;
    final iconSize = 8.0;

    // Horizontal line (always)
    canvas.drawLine(
      Offset(center.dx - iconSize / 2, center.dy),
      Offset(center.dx + iconSize / 2, center.dy),
      iconPaint,
    );

    // Vertical line (only if collapsed)
    if (node.isCollapsed) {
      canvas.drawLine(
        Offset(center.dx, center.dy - iconSize / 2),
        Offset(center.dx, center.dy + iconSize / 2),
        iconPaint,
      );
    }
  }

  /// Get Material color from NodeColor enum
  Color _getNodeColor(NodeColor color) {
    switch (color) {
      case NodeColor.blue:
        return Colors.blue.shade100;
      case NodeColor.green:
        return Colors.green.shade100;
      case NodeColor.yellow:
        return Colors.yellow.shade100;
      case NodeColor.orange:
        return Colors.orange.shade100;
      case NodeColor.red:
        return Colors.red.shade100;
      case NodeColor.purple:
        return Colors.purple.shade100;
      case NodeColor.pink:
        return Colors.pink.shade100;
      case NodeColor.gray:
        return Colors.grey.shade200;
    }
  }

  @override
  bool shouldRepaint(MindMapPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.selectedNodeId != selectedNodeId;
  }
}

/// Interactive mind map canvas widget with pan and zoom
class MindMapCanvas extends StatefulWidget {
  final List<MindMapNode> nodes;
  final String? selectedNodeId;
  final Function(String nodeId)? onNodeTap;
  final Function(String nodeId)? onNodeLongPress;
  final Function(String nodeId, Offset position)? onNodeDrag;
  final Offset? focusPoint;
  final double focusScale;
  final String? focusNodeId;

  const MindMapCanvas({
    super.key,
    required this.nodes,
    this.selectedNodeId,
    this.onNodeTap,
    this.onNodeLongPress,
    this.onNodeDrag,
    this.focusPoint,
    this.focusScale = 1.0,
    this.focusNodeId,
  });

  @override
  State<MindMapCanvas> createState() => _MindMapCanvasState();
}

class _MindMapCanvasState extends State<MindMapCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  String? _draggingNodeId;
  Offset _dragStartOffset = Offset.zero;
  Size? _viewportSize;
  String? _appliedFocusKey;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MindMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNodeId != oldWidget.focusNodeId) {
      _appliedFocusKey = null;
    }
    _scheduleInitialFocus();
  }

  void _scheduleInitialFocus() {
    if (widget.focusPoint == null || _viewportSize == null) {
      return;
    }
    final focusKey =
        widget.focusNodeId ??
        '${widget.focusPoint!.dx.toStringAsFixed(2)}_${widget.focusPoint!.dy.toStringAsFixed(2)}';
    if (_appliedFocusKey == focusKey) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.focusPoint == null || _viewportSize == null) {
        return;
      }
      final focus = widget.focusPoint!;
      final size = _viewportSize!;

      // The focusPoint already represents the center of the node (x + 100, y + 50)
      // So we center it properly in the viewport
      final nodeCenter = focus;

      // Calculate translation to center the node, accounting for scale
      final scale = widget.focusScale;
      final translateX = size.width / 2 - (nodeCenter.dx * scale);
      final translateY = size.height / 2 - (nodeCenter.dy * scale);

      _transformationController.value = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(scale, scale, 1.0);

      _appliedFocusKey = focusKey;
    });
  }

  /// Find node at given canvas position
  MindMapNode? _findNodeAtPosition(Offset position) {
    // Convert screen position to canvas position
    final transform = _transformationController.value;
    final canvasPosition = MatrixUtils.transformPoint(
      Matrix4.inverted(transform),
      position,
    );

    // Check each node (reverse order for top-to-bottom hit testing)
    for (final node in widget.nodes.reversed) {
      const nodeWidth = 200.0;
      const nodeHeight = 100.0;
      final rect = Rect.fromLTWH(node.x, node.y, nodeWidth, nodeHeight);

      if (rect.contains(canvasPosition)) {
        return node;
      }
    }

    return null;
  }

  void _handleTapDown(TapDownDetails details) {
    final node = _findNodeAtPosition(details.localPosition);
    if (node != null) {
      widget.onNodeTap?.call(node.id);
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    final node = _findNodeAtPosition(details.localPosition);
    if (node != null) {
      widget.onNodeLongPress?.call(node.id);
    }
  }

  void _handlePanStart(ScaleStartDetails details) {
    final node = _findNodeAtPosition(details.localFocalPoint);
    if (node != null) {
      setState(() {
        _draggingNodeId = node.id;
        _dragStartOffset = Offset(node.x, node.y);
      });
      // Return true to indicate we're handling this gesture
    }
  }

  void _handlePanUpdate(ScaleUpdateDetails details) {
    if (_draggingNodeId != null) {
      // Convert delta to canvas space
      final transform = _transformationController.value;
      final scale = transform.getMaxScaleOnAxis();
      final canvasDelta = details.focalPointDelta / scale;

      final newPosition = _dragStartOffset + canvasDelta;
      widget.onNodeDrag?.call(_draggingNodeId!, newPosition);

      setState(() {
        _dragStartOffset = newPosition;
      });
    }
  }

  void _handlePanEnd(ScaleEndDetails details) {
    if (_draggingNodeId != null) {
      setState(() {
        _draggingNodeId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        _scheduleInitialFocus();

        return GestureDetector(
          onTapDown: _handleTapDown,
          onLongPressStart: _handleLongPressStart,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.1,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(2000),
            constrained: false,
            // Disable InteractiveViewer panning when dragging a node
            panEnabled: _draggingNodeId == null,
            scaleEnabled: _draggingNodeId == null,
            onInteractionStart: _handlePanStart,
            onInteractionUpdate: _handlePanUpdate,
            onInteractionEnd: _handlePanEnd,
            child: CustomPaint(
              size: const Size(4000, 4000), // Large canvas for mind map
              painter: MindMapPainter(
                nodes: widget.nodes,
                selectedNodeId: widget.selectedNodeId,
              ),
            ),
          ),
        );
      },
    );
  }
}
