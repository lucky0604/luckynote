import 'package:flutter/material.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/association/data/models/graph_node.dart';

/// Custom painter for graph visualization.
///
/// Draws nodes and edges for the local graph view.
class GraphPainter extends CustomPainter {
  const GraphPainter({
    required this.graphData,
    required this.nodePositions,
    this.selectedNode,
  });

  final GraphData graphData;
  final Map<String, Offset> nodePositions;
  final GraphNode? selectedNode;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw edges first (behind nodes)
    _drawEdges(canvas);

    // Draw nodes
    _drawNodes(canvas);
  }

  void _drawEdges(Canvas canvas) {
    final edgePaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in graphData.edges) {
      final sourcePos = nodePositions[edge.sourceId];
      final targetPos = nodePositions[edge.targetId];

      if (sourcePos != null && targetPos != null) {
        canvas.drawLine(sourcePos, targetPos, edgePaint);
      }
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in graphData.nodes) {
      final position = nodePositions[node.id];
      if (position == null) continue;

      final isSelected = selectedNode?.id == node.id;
      final color = _getNodeColor(node.type);
      final radius = isSelected ? 22.0 : 18.0;

      // Draw node circle
      final nodePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, radius, nodePaint);

      // Draw border for selected node
      if (isSelected) {
        final borderPaint = Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(position, radius + 2, borderPaint);
      }

      // Draw label
      _drawNodeLabel(canvas, node, position, radius);
    }
  }

  void _drawNodeLabel(Canvas canvas, GraphNode node, Offset position, double radius) {
    final textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 11,
      fontWeight: node.type == GraphNodeType.center ? FontWeight.w600 : FontWeight.w400,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: node.label, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: 80);

    // Position label below node
    final labelOffset = Offset(
      position.dx - textPainter.width / 2,
      position.dy + radius + 4,
    );

    // Draw background for readability
    final bgRect = Rect.fromLTWH(
      labelOffset.dx - 2,
      labelOffset.dy - 1,
      textPainter.width + 4,
      textPainter.height + 2,
    );

    final bgPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;

    canvas.drawRect(bgRect, bgPaint);
    textPainter.paint(canvas, labelOffset);
  }

  Color _getNodeColor(GraphNodeType type) {
    switch (type) {
      case GraphNodeType.center:
        return AppColors.accent;
      case GraphNodeType.child:
        return AppColors.linkColor;
      case GraphNodeType.parent:
        return AppColors.success;
    }
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) {
    return oldDelegate.graphData != graphData ||
        oldDelegate.selectedNode != selectedNode;
  }
}
