import 'dart:io';
import '../repositories/task_repository.dart';
import '../../../../database/database.dart';
import 'markdown_task_parser.dart';

/// 任务操作服务
/// 处理任务状态切换等操作，包括更新源文件
class TaskActionService {
  TaskActionService({
    required this.taskRepository,
  });

  final TaskRepository taskRepository;

  /// 切换任务状态并同步更新源文件
  Future<bool> toggleTaskStatus(int taskId, AppDatabase database) async {
    try {
      final task = await (database.select(database.tasks)
        ..where((t) => t.id.equals(taskId))
      ).getSingleOrNull();

      if (task == null) return false;

      final document = await (database.select(database.noteDocuments)
        ..where((d) => d.id.equals(task.documentId))
      ).getSingleOrNull();

      if (document == null) return false;

      final file = File(document.filePath);
      if (!await file.exists()) return false;

      final lines = await file.readAsLines();
      bool found = false;

      for (int i = 0; i < lines.length; i++) {
        if (lines[i] == task.rawLine) {
          lines[i] = MarkdownTaskParser.formatTaskLine(lines[i], !task.isCompleted);
          found = true;
          break;
        } else if (MarkdownTaskParser.isTaskLine(lines[i])) {
          if (MarkdownTaskParser.extractContent(lines[i]) == task.content) {
            lines[i] = MarkdownTaskParser.formatTaskLine(lines[i], !task.isCompleted);
            found = true;
            break;
          }
        }
      }

      if (!found) return false;

      await file.writeAsString(lines.join('\n'));
      await taskRepository.toggleTaskStatus(taskId);
      return true;
    } catch (e) {
      print('[TaskActionService] Error: $e');
      return false;
    }
  }
}
