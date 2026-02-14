part of 'database.dart';

extension AppDatabaseFts on AppDatabase {
  Future<void> upsertDocument({
    required String filePath,
    required String title,
    required DateTime lastModified,
    required String contentHash,
    required List<NoteChunk> chunks,
  }) async {
    return transaction(() async {
      final existingDoc = await (select(
        noteDocuments,
      )..where((tbl) => tbl.filePath.equals(filePath))).getSingleOrNull();

      int docId;
      if (existingDoc != null) {
        // 删除旧的 FTS5 索引
        await _deleteFTSForDocument(existingDoc.id);
        // 删除旧的 chunks
        await (delete(noteChunks)..where((tbl) => tbl.documentId.equals(existingDoc.id))).go();
        // 更新文档
        await (update(noteDocuments)..where((tbl) => tbl.id.equals(existingDoc.id))).write(
          NoteDocumentsCompanion(
            title: Value(title),
            lastModified: Value(lastModified),
            contentHash: Value(contentHash),
          ),
        );
        docId = existingDoc.id;
      } else {
        docId = await into(noteDocuments).insert(
          NoteDocumentsCompanion.insert(
            filePath: filePath,
            title: title,
            lastModified: lastModified,
            contentHash: contentHash,
          ),
        );
      }

      // Insert chunks and sync to FTS5
      for (final chunk in chunks) {
        final heading = chunk.heading ?? '';
        final chunkId = await into(noteChunks).insert(
          NoteChunksCompanion.insert(
            documentId: docId,
            heading: Value(heading),
            content: chunk.content,
            priority: Value(chunk.priority),
          ),
        );
        // 同步到 FTS5 索引表
        await _insertFTSEntry(chunkId, title, heading, chunk.content);
      }
    });
  }

  /// 使用 Chunk 对象列表进行文档索引
  Future<void> upsertDocumentWithChunks({
    required String filePath,
    required String title,
    required DateTime lastModified,
    required String contentHash,
    required List<dynamic> chunkList,
  }) async {
    return transaction(() async {
      final existingDoc = await (select(
        noteDocuments,
      )..where((tbl) => tbl.filePath.equals(filePath))).getSingleOrNull();

      int docId;
      if (existingDoc != null) {
        // 先删除旧的 FTS5 索引
        await _deleteFTSForDocument(existingDoc.id);
        // 删除旧的 chunks
        await (delete(noteChunks)..where((tbl) => tbl.documentId.equals(existingDoc.id))).go();
        // 更新文档
        await (update(noteDocuments)..where((tbl) => tbl.id.equals(existingDoc.id))).write(
          NoteDocumentsCompanion(
            title: Value(title),
            lastModified: Value(lastModified),
            contentHash: Value(contentHash),
          ),
        );
        docId = existingDoc.id;
      } else {
        docId = await into(noteDocuments).insert(
          NoteDocumentsCompanion.insert(
            filePath: filePath,
            title: title,
            lastModified: lastModified,
            contentHash: contentHash,
          ),
        );
      }

      // Insert chunks and sync to FTS5
      for (final chunk in chunkList) {
        final headingPath = chunk.headingPath as String;
        final content = chunk.content as String;
        final level = chunk.level as int;

        // 插入到 note_chunks 表
        final chunkId = await into(noteChunks).insert(
          NoteChunksCompanion.insert(
            documentId: docId,
            heading: Value(headingPath),
            content: content,
            priority: Value(level),
          ),
        );

        // 同步到 FTS5 索引表（包含标题）
        await _insertFTSEntry(chunkId, title, headingPath, content);
      }
    });
  }

  /// 删除文档的 FTS5 索引
  Future<void> _deleteFTSForDocument(int documentId) async {
    // 获取该文档的所有 chunk IDs
    final chunks = await (select(noteChunks)..where((t) => t.documentId.equals(documentId))).get();
    for (final chunk in chunks) {
      await customStatement(
        'DELETE FROM note_search_index WHERE rowid = ?',
        [chunk.id],
      );
    }
  }

  /// 插入 FTS5 索引条目（包含标题用于搜索）
  Future<void> _insertFTSEntry(int rowid, String title, String heading, String content) async {
    // 将标题也加入索引，便于搜索笔记名称
    final fullContent = '$title $heading $content';
    await customStatement(
      'INSERT INTO note_search_index(rowid, heading, content) VALUES (?, ?, ?)',
      [rowid, heading, fullContent],
    );
  }

  // FTS5 全文搜索功能
  /// 使用 FTS5 搜索文档切片，返回 BM25 排序的结果
  ///
  /// [query] 搜索查询
  /// [limit] 返回结果数量限制
  /// Returns 包含相关性评分的切片结果列表
  Future<List<NoteChunkResult>> searchChunks(
    String query, {
    int limit = 10,
  }) async {
    // 调试：检查索引状态
    await _debugIndexStatus();

    // 将普通查询转换为 FTS5 格式
    final ftsQuery = _buildFTSQuery(query);
    print('[FTS5] 原始查询: "$query" -> FTS5查询: "$ftsQuery"');
    if (ftsQuery.isEmpty) return [];

    try {
      final sql = '''
        SELECT
          nc.id,
          nc.document_id,
          nc.heading,
          nc.content,
          nc.priority,
          nd.file_path as sourceFilePath,
          nd.title,
          bm25(note_search_index) as score
        FROM note_chunks nc
        INNER JOIN note_documents nd ON nc.document_id = nd.id
        INNER JOIN note_search_index ns ON nc.id = ns.rowid
        WHERE note_search_index MATCH ?
        ORDER BY score
        LIMIT ?
        ''';
      print('[FTS5] SQL: $sql');
      print('[FTS5] Variables: [$ftsQuery, $limit]');
      
      final results = await customSelect(
        sql,
        variables: [Variable.withString(ftsQuery), Variable.withInt(limit)],
      ).get();

      print('[FTS5] Raw results: ${results.length} rows');
      for (final row in results) {
        print('[FTS5] Row: id=${row.read<int>('id')}, title=${row.read<String>('title')}, content=${row.read<String>('content').substring(0, (row.read<String>('content').length > 50 ? 50 : row.read<String>('content').length))}...');
      }

      return results.map((row) {
        return NoteChunkResult(
          id: row.read<int>('id'),
          documentId: row.read<int>('document_id'),
          heading: row.read<String?>('heading'),
          content: row.read<String>('content'),
          priority: row.read<int>('priority'),
          sourceFilePath: row.read<String>('sourceFilePath'),
          title: row.read<String>('title'),
          score: row.read<double>('score'),
        );
      }).toList();
    } catch (e) {
      // FTS5 查询失败时返回空结果
      print('FTS5 search error: $e');
      return [];
    }
  }

  /// 将普通查询转换为 FTS5 查询格式
  /// 针对中文进行特殊处理：提取关键词并分词
  String _buildFTSQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return '';

    // 如果已经是 FTS5 格式，直接返回
    if (trimmed.contains(' OR ') || trimmed.contains(' AND ')) {
      return trimmed;
    }

    // 提取所有有意义的词（中文字符、英文单词、数字）
    final terms = <String>[];

    // 提取英文单词和数字
    final englishPattern = RegExp(r'[a-zA-Z0-9]+');
    for (final match in englishPattern.allMatches(trimmed)) {
      final word = match.group(0)!.toLowerCase();
      if (word.length >= 2) {
        terms.add(word);
      }
    }

    // 提取中文关键词（每2-4个字作为一个词）
    final chinesePattern = RegExp(r'[\u4e00-\u9fa5]+');
    for (final match in chinesePattern.allMatches(trimmed)) {
      final chinese = match.group(0)!;
      // 对于短中文词，直接添加
      if (chinese.length <= 4) {
        terms.add(chinese);
      } else {
        // 对于长中文词，分成2-3字的片段
        for (int i = 0; i < chinese.length - 1; i++) {
          terms.add(chinese.substring(i, i + 2)); // 2字词
          if (i < chinese.length - 2) {
            terms.add(chinese.substring(i, i + 3)); // 3字词
          }
        }
      }
    }

    if (terms.isEmpty) return trimmed; // 返回原始查询

    // 去重
    final uniqueTerms = terms.toSet().toList();
    print('[FTS5] 分词结果: $uniqueTerms');

    // 使用 OR 连接所有词
    return uniqueTerms.map((t) => '"$t"').join(' OR ');
  }

  /// 重建 FTS5 索引
  /// 在批量导入数据后调用此方法以确保索引完整
  Future<void> rebuildFTSIndex() async {
    await customStatement('''
      INSERT INTO note_search_index(note_search_index)
      VALUES('rebuild');
    ''');
  }

  /// 调试：检查索引状态
  Future<void> _debugIndexStatus() async {
    try {
      // 检查 note_documents 数量
      final docCount = await customSelect('SELECT COUNT(*) as cnt FROM note_documents').getSingle();
      print('[DEBUG] note_documents 表记录数: ${docCount.read<int>('cnt')}');

      // 检查 note_chunks 数量
      final chunkCount = await customSelect('SELECT COUNT(*) as cnt FROM note_chunks').getSingle();
      final chunksTotal = chunkCount.read<int>('cnt');
      print('[DEBUG] note_chunks 表记录数: $chunksTotal');

      // 检查 FTS5 索引数量（可能因结构问题失败）
      int ftsTotal = 0;
      try {
        final ftsCount = await customSelect('SELECT COUNT(*) as cnt FROM note_search_index').getSingle();
        ftsTotal = ftsCount.read<int>('cnt');
        print('[DEBUG] note_search_index (FTS5) 记录数: $ftsTotal');
      } catch (e) {
        print('[DEBUG] ⚠️ FTS5 表结构有问题，正在重建...');
        await _rebuildFTSTable();
        ftsTotal = 0;
      }

      // 如果 chunks 有数据但 FTS5 为空，自动修复
      if (chunksTotal > 0 && ftsTotal == 0) {
        print('[DEBUG] ⚠️ 检测到 FTS5 索引为空，正在自动修复...');
        await syncAllChunksToFTS();
        print('[DEBUG] ✅ FTS5 索引修复完成');
      }
    } catch (e) {
      print('[DEBUG] 检查索引状态出错: $e');
    }
  }

  /// 重建 FTS5 表（修复结构问题）
  Future<void> _rebuildFTSTable() async {
    try {
      // 删除旧的 FTS5 表
      await customStatement('DROP TABLE IF EXISTS note_search_index');
      print('[FTS5] 已删除旧的 FTS5 表');

      // 创建新的 FTS5 表（使用正确的列名）
      await customStatement('''
        CREATE VIRTUAL TABLE note_search_index
        USING fts5(
          heading,
          content,
          content_rowid=rowid,
          content='note_chunks'
        )
      ''');
      print('[FTS5] 已创建新的 FTS5 表');
    } catch (e) {
      print('[FTS5] 重建 FTS5 表失败: $e');
    }
  }

  /// 将所有现有 chunks 同步到 FTS5 索引
  /// 用于修复旧数据的索引问题
  Future<void> syncAllChunksToFTS() async {
    print('[FTS5] 开始同步所有 chunks 到 FTS5 索引...');

    // 获取所有 chunks
    final chunks = await select(noteChunks).get();
    print('[FTS5] 找到 ${chunks.length} 个 chunks');

    for (final chunk in chunks) {
      try {
        // 先尝试删除可能存在的旧记录
        await customStatement(
          'DELETE FROM note_search_index WHERE rowid = ?',
          [chunk.id],
        );
        // 插入新记录（列名必须与 FTS5 表定义匹配）
        await customStatement(
          'INSERT INTO note_search_index(rowid, heading, content) VALUES (?, ?, ?)',
          [chunk.id, chunk.heading ?? '', chunk.content],
        );
      } catch (e) {
        print('[FTS5] 同步 chunk ${chunk.id} 失败: $e');
      }
    }

    print('[FTS5] 同步完成，共处理 ${chunks.length} 个 chunks');
  }
}
