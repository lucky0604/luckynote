import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';
part 'database_connection.dart';
part 'database_fts.dart';
part 'database_references.dart';
part 'database_tasks.dart';
part 'database_models.dart';

// 注意：NoteSearch (FTS5) 不在这里声明，通过 customStatement 手动创建
@DriftDatabase(tables: [Notes, Tags, NoteTags, NoteDocuments, NoteChunks, NoteReferences, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // 创建 FTS5 全文搜索虚拟表（列名必须与 note_chunks 匹配）
        await customStatement('''
          CREATE VIRTUAL TABLE IF NOT EXISTS note_search_index
          USING fts5(
            heading,
            content,
            content_rowid=rowid,
            content='note_chunks'
          );
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // 为现有数据库添加 FTS5 表（列名必须与 note_chunks 匹配）
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS note_search_index
            USING fts5(
              heading,
              content,
              content_rowid=rowid,
              content='note_chunks'
            );
          ''');
        }
        if (from < 3) {
          // 添加 NoteReferences 表用于 WikiLink 双链功能
          await m.createTable(noteReferences);
        }
        if (from < 4) {
          // 添加 Tasks 表用于任务管理功能
          await m.createTable(tasks);
        }
      },
    );
  }
}
