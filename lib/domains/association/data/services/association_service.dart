import 'package:luckynote/database/database.dart';
import 'package:luckynote/domains/rag/data/services/document_service.dart';
import '../models/mention_candidate.dart';
import '../models/graph_node.dart';
import 'title_cache.dart';
import 'mention_detector.dart';
import 'graph_builder.dart';

/// Association Service - facade for mention detection and graph building.
///
/// Coordinates unlinked mention detection and local graph data generation.
class AssociationService {
  AssociationService(this._database, [this._documentService])
      : _titleCache = TitleCache(_database),
        _graphBuilder = GraphBuilder(_database) {
    // 确保 MentionDetector 使用同一个 TitleCache 实例
    _mentionDetector = MentionDetector(
      database: _database,
      titleCache: _titleCache,
      documentService: _documentService,
    );
  }

  final AppDatabase _database;
  final DocumentService? _documentService;
  final TitleCache _titleCache;
  late final MentionDetector _mentionDetector;
  final GraphBuilder _graphBuilder;

  /// Get all note titles with caching
  Future<List<String>> getAllTitles() => _titleCache.getAllTitles();

  /// Invalidate title cache (call when notes are created/deleted/renamed)
  void invalidateCache() => _titleCache.invalidateCache();

  /// Find all note titles mentioned in content that aren't linked
  ///
  /// [content] The markdown content to scan
  /// [currentNotePath] Path of current note (to exclude self-mentions)
  /// [currentNoteTitle] Title of current note (preferred for self-mention exclusion)
  /// Returns list of mention candidates
  Future<List<MentionCandidate>> findUnlinkedMentions({
    required String content,
    required String currentNotePath,
    String? currentNoteTitle,
  }) =>
      _mentionDetector.findUnlinkedMentions(
        content: content,
        currentNotePath: currentNotePath,
        currentNoteTitle: currentNoteTitle,
      );

  /// Get local graph data for a note
  ///
  /// [noteTitle] Title of the center note
  /// Returns GraphData with nodes and edges
  Future<GraphData> getLocalGraphData(String noteTitle) =>
      _graphBuilder.getLocalGraphData(noteTitle);
}
