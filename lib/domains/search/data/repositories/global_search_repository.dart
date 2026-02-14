import 'package:luckynote/database/database.dart';

/// 搜索结果类型
enum SearchResultType { title, content }

/// 统一搜索结果
class UnifiedSearchResult {
  final int documentId;
  final String title;
  final String filePath;
  final String? matchedContent;
  final double? score;
  final SearchResultType type;

  UnifiedSearchResult({
    required this.documentId,
    required this.title,
    required this.filePath,
    this.matchedContent,
    this.score,
    required this.type,
  });

  @override
  String toString() {
    return 'UnifiedSearchResult(documentId: $documentId, title: $title, type: $type)';
  }
}

/// 全局搜索仓库
/// 结合文件名搜索和 FTS5 内容搜索
class GlobalSearchRepository {
  GlobalSearchRepository(this._database);

  final AppDatabase _database;

  /// 全局搜索 - 同时搜索标题和内容
  /// [query] 搜索关键词
  /// [limit] 返回结果数量限制
  /// 返回合并后的结果列表，标题匹配优先
  Future<List<UnifiedSearchResult>> search(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final results = <UnifiedSearchResult>[];
    final seenDocIds = <int>{};

    // 1. 搜索标题
    final titleResults = await _database.searchByTitle(query, limit: limit);
    for (final result in titleResults) {
      results.add(UnifiedSearchResult(
        documentId: result.documentId,
        title: result.title,
        filePath: result.filePath,
        type: SearchResultType.title,
      ));
      seenDocIds.add(result.documentId);
    }

    // 2. 搜索内容 (FTS5)
    final contentResults = await _database.searchChunks(query, limit: limit);
    for (final result in contentResults) {
      // 避免重复
      if (!seenDocIds.contains(result.documentId)) {
        results.add(UnifiedSearchResult(
          documentId: result.documentId,
          title: result.title,
          filePath: result.sourceFilePath,
          matchedContent: result.content,
          score: result.score,
          type: SearchResultType.content,
        ));
        seenDocIds.add(result.documentId);
      }
    }

    // 标题匹配优先，然后按内容相关性排序
    results.sort((a, b) {
      // 标题匹配优先
      if (a.type == SearchResultType.title && b.type == SearchResultType.content) {
        return -1;
      } else if (a.type == SearchResultType.content && b.type == SearchResultType.title) {
        return 1;
      }
      // 同类型按分数排序
      if (a.score != null && b.score != null) {
        return a.score!.compareTo(b.score!);
      }
      return 0;
    });

    return results.take(limit).toList();
  }
}
