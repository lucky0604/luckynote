import 'package:luckynote/database/database.dart';

/// RAG 统计信息
class RAGStats {
  const RAGStats({
    required this.documentCount,
    required this.chunkCount,
  });

  /// 已索引文档数
  final int documentCount;

  /// 总切片数
  final int chunkCount;
}

/// RAG 数据仓库
/// 封装 RAG 相关的数据库操作
class RAGRepository {
  RAGRepository(this._database);

  final AppDatabase _database;

  /// 搜索切片
  ///
  /// [query] 搜索查询
  /// [limit] 返回结果数量限制
  Future<List<NoteChunkResult>> search(
    String query, {
    int limit = 10,
  }) async {
    return await _database.searchChunks(query, limit: limit);
  }

  /// 根据 ID 获取切片
  Future<NoteChunk?> getChunk(int id) async {
    return await (_database.select(_database.noteChunks)
      ..where((c) => c.id.equals(id)))
      .getSingleOrNull();
  }

  /// 获取文档的所有切片
  Future<List<NoteChunk>> getDocumentChunks(int documentId) async {
    return await (_database.select(_database.noteChunks)
      ..where((c) => c.documentId.equals(documentId)))
      .get();
  }

  /// 获取索引统计信息
  Future<RAGStats> getStats() async {
    final docCount = await (_database.select(_database.noteDocuments))
      .get()
      .then((list) => list.length);

    final chunkCount = await (_database.select(_database.noteChunks))
      .get()
      .then((list) => list.length);

    return RAGStats(
      documentCount: docCount,
      chunkCount: chunkCount,
    );
  }

  /// 重建 FTS5 索引
  Future<void> rebuildIndex() async {
    await _database.rebuildFTSIndex();
  }
}
