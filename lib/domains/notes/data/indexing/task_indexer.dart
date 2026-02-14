import '../../../../database/database.dart';
import 'package:luckynote/domains/tasks/data/repositories/task_repository.dart';

/// Task indexing service.
///
/// Handles parsing and indexing tasks from note content.
class TaskIndexer {
  const TaskIndexer({
    required this.taskRepository,
  });

  final TaskRepository taskRepository;

  /// Index tasks for a note.
  Future<void> indexNoteTasks(Note note, String content, AppDatabase database) async {
    try {
      final document = await (database.select(database.noteDocuments)
        ..where((d) => d.filePath.equals(note.filePath))
      ).getSingleOrNull();

      if (document == null) {
        print('[TaskIndexer] Skipped: noteDocuments entry not found for ${note.filePath}');
        return;
      }

      print('[TaskIndexer] Indexing tasks for document ${document.id}: ${note.filePath}');
      await taskRepository.reindexTasks(document.id, content);
      print('[TaskIndexer] Completed for document ${document.id}');
    } catch (e) {
      print('[TaskIndexer] Failed for ${note.filePath}: $e');
    }
  }
}
