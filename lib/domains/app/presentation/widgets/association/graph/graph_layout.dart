import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:luckynote/domains/association/data/models/graph_node.dart';

/// Calculates node positions for graph visualization.
///
/// Uses a circular layout with the center node in the middle
/// and other nodes arranged in a circle around it.
class GraphLayout {
  /// Calculate positions for all nodes in the graph.
  ///
  /// Returns a map of node IDs to their calculated positions.
  static Map<String, Offset> calculatePositions({
    required List<GraphNode> nodes,
    required Size canvasSize,
  }) {
    final Map<String, Offset> positions = {};
    if (nodes.isEmpty) return positions;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = math.min(canvasSize.width, canvasSize.height) * 0.35;

    // Find center node
    final centerNode = nodes.firstWhere(
      (n) => n.type == GraphNodeType.center,
      orElse: () => nodes.first,
    );

    // Place center node at center
    positions[centerNode.id] = center;

    // Calculate positions for other nodes in a circle
    final otherNodes = nodes.where((n) => n.id != centerNode.id).toList();
    final angleStep = (2 * math.pi) / (otherNodes.isNotEmpty ? otherNodes.length : 1);

    for (int i = 0; i < otherNodes.length; i++) {
      final node = otherNodes[i];
      final angle = i * angleStep - math.pi / 2; // Start from top
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      positions[node.id] = Offset(x, y);
    }

    return positions;
  }

  /// Find a node at the given position.
  ///
  /// Returns the node if the position is within the node's radius,
  /// otherwise returns null.
  static GraphNode? findNodeAtPosition({
    required Offset position,
    required List<GraphNode> nodes,
    required Map<String, Offset> nodePositions,
    double nodeRadius = 24.0,
  }) {
    for (final node in nodes) {
      final nodePos = nodePositions[node.id];
      if (nodePos != null) {
        final distance = (position - nodePos).distance;
        if (distance <= nodeRadius) {
          return node;
        }
      }
    }
    return null;
  }
}
