import 'package:flutter/material.dart';

import 'package:luckynote/domains/association/data/models/graph_node.dart';
import 'graph_layout.dart';
import 'graph_painter.dart';

/// Interactive graph canvas with gesture detection.
///
/// Handles tap gestures on nodes and renders the graph using CustomPaint.
class GraphCanvas extends StatefulWidget {
  const GraphCanvas({
    super.key,
    required this.graphData,
    required this.size,
    required this.onNodeTap,
    this.selectedNode,
  });

  final GraphData graphData;
  final Size size;
  final void Function(GraphNode) onNodeTap;
  final GraphNode? selectedNode;

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  Map<String, Offset>? _nodePositions;

  @override
  void initState() {
    super.initState();
    _calculatePositions();
  }

  @override
  void didUpdateWidget(GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graphData != widget.graphData) {
      _calculatePositions();
    }
  }

  void _calculatePositions() {
    setState(() {
      _nodePositions = GraphLayout.calculatePositions(
        nodes: widget.graphData.nodes,
        canvasSize: widget.size,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_nodePositions == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTapDown: (details) {
        // Check if tapped on a node
        final tappedNode = GraphLayout.findNodeAtPosition(
          position: details.localPosition,
          nodes: widget.graphData.nodes,
          nodePositions: _nodePositions!,
        );
        if (tappedNode != null) {
          widget.onNodeTap(tappedNode);
        }
      },
      child: CustomPaint(
        size: widget.size,
        painter: GraphPainter(
          graphData: widget.graphData,
          nodePositions: _nodePositions!,
          selectedNode: widget.selectedNode,
        ),
      ),
    );
  }
}
