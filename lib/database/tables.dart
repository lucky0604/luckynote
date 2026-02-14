import 'package:drift/drift.dart';

@DataClassName('Note')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text().unique()();
  TextColumn get title => text()();
  TextColumn get preview => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
}

@DataClassName('Tag')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

@DataClassName('NoteTag')
class NoteTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId =>
      integer().references(Notes, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();
}

@DataClassName('NoteDocument')
class NoteDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text().unique()();
  TextColumn get title => text()();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get contentHash => text()();
}

@DataClassName('NoteChunk')
class NoteChunks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId =>
      integer().references(NoteDocuments, #id, onDelete: KeyAction.cascade)();
  TextColumn get heading => text().nullable()();
  TextColumn get content => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
}

/// FTS5 虚拟表用于全文搜索
/// 使用 External Content 模式，实际数据存储在 NoteChunks 表中
/// 注意：列名必须与 note_chunks 表匹配（heading, content）
class NoteSearch extends Table {
  TextColumn get heading => text()();
  TextColumn get content => text()();

  @override
  String get tableName => 'note_search_index';

  @override
  List<String> get customConstraints => [
    'USING fts5(heading, content, content="note_chunks", content_rowid=rowid)'
  ];
}

/// WikiLink 双向链接引用表
/// 存储笔记之间的引用关系，用于实现类似 Obsidian 的双链功能
@DataClassName('NoteReference')
class NoteReferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  // 发起引用的笔记 (Source)
  IntColumn get sourceDocId =>
      integer().references(NoteDocuments, #id, onDelete: KeyAction.cascade)();
  // 被引用的笔记标题 (Target Title) - 这里存标题而非 ID，因为引用时目标文件可能还不存在
  TextColumn get targetTitle => text()();

  // 索引优化查询速度
  @override
  List<Set<Column>> get uniqueKeys => [{sourceDocId, targetTitle}];
}

/// Task 表 - 存储 Markdown 文件中的任务项
@DataClassName('Task')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId =>
      integer().references(NoteDocuments, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get rawLine => text()();
  IntColumn get lineNumber => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
