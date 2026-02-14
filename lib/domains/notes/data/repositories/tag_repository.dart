import 'package:drift/drift.dart';
import 'package:luckynote/database/database.dart';

class TagRepository {
  TagRepository(this._database);

  final AppDatabase _database;

  Future<List<Tag>> getAll() async {
    final query = _database.select(_database.tags)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  Future<List<TagWithCount>> getAllWithCount() async {
    final allTags = await getAll();
    final result = <TagWithCount>[];

    for (final tag in allTags) {
      final noteTags = await (_database.select(
        _database.noteTags,
      )..where((nt) => nt.tagId.equals(tag.id))).get();

      result.add(TagWithCount(tag: tag, noteCount: noteTags.length));
    }

    return result;
  }

  Future<Tag?> getByName(String name) async {
    return await (_database.select(
      _database.tags,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  Future<Tag?> getById(int id) async {
    return await (_database.select(
      _database.tags,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Tag> getOrCreate(String name) async {
    final existing = await getByName(name);
    if (existing != null) {
      return existing;
    }

    final id = await _database
        .into(_database.tags)
        .insert(TagsCompanion.insert(name: name));
    return Tag(id: id, name: name);
  }

  Future<List<Tag>> getOrCreateMany(List<String> names) async {
    final tags = <Tag>[];
    for (final name in names) {
      tags.add(await getOrCreate(name));
    }
    return tags;
  }

  Future<int> put(Tag tag) async {
    return await _database.into(_database.tags).insertOnConflictUpdate(tag);
  }

  Future<bool> delete(int id) async {
    final count = await (_database.delete(
      _database.tags,
    )..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  Future<int> deleteOrphans() async {
    final allTags = await getAll();
    int deletedCount = 0;

    for (final tag in allTags) {
      final noteCount = (await (_database.select(
        _database.noteTags,
      )..where((nt) => nt.tagId.equals(tag.id))).get()).length;

      if (noteCount == 0) {
        final count = await (_database.delete(
          _database.tags,
        )..where((t) => t.id.equals(tag.id))).go();
        deletedCount += count;
      }
    }

    return deletedCount;
  }

  Future<int> count() async {
    return (await _database.select(_database.tags).get()).length;
  }

  Future<List<Tag>> getTagsForNote(Note note) async {
    final noteTags = await (_database.select(
      _database.noteTags,
    )..where((nt) => nt.noteId.equals(note.id))).get();

    if (noteTags.isEmpty) {
      return [];
    }

    final tagIds = noteTags.map((nt) => nt.tagId).toList();

    return await (_database.select(
      _database.tags,
    )..where((t) => t.id.isIn(tagIds))).get();
  }

  static List<String> parseTagsFromContent(String content) {
    final regex = RegExp(r'#([a-zA-Z0-9_/\u4e00-\u9fa5]+)');
    final matches = regex.allMatches(content);

    final tagsSet = <String>{};
    for (final match in matches) {
      final tag = match.group(1);
      if (tag != null && tag.isNotEmpty) {
        tagsSet.add(tag);
      }
    }

    return tagsSet.toList()..sort();
  }
}

class TagWithCount {
  const TagWithCount({required this.tag, required this.noteCount});

  final Tag tag;
  final int noteCount;
}
