import 'package:luckynote/database/database.dart';
import '../models/graph_node.dart';

/// Graph building service.
///
/// Builds local graph data showing connections between notes.
class GraphBuilder {
  GraphBuilder(this._database);

  final AppDatabase _database;

  /// Get local graph data for a note
  ///
  /// [noteTitle] Title of the center note
  /// Returns GraphData with nodes and edges
  Future<GraphData> getLocalGraphData(String noteTitle) async {
    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];

    // Add center node
    nodes.add(GraphNode(
      id: noteTitle,
      label: noteTitle,
      type: GraphNodeType.center,
    ));

    // Get document ID for the center note
    final centerDocs = await (_database.select(_database.noteDocuments)
          ..where((tbl) => tbl.title.equals(noteTitle))
          ..limit(1))
        .get();

    if (centerDocs.isEmpty) {
      return GraphData(nodes: nodes, edges: edges);
    }

    final centerDocId = centerDocs.first.id;

    // Find children (outgoing links from center note)
    final children = await (_database.select(_database.noteReferences)
          ..where((tbl) => tbl.sourceDocId.equals(centerDocId)))
        .get();

    final childNodeIds = <String>{};

    for (final child in children) {
      final targetTitle = child.targetTitle;
      childNodeIds.add(targetTitle);

      nodes.add(GraphNode(
        id: targetTitle,
        label: targetTitle,
        type: GraphNodeType.child,
      ));

      edges.add(GraphEdge(
        sourceId: noteTitle,
        targetId: targetTitle,
      ));
    }

    // Find parents (incoming links to center note)
    final parents = await (_database.select(_database.noteReferences)
          ..where((tbl) => tbl.targetTitle.equals(noteTitle)))
        .get();

    for (final parent in parents) {
      // Get parent document title
      final parentDocs = await (_database.select(_database.noteDocuments)
            ..where((tbl) => tbl.id.equals(parent.sourceDocId))
            ..limit(1))
          .get();

      if (parentDocs.isEmpty) continue;

      final parentTitle = parentDocs.first.title;

      // Skip if already added as child (self-reference or circular)
      if (childNodeIds.contains(parentTitle)) continue;

      nodes.add(GraphNode(
        id: parentTitle,
        label: parentTitle,
        type: GraphNodeType.parent,
      ));

      edges.add(GraphEdge(
        sourceId: parentTitle,
        targetId: noteTitle,
      ));
    }

    // Add file paths to nodes
    for (final node in nodes) {
      if (node.type == GraphNodeType.center) {
        nodes[nodes.indexOf(node)] = GraphNode(
          id: node.id,
          label: node.label,
          type: node.type,
          filePath: centerDocs.first.filePath,
        );
      } else {
        final docs = await (_database.select(_database.noteDocuments)
              ..where((tbl) => tbl.title.equals(node.label))
              ..limit(1))
            .get();

        if (docs.isNotEmpty) {
          nodes[nodes.indexOf(node)] = GraphNode(
            id: node.id,
            label: node.label,
            type: node.type,
            filePath: docs.first.filePath,
          );
        }
      }
    }

    return GraphData(nodes: nodes, edges: edges);
  }
}
