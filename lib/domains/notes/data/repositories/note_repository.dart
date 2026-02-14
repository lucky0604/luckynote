import 'package:drift/drift.dart';
import 'package:luckynote/database/database.dart';

enum NoteSortType { modifiedAt, createdAt, title }

class NoteRepository {
  NoteRepository(this._database);

  final AppDatabase _database;

  AppDatabase get database => _database;

  Future<List<Note>> getAll({
    NoteSortType sortType = NoteSortType.modifiedAt,
    bool ascending = false,
    String? tagFilter,
    String? folderFilter,
  }) async {
    print(
      '[NoteRepository] getAll 开始，tagFilter: $tagFilter, folderFilter: $folderFilter',
    );
    try {
      var query = _database.select(_database.notes);

      // Apply folder filter
      if (folderFilter != null) {
        query = query..where((n) => n.filePath.like('$folderFilter%'));
      }

      // Apply tag filter
      if (tagFilter != null) {
        final tag = await (_database.select(
          _database.tags,
        )..where((t) => t.name.equals(tagFilter))).getSingleOrNull();

        if (tag != null) {
          final noteIds =
              await (_database.select(_database.noteTags)
                    ..where((nt) => nt.tagId.equals(tag.id)))
                  .map((nt) => nt.noteId)
                  .get();

          query = query..where((n) => n.id.isIn(noteIds));
        }
      }

      // Apply sorting
      switch (sortType) {
        case NoteSortType.modifiedAt:
          query = query..orderBy([(n) => OrderingTerm.asc(n.modifiedAt)]);
        case NoteSortType.createdAt:
          query = query..orderBy([(n) => OrderingTerm.asc(n.createdAt)]);
        case NoteSortType.title:
          query = query..orderBy([(n) => OrderingTerm.asc(n.title)]);
      }

      final results = await query.get();
      print('[NoteRepository] getAll 完成，返回 ${results.length} 条笔记');
      return !ascending ? results.reversed.toList() : results;
    } catch (e) {
      print('[NoteRepository] getAll 出错: $e');
      rethrow;
    }
  }

  Future<List<Note>> getAllSorted({
    NoteSortType sortType = NoteSortType.modifiedAt,
    bool ascending = false,
    String? tagFilter,
    String? folderFilter,
  }) async {
    final notesList = await getAll(
      sortType: sortType,
      ascending: ascending,
      tagFilter: tagFilter,
      folderFilter: folderFilter,
    );

    final pinned = notesList.where((n) => n.isPinned).toList();
    final unpinned = notesList.where((n) => !n.isPinned).toList();

    return [...pinned, ...unpinned];
  }

  Future<Note?> getByFilePath(String filePath) async {
    return await (_database.select(
      _database.notes,
    )..where((t) => t.filePath.equals(filePath))).getSingleOrNull();
  }

  Future<Note?> getById(int id) async {
    print('[NoteRepository] getById 开始: $id');
    try {
      final result = await (_database.select(
        _database.notes,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      print('[NoteRepository] getById 完成: ${result?.title ?? 'null'}');
      return result;
    } catch (e) {
      print('[NoteRepository] getById 出错: $e');
      rethrow;
    }
  }

  /// 根据标题查找笔记（用于 WikiLink 导航）
  Future<Note?> getByTitle(String title) async {
    print('[NoteRepository] getByTitle 开始: $title');
    try {
      final result = await (_database.select(
        _database.notes,
      )..where((t) => t.title.equals(title))).getSingleOrNull();
      print('[NoteRepository] getByTitle 完成: ${result?.title ?? 'null'}');
      return result;
    } catch (e) {
      print('[NoteRepository] getByTitle 出错: $e');
      rethrow;
    }
  }

  Future<int> put(Note note) async {
    return await _database.into(_database.notes).insertOnConflictUpdate(note);
  }

  Future<int> insert(NotesCompanion companion) async {
    print('[NoteRepository] insert 开始');
    try {
      final id = await _database.into(_database.notes).insert(companion);
      print('[NoteRepository] insert 成功，ID: $id');
      return id;
    } catch (e) {
      print('[NoteRepository] insert 出错: $e');
      rethrow;
    }
  }

  Future<void> putMany(List<Note> notesList) async {
    for (final note in notesList) {
      await _database.into(_database.notes).insertOnConflictUpdate(note);
    }
  }

  Future<bool> delete(int id) async {
    final count = await (_database.delete(
      _database.notes,
    )..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  Future<bool> deleteByFilePath(String filePath) async {
    final count = await (_database.delete(
      _database.notes,
    )..where((t) => t.filePath.equals(filePath))).go();
    return count > 0;
  }

  Future<bool> togglePin(int id) async {
    final note = await getById(id);
    if (note != null) {
      final updated = note.copyWith(isPinned: !note.isPinned);
      await _database.into(_database.notes).insertOnConflictUpdate(updated);
      return true;
    }
    return false;
  }

  Future<bool> setPin(int id, bool isPinned) async {
    final note = await getById(id);
    if (note != null) {
      final updated = note.copyWith(isPinned: isPinned);
      await _database.into(_database.notes).insertOnConflictUpdate(updated);
      return true;
    }
    return false;
  }

  Future<void> updateTags(Note note, List<Tag> tags) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.noteTags,
      )..where((nt) => nt.noteId.equals(note.id))).go();

      for (final tag in tags) {
        await _database
            .into(_database.noteTags)
            .insert(NoteTagsCompanion.insert(noteId: note.id, tagId: tag.id));
      }
    });
  }

  /// 更新文件路径（用于重命名/移动）
  Future<void> updateFilePath(String oldPath, String newPath) async {
    await _database.transaction(() async {
      final note = await (_database.select(
        _database.notes,
      )..where((t) => t.filePath.equals(oldPath))).getSingleOrNull();
      if (note != null) {
        final updatedNote = note.copyWith(filePath: newPath);
        await _database.into(_database.notes).insertOnConflictUpdate(updatedNote);
      }

      final doc = await (_database.select(
        _database.noteDocuments,
      )..where((d) => d.filePath.equals(oldPath))).getSingleOrNull();
      if (doc != null) {
        final updatedDoc = doc.copyWith(filePath: newPath);
        await _database
            .into(_database.noteDocuments)
            .insertOnConflictUpdate(updatedDoc);
      }
    });
  }

  Future<List<Note>> search(String queryStr) async {
    if (queryStr.isEmpty) {
      return await getAllSorted();
    }

    final lowerQuery = '%$queryStr%';
    final results =
        await (_database.select(_database.notes)
              ..where(
                (t) => t.title.like(lowerQuery) | t.preview.like(lowerQuery),
              ))
            .get();
    return results;
  }

  /// 获取笔记总数（不受筛选条件影响）
  Future<int> count() async {
    final result = await _database.customSelect(
      'SELECT COUNT(*) as cnt FROM notes',
    ).getSingle();
    return result.read<int>('cnt');
  }
}
