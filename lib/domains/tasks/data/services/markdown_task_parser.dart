import '../../../../database/database.dart';

/// Markdown 任务解析器
/// 用于解析和格式化 Markdown 中的任务列表项
class MarkdownTaskParser {
  static final taskRegex = RegExp(
    r'^(\s*)[-*+]\s\[([ xX])\]\s+(.*)$',
    multiLine: true,
  );

  /// 解析 Markdown 内容中的任务列表
  static List<Task> parse(String content, int documentId) {
    final tasks = <Task>[];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final match = taskRegex.firstMatch(lines[i]);
      if (match != null) {
        final statusChar = match.group(2)!;
        tasks.add(Task(
          id: 0,
          documentId: documentId,
          content: match.group(3)!.trim(),
          isCompleted: statusChar.toLowerCase() == 'x',
          rawLine: lines[i],
          lineNumber: i + 1,
          createdAt: DateTime.now(),
        ));
      }
    }
    return tasks;
  }

  /// 格式化任务行，更新完成状态
  static String formatTaskLine(String rawLine, bool isCompleted) {
    final match = taskRegex.firstMatch(rawLine);
    if (match == null) return rawLine;
    final indent = match.group(1) ?? '';
    final marker = rawLine.trim().startsWith('*') ? '*' :
                  rawLine.trim().startsWith('+') ? '+' : '-';
    final content = match.group(3) ?? '';
    final checkbox = isCompleted ? '[x]' : '[ ]';
    return '$indent$marker $checkbox $content';
  }

  /// 判断是否为任务行
  static bool isTaskLine(String line) => taskRegex.hasMatch(line);

  /// 提取任务内容
  static String extractContent(String rawLine) {
    final match = taskRegex.firstMatch(rawLine);
    return match?.group(3)?.trim() ?? rawLine;
  }
}
