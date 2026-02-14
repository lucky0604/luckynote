import 'dart:io';

import 'package:drift/drift.dart';

import '../../../../core/utils/file_utils.dart';
import '../../../../database/database.dart';
import 'package:luckynote/domains/notes/data/repositories/note_repository.dart';
import 'tag_indexer.dart';
import 'task_indexer.dart';

/// File indexing service.
///
/// Handles indexing of individual markdown files.
class FileIndexer {
  const FileIndexer({
    required this.noteRepository,
    required this.tagIndexer,
    required this.taskIndexer,
  });

  final NoteRepository noteRepository;
  final TagIndexer tagIndexer;
  final TaskIndexer taskIndexer;

  /// Create a new note index from a file.
  Future<Note> createNote(String filePath, FileStat stat, AppDatabase database) async {
    print('[FileIndexer] Creating note: $filePath');
    final file = File(filePath);
    final content = await file.readAsString();

    final title = FileUtils.extractTitleFromContent(content);
    final preview = FileUtils.extractPreviewFromContent(content);
    print('[FileIndexer] Title: $title, Preview: ${preview.length > 50 ? '${preview.substring(0, 50)}...' : preview}');

    final noteId = await noteRepository.insert(
      NotesCompanion.insert(
        filePath: filePath,
        title: title,
        preview: preview,
        createdAt: stat.modified,
        modifiedAt: stat.modified,
        isPinned: const Value(false),
      ),
    );

    print('[FileIndexer] Inserted with ID: $noteId');

    final note = await noteRepository.getById(noteId);
    if (note == null) {
      print('[FileIndexer] Error: Failed to retrieve created note');
      throw StateError('Failed to retrieve created note');
    }

    print('[FileIndexer] Retrieved: ${note.title}');

    // Parse and associate tags
    await tagIndexer.updateNoteTags(note, content);

    // Index tasks
    await taskIndexer.indexNoteTasks(note, content, database);

    print('[FileIndexer] Completed');
    return note;
  }

  /// Update an existing note index.
  Future<Note> updateNote(Note note, String filePath, AppDatabase database) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final stat = await file.stat();

    final updated = Note(
      id: note.id,
      filePath: filePath,
      title: FileUtils.extractTitleFromContent(content),
      preview: FileUtils.extractPreviewFromContent(content),
      createdAt: note.createdAt,
      modifiedAt: stat.modified,
      isPinned: note.isPinned,
    );

    // Save note
    await noteRepository.put(updated);

    // Update tags
    await tagIndexer.updateNoteTags(updated, content);

    // Update tasks
    await taskIndexer.indexNoteTasks(updated, content, database);

    return updated;
  }

  /// Check if a file is indexable.
  bool isIndexable(String filePath) {
    return FileUtils.isMarkdownFile(filePath);
  }

  /// Check if a file exists.
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }
}
