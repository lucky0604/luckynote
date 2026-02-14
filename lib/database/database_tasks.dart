part of 'database.dart';

extension AppDatabaseTasks on AppDatabase {
  /// 获取所有未完成的任务（包含文档信息）
  /// 只返回文件仍然存在的任务（通过 INNER JOIN notes 表过滤孤儿数据）
  Future<List<TaskWithDocument>> getAllPendingTasks() async {
    final results = await customSelect('''
    SELECT t.id, t.document_id, t.content, t.is_completed, t.raw_line,
           t.line_number, t.created_at, nd.title as documentTitle, nd.file_path as filePath
    FROM tasks t
    INNER JOIN note_documents nd ON t.document_id = nd.id
    INNER JOIN notes n ON nd.file_path = n.file_path
    WHERE t.is_completed = 0
    ORDER BY t.created_at DESC
  ''').get();

    return results
        .map((row) => TaskWithDocument(
              id: row.read<int>('id'),
              documentId: row.read<int>('document_id'),
              content: row.read<String>('content'),
              isCompleted: row.read<bool>('is_completed'),
              rawLine: row.read<String>('raw_line'),
              lineNumber: row.read<int>('line_number'),
              createdAt: row.read<DateTime>('created_at'),
              documentTitle: row.read<String>('documentTitle'),
              filePath: row.read<String>('filePath'),
            ))
        .toList();
  }

  /// 监听未完成任务的变化（实时流）
  /// 只返回文件仍然存在的任务（通过 INNER JOIN notes 表过滤孤儿数据）
  Stream<List<TaskWithDocument>> watchPendingTasks() {
    return customSelect('''
    SELECT t.id, t.document_id, t.content, t.is_completed, t.raw_line,
           t.line_number, t.created_at, nd.title as documentTitle, nd.file_path as filePath
    FROM tasks t
    INNER JOIN note_documents nd ON t.document_id = nd.id
    INNER JOIN notes n ON nd.file_path = n.file_path
    WHERE t.is_completed = 0
    ORDER BY t.created_at DESC
  ''', readsFrom: {tasks, noteDocuments, notes}).watch().map((results) {
      return results
          .map((row) => TaskWithDocument(
                id: row.read<int>('id'),
                documentId: row.read<int>('document_id'),
                content: row.read<String>('content'),
                isCompleted: row.read<bool>('is_completed'),
                rawLine: row.read<String>('raw_line'),
                lineNumber: row.read<int>('line_number'),
                createdAt: row.read<DateTime>('created_at'),
                documentTitle: row.read<String>('documentTitle'),
                filePath: row.read<String>('filePath'),
              ))
          .toList();
    });
  }

  /// 监听所有任务的变化（含筛选）
  /// [filter] 为 null 表示全部，true 表示已完成，false 表示未完成
  /// 只返回文件仍然存在的任务（通过 INNER JOIN notes 表过滤孤儿数据）
  Stream<List<TaskWithDocument>> watchAllTasks({bool? filter}) {
    String whereClause = '';
    if (filter != null) {
      whereClause = filter ? 'WHERE t.is_completed = 1' : 'WHERE t.is_completed = 0';
    }

    return customSelect('''
    SELECT t.id, t.document_id, t.content, t.is_completed, t.raw_line,
           t.line_number, t.created_at, nd.title as documentTitle, nd.file_path as filePath
    FROM tasks t
    INNER JOIN note_documents nd ON t.document_id = nd.id
    INNER JOIN notes n ON nd.file_path = n.file_path
    $whereClause
    ORDER BY t.is_completed ASC, t.created_at DESC
  ''', readsFrom: {tasks, noteDocuments, notes}).watch().map((results) {
      return results
          .map((row) => TaskWithDocument(
                id: row.read<int>('id'),
                documentId: row.read<int>('document_id'),
                content: row.read<String>('content'),
                isCompleted: row.read<bool>('is_completed'),
                rawLine: row.read<String>('raw_line'),
                lineNumber: row.read<int>('line_number'),
                createdAt: row.read<DateTime>('created_at'),
                documentTitle: row.read<String>('documentTitle'),
                filePath: row.read<String>('filePath'),
              ))
          .toList();
    });
  }

  /// 获取所有任务（含筛选）
  /// 只返回文件仍然存在的任务（通过 INNER JOIN notes 表过滤孤儿数据）
  Future<List<TaskWithDocument>> getAllTasks({bool? filter}) async {
    String whereClause = '';
    if (filter != null) {
      whereClause = filter ? 'WHERE t.is_completed = 1' : 'WHERE t.is_completed = 0';
    }

    final results = await customSelect('''
    SELECT t.id, t.document_id, t.content, t.is_completed, t.raw_line,
           t.line_number, t.created_at, nd.title as documentTitle, nd.file_path as filePath
    FROM tasks t
    INNER JOIN note_documents nd ON t.document_id = nd.id
    INNER JOIN notes n ON nd.file_path = n.file_path
    $whereClause
    ORDER BY t.is_completed ASC, t.created_at DESC
  ''').get();

    return results
        .map((row) => TaskWithDocument(
              id: row.read<int>('id'),
              documentId: row.read<int>('document_id'),
              content: row.read<String>('content'),
              isCompleted: row.read<bool>('is_completed'),
              rawLine: row.read<String>('raw_line'),
              lineNumber: row.read<int>('line_number'),
              createdAt: row.read<DateTime>('created_at'),
              documentTitle: row.read<String>('documentTitle'),
              filePath: row.read<String>('filePath'),
            ))
        .toList();
  }

  /// 删除文档的所有任务
  Future<void> deleteTasksByDocumentId(int documentId) async {
    await (delete(tasks)..where((tbl) => tbl.documentId.equals(documentId))).go();
  }

  /// 批量插入任务
  Future<void> insertTasksList(List<Task> tasks) async {
    await batch((batch) {
      batch.insertAll(
        this.tasks,
        tasks
            .map((t) => TasksCompanion.insert(
                  documentId: t.documentId,
                  content: t.content,
                  isCompleted: Value(t.isCompleted),
                  rawLine: t.rawLine,
                  lineNumber: Value(t.lineNumber),
                  createdAt: Value(t.createdAt),
                ))
            .toList(),
      );
    });
  }

  /// 清理孤儿数据 - 删除没有对应文件的任务
  /// 返回删除的记录数
  Future<int> deleteOrphanTasks() async {
    final result = await customSelect('''
      SELECT COUNT(*) as count
      FROM tasks t
      LEFT JOIN notes n ON t.document_id IN (
        SELECT id FROM note_documents WHERE file_path = n.file_path
      )
      WHERE n.file_path IS NULL
    ''').getSingle();

    final count = result.read<int>('count');
    if (count > 0) {
      await customStatement('''
        DELETE FROM tasks
        WHERE document_id IN (
          SELECT id FROM note_documents
          WHERE file_path NOT IN (SELECT file_path FROM notes)
        )
      ''');
    }
    return count;
  }

  /// 清理孤儿数据 - 删除没有对应文件的文档记录
  /// 返回删除的记录数
  Future<int> deleteOrphanDocuments() async {
    final result = await customSelect('''
      SELECT COUNT(*) as count
      FROM note_documents nd
      WHERE nd.file_path NOT IN (SELECT file_path FROM notes)
    ''').getSingle();

    final count = result.read<int>('count');
    if (count > 0) {
      await customStatement('''
        DELETE FROM note_documents
        WHERE file_path NOT IN (SELECT file_path FROM notes)
      ''');
    }
    return count;
  }

  /// 清理所有孤儿数据（任务和文档）
  /// 返回删除的总记录数
  Future<Map<String, int>> deleteAllOrphanData() async {
    final deletedTasks = await deleteOrphanTasks();
    final deletedDocuments = await deleteOrphanDocuments();
    return {
      'tasks': deletedTasks,
      'documents': deletedDocuments,
    };
  }
}
