import 'package:drift/drift.dart';
import '../../../../database/database.dart';
import '../services/markdown_task_parser.dart';

class TaskRepository {
  TaskRepository(this._database);

  final AppDatabase _database;

  Future<List<Task>> getTasksByDocumentId(int documentId) async {
    return await (_database.select(_database.tasks)
      ..where((t) => t.documentId.equals(documentId))
      ..orderBy([(t) => OrderingTerm.asc(t.lineNumber)])
    ).get();
  }

  Future<List<TaskWithDocument>> getAllPendingTasks() async {
    return await _database.getAllPendingTasks();
  }

  /// 监听未完成任务的变化
  Stream<List<TaskWithDocument>> watchPendingTasks() {
    return _database.watchPendingTasks();
  }

  /// 监听所有任务（含筛选）
  /// [filter] 为 null 表示全部，true 表示已完成，false 表示未完成
  Stream<List<TaskWithDocument>> watchAllTasks({bool? filter}) {
    return _database.watchAllTasks(filter: filter);
  }

  /// 获取所有任务（含筛选）
  Future<List<TaskWithDocument>> getAllTasks({bool? filter}) async {
    return await _database.getAllTasks(filter: filter);
  }

  Future<void> reindexTasks(int documentId, String content) async {
    final parsedTasks = MarkdownTaskParser.parse(content, documentId);
    print('[TaskRepository] Parsed ${parsedTasks.length} tasks for document $documentId');
    for (final task in parsedTasks) {
      print('  - [${task.isCompleted ? "x" : " "}] ${task.content} (line ${task.lineNumber})');
    }
    final existingTasks = await getTasksByDocumentId(documentId);
    final existingByKey = {
      for (final task in existingTasks) _taskKey(task): task,
    };
    final parsedByKey = {
      for (final task in parsedTasks) _taskKey(task): task,
    };

    final tasksToInsert = <Task>[];
    final tasksToUpdate = <Task>[];
    final taskIdsToDelete = <int>[];

    for (final task in parsedTasks) {
      final key = _taskKey(task);
      final existing = existingByKey[key];
      if (existing == null) {
        tasksToInsert.add(task);
        continue;
      }

      if (existing.isCompleted != task.isCompleted ||
          existing.rawLine != task.rawLine ||
          existing.lineNumber != task.lineNumber ||
          existing.content != task.content) {
        tasksToUpdate.add(existing.copyWith(
          content: task.content,
          isCompleted: task.isCompleted,
          rawLine: task.rawLine,
          lineNumber: task.lineNumber,
        ));
      }
    }

    for (final task in existingTasks) {
      final key = _taskKey(task);
      if (!parsedByKey.containsKey(key)) {
        taskIdsToDelete.add(task.id);
      }
    }

    await _database.transaction(() async {
      if (taskIdsToDelete.isNotEmpty) {
        await (_database.delete(_database.tasks)
              ..where((t) => t.id.isIn(taskIdsToDelete)))
            .go();
      }
      for (final task in tasksToUpdate) {
        await _database.update(_database.tasks).replace(task);
      }
      if (tasksToInsert.isNotEmpty) {
        await _database.insertTasksList(tasksToInsert);
      }
    });
    print('[TaskRepository] Reindex completed for document $documentId');
  }

  Future<Task> toggleTaskStatus(int taskId) async {
    final task = await (_database.select(_database.tasks)
      ..where((t) => t.id.equals(taskId))
    ).getSingle();
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _database.update(_database.tasks).replace(updated);
    return updated;
  }

  Future<void> deleteByDocumentId(int documentId) async {
    await _database.deleteTasksByDocumentId(documentId);
  }
}

String _taskKey(Task task) => '${task.lineNumber}|${task.content}';
