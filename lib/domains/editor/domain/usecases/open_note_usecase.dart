import 'package:super_editor/super_editor.dart';
import '../../../../database/database.dart';
import '../../data/markdown/markdown_serializer.dart';
import '../../data/services/note_file_service.dart';

/// 打开笔记用例的结果
class OpenNoteResult {
  OpenNoteResult({
    required this.document,
    required this.rawMarkdown,
  });

  final MutableDocument document;
  final String rawMarkdown;
}

/// 打开笔记用例
class OpenNoteUseCase {
  OpenNoteUseCase({
    required this.noteFileService,
    required this.markdownSerializer,
  });

  final NoteFileService noteFileService;
  final MarkdownSerializer markdownSerializer;

  /// 执行打开笔记操作
  Future<OpenNoteResult> execute(Note note) async {
    final content = await noteFileService.readNoteContent(note.filePath);
    final document = markdownSerializer.deserialize(content);

    return OpenNoteResult(
      document: document,
      rawMarkdown: content,
    );
  }
}
