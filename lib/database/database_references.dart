part of 'database.dart';

extension AppDatabaseReferences on AppDatabase {
  /// 更新笔记的 WikiLink 引用关系
  /// 从内容中提取 [[Title]] 或 [[Title|Alias]] 格式的链接并存储
  Future<void> updateNoteReferences(int documentId, String content) async {
    // 提取所有 WikiLink
    final linkPattern = RegExp(r'\[\[(.*?)(?:\|(.*?))?\]\]');
    final matches = linkPattern.allMatches(content);

    final targetTitles = matches
        .map((m) => m.group(1)?.trim() ?? '')
        .where((title) => title.isNotEmpty)
        .toSet()
        .toList();

    await transaction(() async {
      // 删除该文档的旧引用
      await (delete(noteReferences)
            ..where((tbl) => tbl.sourceDocId.equals(documentId)))
          .go();

      // 插入新引用
      if (targetTitles.isNotEmpty) {
        final companions = targetTitles
            .map((title) => NoteReferencesCompanion.insert(
                  sourceDocId: documentId,
                  targetTitle: title,
                ))
            .toList();

        await batch((batch) => batch.insertAll(noteReferences, companions));
      }
    });
  }

  /// 获取指向某个笔记的反向链接 (Backlinks)
  /// 返回所有引用了当前标题的笔记列表
  Future<List<BacklinkResult>> getBacklinks(String targetTitle) async {
    final results = await customSelect('''
      SELECT
        nr.id,
        nr.source_doc_id,
        nd.title as sourceTitle,
        nd.file_path as sourceFilePath
      FROM note_references nr
      INNER JOIN note_documents nd ON nr.source_doc_id = nd.id
      WHERE nr.target_title = ?
      ORDER BY nd.title
    ''', variables: [Variable(targetTitle)]).get();

    return results
        .map((row) => BacklinkResult(
              id: row.read<int>('id'),
              sourceDocId: row.read<int>('source_doc_id'),
              sourceTitle: row.read<String>('sourceTitle'),
              sourceFilePath: row.read<String>('sourceFilePath'),
            ))
        .toList();
  }

  /// 按标题搜索文档 (用于全局搜索)
  Future<List<TitleSearchResult>> searchByTitle(String query, {int limit = 10}) async {
    final results = await (select(noteDocuments)
          ..where((tbl) => tbl.title.like('%$query%'))
          ..limit(limit))
        .get();

    return results
        .map((doc) => TitleSearchResult(
              documentId: doc.id,
              title: doc.title,
              filePath: doc.filePath,
            ))
        .toList();
  }

  /// 获取所有笔记标题 (用于 WikiLink 自动补全)
  /// 过滤掉无效标题（空字符串、纯符号、过短等）
  Future<List<String>> getAllNoteTitles() async {
    final docs = await select(noteDocuments).get();
    return docs
        .map((d) => d.title)
        .where((title) => _isValidNoteTitle(title))
        .toSet()
        .toList()
      ..sort();
  }

  /// 检查标题是否有效（用于过滤错误数据）
  bool _isValidNoteTitle(String title) {
    // 过滤空字符串
    if (title.trim().isEmpty) return false;
    // 过滤过短的标题（少于2个字符）
    if (title.length < 2) return false;
    // 过滤纯数字或纯符号
    if (RegExp(r'^[\d\-\s#]+$').hasMatch(title)) return false;
    return true;
  }
}
