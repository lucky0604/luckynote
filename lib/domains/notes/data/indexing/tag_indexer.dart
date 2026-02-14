import '../../../../database/database.dart';
import 'package:luckynote/domains/notes/data/repositories/note_repository.dart';
import 'package:luckynote/domains/notes/data/repositories/tag_repository.dart';

/// Tag indexing service.
///
/// Handles tag parsing and association with notes.
class TagIndexer {
  const TagIndexer({
    required this.noteRepository,
    required this.tagRepository,
  });

  final NoteRepository noteRepository;
  final TagRepository tagRepository;

  /// Update tags for a note based on content.
  Future<void> updateNoteTags(Note note, String content) async {
    final tagNames = TagRepository.parseTagsFromContent(content);
    final tags = await tagRepository.getOrCreateMany(tagNames);
    await noteRepository.updateTags(note, tags);
  }

  /// Clean up orphaned tags (tags with no associated notes).
  Future<void> deleteOrphans() async {
    await tagRepository.deleteOrphans();
  }
}
