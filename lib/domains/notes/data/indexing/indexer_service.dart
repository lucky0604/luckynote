import 'dart:io';

import '../../../../core/utils/file_utils.dart';
import '../../../../database/database.dart';
import 'package:luckynote/domains/notes/data/repositories/note_repository.dart';
import 'package:luckynote/domains/notes/data/repositories/tag_repository.dart';
import 'package:luckynote/domains/tasks/data/repositories/task_repository.dart';
import 'package:luckynote/domains/rag/data/services/document_service.dart';
import 'file_indexer.dart';
import 'tag_indexer.dart';
import 'task_indexer.dart';
import 'index_result.dart';

/// Indexing service coordinator.
///
/// Coordinates file system and database synchronization.
class IndexerService {
  IndexerService({
    required this.noteRepository,
    required this.tagRepository,
    required this.taskRepository,
    required this.database,
    DocumentService? documentService,
  })  : _documentService = documentService {
    _tagIndexer = TagIndexer(
      noteRepository: noteRepository,
      tagRepository: tagRepository,
    );
    _taskIndexer = TaskIndexer(
      taskRepository: taskRepository,
    );
    _fileIndexer = FileIndexer(
      noteRepository: noteRepository,
      tagIndexer: _tagIndexer,
      taskIndexer: _taskIndexer,
    );
  }

  final NoteRepository noteRepository;
  final TagRepository tagRepository;
  final TaskRepository taskRepository;
  final AppDatabase database;
  final DocumentService? _documentService;

  late final FileIndexer _fileIndexer;
  late final TagIndexer _tagIndexer;
  late final TaskIndexer _taskIndexer;

  /// Full scan and sync index.
  /// Compares file system with database and updates changed files.
  /// [forceReindex] If true, force reindex all files (for FTS5 index repair).
  /// [onProgress] Optional callback for progress updates (current, total).
  Future<IndexResult> fullScan(
    String vaultPath, {
    bool forceReindex = false,
    void Function(int current, int total)? onProgress,
  }) async {
    print('[IndexerService] fullScan start: $vaultPath, forceReindex: $forceReindex');
    try {
      final directory = Directory(vaultPath);

      if (!await directory.exists()) {
        print('[IndexerService] Directory does not exist');
        return IndexResult.empty();
      }

      final result = IndexResult();

      // Get all markdown files from file system
      final filesInFs = <String, FileStat>{};
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && FileUtils.isMarkdownFile(entity.path)) {
          filesInFs[entity.path] = await entity.stat();
        }
      }

      final totalFiles = filesInFs.length;
      print('[IndexerService] Found $totalFiles markdown files');

      // Get all notes from database
      final notesInDb = await noteRepository.getAll();
      print('[IndexerService] Database has ${notesInDb.length} notes');
      final pathsInDb = <String, Note>{};
      for (final note in notesInDb) {
        pathsInDb[note.filePath] = note;
      }

      // Detect new and modified files
      int processedCount = 0;
      for (final entry in filesInFs.entries) {
        final filePath = entry.key;
        final stat = entry.value;

        if (pathsInDb.containsKey(filePath)) {
          final note = pathsInDb[filePath]!;
          // Force reindex mode or file modified
          if (forceReindex || stat.modified.isAfter(note.modifiedAt)) {
            print('[IndexerService] Updating file: $filePath');
            await _fileIndexer.updateNote(note, filePath, database);
            result.updated++;
          }
        } else {
          print('[IndexerService] Adding new file: $filePath');
          await _fileIndexer.createNote(filePath, stat, database);
          result.added++;
        }

        processedCount++;
        onProgress?.call(processedCount, totalFiles);
      }

      // Detect deleted files
      for (final path in pathsInDb.keys) {
        if (!filesInFs.containsKey(path)) {
          await noteRepository.deleteByFilePath(path);
          result.deleted++;
        }
      }

      // Clean up orphan tags
      await _tagIndexer.deleteOrphans();

      print('[IndexerService] fullScan complete - added: ${result.added}, updated: ${result.updated}, deleted: ${result.deleted}');
      return result;
    } catch (e) {
      print('[IndexerService] fullScan error: $e');
      rethrow;
    }
  }

  /// Index a single file (add or update).
  Future<Note?> indexFile(String filePath) async {
    if (!await _fileIndexer.fileExists(filePath)) {
      return null;
    }

    if (!_fileIndexer.isIndexable(filePath)) {
      return null;
    }

    final existingNote = await noteRepository.getByFilePath(filePath);
    final stat = await File(filePath).stat();

    if (existingNote != null) {
      return await _fileIndexer.updateNote(existingNote, filePath, database);
    } else {
      return await _fileIndexer.createNote(filePath, stat, database);
    }
  }

  /// Remove file index.
  Future<void> removeIndex(String filePath) async {
    // Delete from notes table
    await noteRepository.deleteByFilePath(filePath);

    // Delete from note_documents table (this cascades to tasks, note_chunks, note_references)
    if (_documentService != null) {
      await _documentService!.deleteDocument(filePath);
    } else {
      // Fallback: delete directly from database if documentService is not available
      await (database.delete(database.noteDocuments)
            ..where((tbl) => tbl.filePath.equals(filePath)))
          .go();
    }

    // Clean up orphan tags
    await _tagIndexer.deleteOrphans();
  }

  /// Rename file index.
  Future<Note?> renameIndex(String oldPath, String newPath) async {
    final note = await noteRepository.getByFilePath(oldPath);
    if (note == null) {
      // If old path doesn't exist, try indexing new path
      return indexFile(newPath);
    }

    // Update file path
    final updatedNote = note.copyWith(filePath: newPath);

    // Re-read file content to update metadata
    final file = File(newPath);
    if (await file.exists()) {
      final content = await file.readAsString();
      final withTitle = updatedNote.copyWith(
        title: FileUtils.extractTitleFromContent(content),
        preview: FileUtils.extractPreviewFromContent(content),
        modifiedAt: DateTime.now(),
      );

      // Update tags
      await _tagIndexer.updateNoteTags(withTitle, content);

      // Save note
      await noteRepository.put(withTitle);
      return withTitle;
    }

    await noteRepository.put(updatedNote);
    return updatedNote;
  }
}
