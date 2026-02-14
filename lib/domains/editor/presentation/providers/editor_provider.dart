import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:super_editor/super_editor.dart';

import '../../../../core/utils/file_utils.dart';
import '../../../../database/database.dart';
import '../../../notes/data/services/file_watcher_service.dart';
import '../../data/markdown/markdown_serializer.dart';
import '../../../shared_infra/providers/database_provider.dart';
import '../../../notes/presentation/providers/file_watcher_provider.dart';
import '../../../notes/presentation/providers/tags_provider.dart';
import 'editor_state.dart';
import 'editor_undo_stack.dart';
import 'task_index_scheduler.dart';

/// Markdown serializer Provider
final markdownSerializerProvider = Provider<MarkdownSerializer>((ref) {
  return MarkdownSerializer();
});

/// 撤销重做状态 Provider
final editorUndoStateProvider = Provider<EditorUndoState>((ref) {
  return ref.watch(editorProvider.notifier).undoStack.state;
});

/// Editor state manager.
class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier(this._ref) : super(const EditorState()) {
    _taskScheduler = TaskIndexScheduler(
      ref: _ref,
      onStateUpdate: (newState) => state = newState,
    );
    _listenToExternalFileChanges();
  }

  final Ref _ref;
  late final TaskIndexScheduler _taskScheduler;
  
  /// 撤销重做栈
  final EditorUndoStack undoStack = EditorUndoStack();
  
  /// 标记是否正在进行撤销/重做操作
  bool _isUndoingOrRedoing = false;

  /// Last saved content hash to detect external changes
  String? _lastSavedContentHash;

  /// Open a note for editing.
  Future<void> openNote(Note note) async {
    // If there are unsaved changes, save them first
    if (state.isDirty && state.currentNote != null) {
      await saveCurrentNote();
    }

    try {
      final file = File(note.filePath);
      final content = await file.readAsString();
      _taskScheduler.updateSignature(content);

      final serializer = _ref.read(markdownSerializerProvider);
      final document = serializer.deserialize(content);

      state = EditorState(
        currentNote: note,
        document: document,
        rawMarkdown: content,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(error: '打开笔记失败: $e');
    }
  }

  /// Close the current note.
  Future<void> closeNote() async {
    if (state.isDirty && state.currentNote != null) {
      await saveCurrentNote();
    }

    state = const EditorState();
    _taskScheduler.clearSignature();
  }

  /// Mark the document as modified.
  void markDirty() {
    // 如果正在进行撤销/重做，不记录快照
    if (!_isUndoingOrRedoing) {
      // 保存当前状态到撤销栈
      undoStack.push(
        rawMarkdown: state.rawMarkdown,
        viewMode: state.viewMode,
        scrollRatio: state.scrollRatio,
      );
    }
    
    if (!state.isDirty) {
      state = state.copyWith(isDirty: true);
    }
    _scheduleTaskReindex();
  }

  /// 撤销操作
  bool undo() {
    if (!undoStack.canUndo) return false;
    
    final currentContent = _getCurrentEditorContent();
    if (currentContent == null) return false;
    
    _isUndoingOrRedoing = true;
    
    final snapshot = undoStack.undo(currentContent);
    if (snapshot != null) {
      // 恢复状态
      state = state.copyWith(
        rawMarkdown: snapshot.rawMarkdown,
        viewMode: snapshot.viewMode,
        isDirty: true,
      );
    }
    
    _isUndoingOrRedoing = false;
    return true;
  }

  /// 重做操作
  bool redo() {
    if (!undoStack.canRedo) return false;
    
    final currentContent = _getCurrentEditorContent();
    if (currentContent == null) return false;
    
    _isUndoingOrRedoing = true;
    
    final snapshot = undoStack.redo(currentContent);
    if (snapshot != null) {
      // 恢复状态
      state = state.copyWith(
        rawMarkdown: snapshot.rawMarkdown,
        viewMode: snapshot.viewMode,
        isDirty: true,
      );
    }
    
    _isUndoingOrRedoing = false;
    return true;
  }

  /// Save the current note.
  Future<void> saveCurrentNote() async {
    final note = state.currentNote;
    if (note == null) return;

    state = state.copyWith(isSaving: true);

    try {
      // Get content based on view mode
      String content;
      if (state.viewMode == EditorViewMode.source) {
        content = state.rawMarkdown;
      } else {
        final document = state.document;
        if (document == null) {
          state = state.copyWith(isSaving: false);
          return;
        }
        final serializer = _ref.read(markdownSerializerProvider);
        content = serializer.serialize(document);
      }

      final newTitle = FileUtils.extractTitleFromContent(content);
      final oldTitle = note.title;

      // If title changed, need to rename file
      Note updatedNote = note;
      String filePath = note.filePath;
      if (newTitle != oldTitle) {
        final directory = p.dirname(note.filePath);
        final newFileName = FileUtils.generateNoteFileName(newTitle);
        final newPath = p.join(directory, newFileName);

        final file = File(note.filePath);
        if (await file.exists()) {
          await file.rename(newPath);
        }

        updatedNote = updatedNote.copyWith(
          filePath: newPath,
          title: newTitle,
        );
        filePath = newPath;

        // 标题变更时失效缓存
        _ref.read(associationServiceProvider).invalidateCache();
      }

      // Save content to file
      final file = File(filePath);
      await file.writeAsString(content);

      // Update metadata in database
      final noteRepo = _ref.read(noteRepositoryProvider);
      updatedNote = updatedNote.copyWith(
        preview: FileUtils.extractPreviewFromContent(content),
        modifiedAt: DateTime.now(),
      );
      await noteRepo.put(updatedNote);

      // Update WikiLink references
      final docService = _ref.read(documentServiceProvider);
      final noteDoc = await docService.getOrCreateDocument(
        filePath,
        updatedNote.title,
        File(filePath).lastModifiedSync(),
      );

      final wikiLinkRepo = _ref.read(wikiLinkRepositoryProvider);
      await wikiLinkRepo.updateReferences(noteDoc.id, content);

      // Refresh tags
      await _ref.read(tagsProvider.notifier).loadTags();

      // Trigger file change event
      _ref.read(fileWatcherProvider.notifier).state = _ref
          .read(fileWatcherProvider)
          .copyWith(
            lastEvent: FileChangeEvent(
              type: FileChangeType.modified,
              path: filePath,
            ),
          );

      // Remember saved content hash to avoid unnecessary reload
      _lastSavedContentHash = content.hashCode.toString();

      state = state.copyWith(
        currentNote: updatedNote,
        rawMarkdown: content,
        isDirty: false,
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '保存失败: $e');
    }
  }

  /// Update the document content.
  void updateDocument(MutableDocument document) {
    state = state.copyWith(document: document, isDirty: true);
    _scheduleTaskReindex();
  }

  /// Clear error.
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Open a note by file path.
  Future<void> openNoteByPath(String filePath) async {
    final noteRepo = _ref.read(noteRepositoryProvider);
    final note = await noteRepo.getByFilePath(filePath);
    if (note != null) {
      await openNote(note);
    }
  }

  /// Toggle view mode (source <-> preview).
  /// scrollRatio: 切换前的滚动比例 (0.0 ~ 1.0)，用于模式切换后同步滚动位置
  Future<void> toggleViewMode({double scrollRatio = 0.0}) async {
    if (state.currentNote == null) return;

    final newMode = state.viewMode == EditorViewMode.source
        ? EditorViewMode.preview
        : EditorViewMode.source;

    if (newMode == EditorViewMode.source) {
      final serializer = _ref.read(markdownSerializerProvider);
      final markdown = state.document != null
          ? serializer.serialize(state.document!)
          : state.rawMarkdown;
      state = state.copyWith(
        viewMode: newMode,
        rawMarkdown: markdown,
        scrollRatio: scrollRatio,
      );
    } else {
      final serializer = _ref.read(markdownSerializerProvider);
      final document = serializer.deserialize(state.rawMarkdown);
      state = state.copyWith(
        viewMode: newMode,
        document: document,
        scrollRatio: scrollRatio,
      );
    }
  }

  /// 更新滚动比例
  void updateScrollRatio(double ratio) {
    state = state.copyWith(scrollRatio: ratio);
  }

  /// Update raw Markdown in source mode.
  void updateRawMarkdown(String markdown) {
    state = state.copyWith(rawMarkdown: markdown, isDirty: true);
    _scheduleTaskReindex();
  }

  /// Convert selected text to WikiLink.
  void convertToWikiLink({
    required int startIndex,
    required int endIndex,
    required String targetTitle,
  }) {
    final currentContent = _getCurrentEditorContent();
    if (currentContent == null) return;

    if (startIndex < 0 || endIndex > currentContent.length || startIndex >= endIndex) {
      state = state.copyWith(error: '无效的位置范围');
      return;
    }

    final wikiLink = '[[$targetTitle]]';
    final newContent = currentContent.substring(0, startIndex) +
        wikiLink +
        currentContent.substring(endIndex);

    if (state.viewMode == EditorViewMode.source) {
      state = state.copyWith(rawMarkdown: newContent, isDirty: true);
    } else {
      final serializer = _ref.read(markdownSerializerProvider);
      final document = serializer.deserialize(newContent);
      state = state.copyWith(document: document, isDirty: true);
    }

    _scheduleTaskReindex();
  }

  void _scheduleTaskReindex() {
    final note = state.currentNote;
    if (note == null) return;
    final content = _getCurrentEditorContent();
    if (content == null) return;

    _taskScheduler.scheduleReindex(note: note, content: content);
  }

  String? _getCurrentEditorContent() {
    if (state.viewMode == EditorViewMode.source) {
      return state.rawMarkdown;
    }

    final document = state.document;
    if (document == null) return null;

    final serializer = _ref.read(markdownSerializerProvider);
    return serializer.serialize(document);
  }

  void _listenToExternalFileChanges() {
    _ref.listen<FileWatcherState>(fileWatcherProvider, (previous, next) {
      final event = next.lastEvent;
      final note = state.currentNote;
      if (event == null || note == null) return;

      if (event.type == FileChangeType.modified &&
          p.normalize(event.path) == p.normalize(note.filePath)) {
        _checkAndReloadIfExternalChange();
      }
    });
  }

  /// Check if file content actually changed externally before reloading
  Future<void> _checkAndReloadIfExternalChange() async {
    final note = state.currentNote;
    if (note == null) return;

    try {
      final file = File(note.filePath);
      if (!await file.exists()) return;

      final diskContent = await file.readAsString();
      final diskContentHash = diskContent.hashCode.toString();

      // If content hash matches last saved, it's our own save - skip reload
      if (_lastSavedContentHash == diskContentHash) {
        return;
      }

      // Content actually changed externally
      _reloadCurrentNoteFromDisk();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _reloadCurrentNoteFromDisk() async {
    final note = state.currentNote;
    if (note == null) return;

    if (state.isDirty) {
      state = state.copyWith(error: '当前笔记在外部被修改，请先保存或放弃本地更改');
      return;
    }

    try {
      final file = File(note.filePath);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      _taskScheduler.updateSignature(content);
      final serializer = _ref.read(markdownSerializerProvider);
      final document = serializer.deserialize(content);

      state = state.copyWith(
        document: document,
        rawMarkdown: content,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(error: '重新加载失败: $e');
    }
  }

  @override
  void dispose() {
    undoStack.clear();
    _taskScheduler.dispose();
    super.dispose();
  }
}

/// Editor Provider
final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) {
    return EditorNotifier(ref);
  },
);

/// Current note Provider (convenience access)
final currentNoteProvider = Provider<Note?>((ref) {
  return ref.watch(editorProvider).currentNote;
});

/// Editor document Provider (convenience access)
final editorDocumentProvider = Provider<MutableDocument?>((ref) {
  return ref.watch(editorProvider).document;
});

/// Is dirty Provider (convenience access)
final isDirtyProvider = Provider<bool>((ref) {
  return ref.watch(editorProvider).isDirty;
});
