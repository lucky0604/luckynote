/// Node type in the local graph
enum GraphNodeType {
  /// Center node - the currently viewed note
  center,

  /// Child node - notes referenced by the center note
  child,

  /// Parent node - notes that reference the center note
  parent,
}

/// Graph node representation
class GraphNode {
  const GraphNode({
    required this.id,
    required this.label,
    required this.type,
    this.filePath,
  });

  /// Unique identifier for the node (typically the note title)
  final String id;

  /// Display label for the node
  final String label;

  /// Type of node in the graph
  final GraphNodeType type;

  /// File path for navigation (null for placeholder nodes)
  final String? filePath;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GraphNode &&
        other.id == id &&
        other.label == label &&
        other.type == type &&
        other.filePath == filePath;
  }

  @override
  int get hashCode {
    return Object.hash(id, label, type, filePath);
  }

  @override
  String toString() {
    return 'GraphNode(id: $id, label: $label, type: $type, filePath: $filePath)';
  }
}

/// Graph edge representing a connection between two nodes
class GraphEdge {
  const GraphEdge({
    required this.sourceId,
    required this.targetId,
  });

  /// Source node ID
  final String sourceId;

  /// Target node ID
  final String targetId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GraphEdge &&
        other.sourceId == sourceId &&
        other.targetId == targetId;
  }

  @override
  int get hashCode {
    return Object.hash(sourceId, targetId);
  }

  @override
  String toString() {
    return 'GraphEdge(sourceId: $sourceId, targetId: $targetId)';
  }
}

/// Complete graph data for local note graph visualization
class GraphData {
  const GraphData({
    required this.nodes,
    required this.edges,
  });

  /// All nodes in the graph
  final List<GraphNode> nodes;

  /// All edges connecting the nodes
  final List<GraphEdge> edges;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GraphData &&
        other.nodes.length == nodes.length &&
        other.edges.length == edges.length;
  }

  @override
  int get hashCode {
    return Object.hash(nodes.length, edges.length);
  }

  @override
  String toString() {
    return 'GraphData(nodes: ${nodes.length}, edges: ${edges.length})';
  }
}
