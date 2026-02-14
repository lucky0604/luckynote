import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../../../core/utils/file_utils.dart';
import '../../../../database/database.dart';
import 'chunk_service.dart';

/// 文档仓库服务
/// 用于 RAG 模块的文档和切片管理
class DocumentService {
  DocumentService(this._database);

  final AppDatabase _database;

  /// 计算文件内容的哈希值
  String _calculateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 索引文档到数据库
  ///
  /// [filePath] 文件路径
  /// [title] 文档标题
  /// [content] 文档完整内容
  /// [chunks] 切片列表
  /// [lastModified] 最后修改时间
  Future<void> indexDocument({
    required String filePath,
    required String title,
    required String content,
    required List<NoteChunk> chunks,
    DateTime? lastModified,
  }) async {
    final contentHash = _calculateHash(content);
    final modifiedTime = lastModified ?? DateTime.now();

    await _database.upsertDocument(
      filePath: filePath,
      title: title,
      lastModified: modifiedTime,
      contentHash: contentHash,
      chunks: chunks,
    );
  }

  /// 索引 Markdown 文件到数据库
  ///
  /// [filePath] Markdown 文件路径
  /// [chunkService] 可选的自定义切片服务
  Future<void> indexMarkdownFile(
    String filePath, {
    ChunkService? chunkService,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final content = await file.readAsString();
    final title = FileUtils.extractTitleFromContent(content);
    final stat = await file.stat();
    final contentHash = _calculateHash(content);

    // 检查是否需要重新索引
    if (!await needsReindex(filePath, content)) {
      return;
    }

    // 对内容进行切片
    final chunker = chunkService ?? ChunkService();
    final result = chunker.chunkMarkdown(content);

    // 使用数据库的 upsertDocumentWithChunks 方法
    await _database.upsertDocumentWithChunks(
      filePath: filePath,
      title: title,
      lastModified: stat.modified,
      contentHash: contentHash,
      chunkList: result.chunks,
    );
  }

  /// 搜索文档切片
  ///
  /// [query] 搜索关键词
  /// [limit] 返回结果数量限制
  Future<List<NoteChunkResult>> searchChunks(
    String query, {
    int limit = 10,
  }) async {
    return await _database.searchChunks(query, limit: limit);
  }

  /// 检查文档是否需要重新索引
  ///
  /// [filePath] 文件路径
  /// [content] 当前文件内容
  /// 返回 true 表示需要重新索引
  Future<bool> needsReindex(String filePath, String content) async {
    final currentHash = _calculateHash(content);

    final docs = await (_database.select(
      _database.noteDocuments,
    )..where((tbl) => tbl.filePath.equals(filePath))).get();

    if (docs.isEmpty) return true;

    return docs.first.contentHash != currentHash;
  }

  /// 删除文档索引
  Future<void> deleteDocument(String filePath) async {
    await (_database.delete(
      _database.noteDocuments,
    )..where((tbl) => tbl.filePath.equals(filePath))).go();
  }

  /// 获取或创建文档记录
  /// 用于 WikiLink 引用管理
  ///
  /// [filePath] 文件路径
  /// [title] 文档标题
  /// [lastModified] 最后修改时间
  /// 返回 NoteDocument 对象
  Future<NoteDocument> getOrCreateDocument(
    String filePath,
    String title,
    DateTime lastModified,
  ) async {
    // 尝试获取现有文档
    final existing = await (_database.select(
      _database.noteDocuments,
    )..where((tbl) => tbl.filePath.equals(filePath))).getSingleOrNull();

    if (existing != null) {
      return existing;
    }

    // 创建新文档记录（不包含 chunks，仅用于 WikiLink 引用）
    final contentHash = _calculateHash('');
    final docId = await _database.into(_database.noteDocuments).insert(
      NoteDocumentsCompanion.insert(
        filePath: filePath,
        title: title,
        lastModified: lastModified,
        contentHash: contentHash,
      ),
    );

    // 返回创建的文档
    return NoteDocument(
      id: docId,
      filePath: filePath,
      title: title,
      lastModified: lastModified,
      contentHash: contentHash,
    );
  }

  /// 根据文件路径获取文档
  Future<NoteDocument?> getDocumentByFilePath(String filePath) async {
    return await (_database.select(
      _database.noteDocuments,
    )..where((tbl) => tbl.filePath.equals(filePath))).getSingleOrNull();
  }
}
