import 'package:super_editor/super_editor.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../database/database.dart';
import '../../data/markdown/markdown_serializer.dart';
import '../../../notes/data/repositories/note_repository.dart';
import '../../../rag/data/services/document_service.dart';
import '../../../association/data/repositories/wikilink_repository.dart';
import '../../data/services/note_file_service.dart';

/// 保存笔记用例的结果
class SaveNoteResult {
  SaveNoteResult({
    required this.updatedNote,
    required this.content,
    required this.filePath,
  });

  final Note updatedNote;
  final String content;
  final String filePath;
}

/// 保存笔记用例
class SaveNoteUseCase {
  SaveNoteUseCase({
    required this.noteFileService,
    required this.markdownSerializer,
    required this.noteRepository,
    required this.documentService,
    required this.wikiLinkRepository,
  });

  final NoteFileService noteFileService;
  final MarkdownSerializer markdownSerializer;
  final NoteRepository noteRepository;
  final DocumentService documentService;
  final WikiLinkRepository wikiLinkRepository;

  /// 执行保存笔记操作
  Future<SaveNoteResult> execute({
    required Note note,
    required MutableDocument? document,
    required String rawMarkdown,
    required bool isSourceMode,
  }) async {
    // Get content based on view mode
    String content;
    if (isSourceMode) {
      content = rawMarkdown;
    } else {
      if (document == null) {
        throw Exception('Document is null');
      }
      content = markdownSerializer.serialize(document);
    }

    final newTitle = FileUtils.extractTitleFromContent(content);
    Note updatedNote = note;
    String filePath = note.filePath;

    // If title changed, rename file
    final newPath = await noteFileService.renameNoteIfTitleChanged(
      note: note,
      newTitle: newTitle,
    );
    if (newPath != null) {
      updatedNote = updatedNote.copyWith(
        filePath: newPath,
        title: newTitle,
      );
      filePath = newPath;
    }

    // Save content to file
    await noteFileService.saveNoteContent(filePath, content);

    // Update metadata in database
    updatedNote = updatedNote.copyWith(
      preview: FileUtils.extractPreviewFromContent(content),
      modifiedAt: DateTime.now(),
    );
    await noteRepository.put(updatedNote);

    // Update WikiLink references
    final noteDoc = await documentService.getOrCreateDocument(
      filePath,
      updatedNote.title,
      noteFileService.getLastModified(filePath),
    );
    await wikiLinkRepository.updateReferences(noteDoc.id, content);

    return SaveNoteResult(
      updatedNote: updatedNote,
      content: content,
      filePath: filePath,
    );
  }
}
