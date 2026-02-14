import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../../core/utils/file_utils.dart';
import '../../../../database/database.dart';

/// 笔记文件服务
/// 处理笔记文件的读写、重命名等操作
class NoteFileService {
  /// 读取笔记内容
  Future<String> readNoteContent(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }

  /// 保存笔记内容
  Future<void> saveNoteContent(String filePath, String content) async {
    final file = File(filePath);
    await file.writeAsString(content);
  }

  /// 检查文件是否存在
  Future<bool> exists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// 重命名笔记文件（当标题变化时）
  /// 返回新的文件路径
  Future<String?> renameNoteIfTitleChanged({
    required Note note,
    required String newTitle,
  }) async {
    if (newTitle == note.title) return null;

    final directory = p.dirname(note.filePath);
    final newFileName = FileUtils.generateNoteFileName(newTitle);
    final newPath = p.join(directory, newFileName);

    final file = File(note.filePath);
    if (await file.exists()) {
      await file.rename(newPath);
    }

    return newPath;
  }

  /// 获取文件最后修改时间
  DateTime getLastModified(String filePath) {
    return File(filePath).lastModifiedSync();
  }
}
