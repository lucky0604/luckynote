import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/file_utils.dart';
import '../../data/repositories/note_repository.dart';
import '../../../navigation/data/models/navigation_state.dart';
import '../../../../database/database.dart';
import '../../../shared_infra/providers/database_provider.dart';
import '../../../editor/presentation/providers/editor_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import 'file_watcher_provider.dart';
import 'tags_provider.dart';
import 'vault_provider.dart';


/// 笔记列表状态
class NotesState {
  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.sortType = NoteSortType.modifiedAt,
    this.sortAscending = false,
    this.folderFilter,
  });

  final List<Note> notes;
  final bool isLoading;
  final String? error;
  final NoteSortType sortType;
  final bool sortAscending;
  final String? folderFilter;

  NotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? error,
    NoteSortType? sortType,
    bool? sortAscending,
    String? folderFilter,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sortType: sortType ?? this.sortType,
      sortAscending: sortAscending ?? this.sortAscending,
      folderFilter: folderFilter ?? this.folderFilter,
    );
  }
}

/// 笔记列表状态管理
class NotesNotifier extends StateNotifier<NotesState> {
  NotesNotifier(this._ref) : super(const NotesState());

  final Ref _ref;

  NoteRepository get _noteRepo => _ref.read(noteRepositoryProvider);

  /// 加载笔记列表
  Future<void> loadNotes() async {
    print('[NotesProvider] loadNotes 开始');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final navState = _ref.read(navigationProvider);
      final selectedTag = _ref.read(selectedTagProvider);
      final folderFilter = _ref.read(selectedFolderProvider);

      print(
        '[NotesProvider] 筛选类型: ${navState.filterType}, 标签: $selectedTag, 文件夹: $folderFilter',
      );

      // 根据筛选类型决定加载逻辑
      List<Note> notes;

      switch (navState.filterType) {
        case NavigationFilterType.favorites:
          // 只加载已置顶的笔记
          notes = await _noteRepo.getAllSorted(
            sortType: state.sortType,
            ascending: state.sortAscending,
          );
          notes = notes.where((n) => n.isPinned).toList();
          break;

        case NavigationFilterType.folderRoot:
        case NavigationFilterType.tasks:
          // 树形视图模式或任务视图，不加载笔记列表
          notes = [];
          break;

        case NavigationFilterType.all:
        case NavigationFilterType.tag:
        case NavigationFilterType.folderPath:
          // 使用标签和文件夹过滤
          notes = await _noteRepo.getAllSorted(
            sortType: state.sortType,
            ascending: state.sortAscending,
            tagFilter: selectedTag,
            folderFilter: folderFilter,
          );
          break;
      }

      print('[NotesProvider] 从数据库加载了 ${notes.length} 条笔记');
      if (notes.isNotEmpty) {
        print(
          '[NotesProvider] 笔记列表: ${notes.map((n) => '${n.title} (${n.filePath})').toList()}',
        );
      }
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      print('[NotesProvider] 加载失败: $e');
      state = state.copyWith(isLoading: false, error: '加载笔记失败: $e');
    }
  }

  /// 刷新笔记列表
  Future<void> refresh() => loadNotes();

  /// 创建新笔记
  /// [title] 笔记标题，默认为 "新建笔记"
  /// [folderPath] 目标文件夹路径，默认为仓库根目录
  Future<Note?> createNote({String? title, String? folderPath}) async {
    final vaultPath = _ref
        .read(vaultProvider)
        .maybeWhen(data: (path) => path, orElse: () => null);

    if (vaultPath == null) {
      return null;
    }

    try {
      final noteTitle = title ?? AppConstants.newNoteTitle;
      final fileName = FileUtils.generateNoteFileName(noteTitle);
      // 使用指定的文件夹路径，如果没有则使用仓库根目录
      final targetFolder = folderPath ?? vaultPath;
      final filePath = p.join(targetFolder, fileName);

      final initialContent = '# $noteTitle\n\n';

      // 写入文件
      final file = File(filePath);
      await file.writeAsString(initialContent);

      // 使用索引服务创建数据库记录（确保和文件系统同步）
      final indexer = _ref.read(indexerServiceProvider);
      final note = await indexer.indexFile(filePath);

      // 失效标题缓存，确保新标题能被检测
      _ref.read(associationServiceProvider).invalidateCache();

      // 刷新列表
      await loadNotes();

      return note;
    } catch (e) {
      state = state.copyWith(error: '创建笔记失败: $e');
      return null;
    }
  }

  /// 删除笔记
  Future<void> deleteNote(int noteId) async {
    try {
      final note = await _noteRepo.getById(noteId);
      if (note != null) {
        // 检查是否是当前编辑器打开的笔记
        final currentNote = _ref.read(editorProvider).currentNote;
        if (currentNote != null && currentNote.id == noteId) {
          // 关闭编辑器
          await _ref.read(editorProvider.notifier).closeNote();
        }

        // 删除文件
        final file = File(note.filePath);
        if (await file.exists()) {
          await file.delete();
        }

        // 从数据库删除
        await _noteRepo.delete(noteId);

        // 失效标题缓存
        _ref.read(associationServiceProvider).invalidateCache();

        // 刷新标签
        _ref.read(tagsProvider.notifier).refresh();
      }

      await loadNotes();
    } catch (e) {
      state = state.copyWith(error: '删除笔记失败: $e');
    }
  }

  /// 切换笔记置顶状态
  Future<void> togglePin(int noteId) async {
    try {
      _noteRepo.togglePin(noteId);
      await loadNotes();
    } catch (e) {
      state = state.copyWith(error: '操作失败: $e');
    }
  }

  /// 重命名笔记
  Future<Note?> renameNote(int noteId, String newTitle) async {
    try {
      final note = await _noteRepo.getById(noteId);
      if (note == null) return null;

      final oldPath = note.filePath;
      final directory = p.dirname(oldPath);
      final newFileName = FileUtils.generateNoteFileName(newTitle);
      final newPath = p.join(directory, newFileName);

      // 重命名文件
      final file = File(oldPath);
      if (await file.exists()) {
        await file.rename(newPath);
      }

      // 使用索引服务更新数据库（确保和文件系统同步）
      final indexer = _ref.read(indexerServiceProvider);
      final updatedNote = await indexer.renameIndex(oldPath, newPath);

      // 失效标题缓存
      _ref.read(associationServiceProvider).invalidateCache();

      await loadNotes();

      return updatedNote;
    } catch (e) {
      state = state.copyWith(error: '重命名失败: $e');
      return null;
    }
  }

  /// 设置排序方式
  void setSortType(NoteSortType sortType) {
    if (state.sortType != sortType) {
      state = state.copyWith(sortType: sortType);
      loadNotes();
    }
  }

  /// 切换排序方向
  void toggleSortDirection() {
    state = state.copyWith(sortAscending: !state.sortAscending);
    loadNotes();
  }

  /// 搜索笔记
  List<Note> search(String query) {
    if (query.isEmpty) {
      return state.notes;
    }
    // 从当前已加载的笔记中筛选（简单搜索）
    final lowerQuery = query.toLowerCase();
    return state.notes
        .where(
          (note) =>
              note.title.toLowerCase().contains(lowerQuery) ||
              note.preview.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }
}

/// 笔记列表 Provider
final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final notifier = NotesNotifier(ref);

  // 当数据库准备好后加载笔记
  ref.listen(databaseProvider, (previous, next) async {
    final db = await next;
    // 清理孤儿数据（已删除文件的任务和文档）
    try {
      final deleted = await db.deleteAllOrphanData();
      if (deleted['tasks']! > 0 || deleted['documents']! > 0) {
        print('[NotesProvider] 清理孤儿数据: ${deleted['tasks']} 个任务, ${deleted['documents']} 个文档');
      }
    } catch (e) {
      print('[NotesProvider] 清理孤儿数据失败: $e');
    }
    notifier.loadNotes();
  });

  // 当导航状态变化时，重新加载笔记
  ref.listen(navigationProvider, (previous, next) {
    if (previous == null || previous.filterType != next.filterType) {
      notifier.loadNotes();
    }
  });

  // 当选中的标签变化时，重新加载
  ref.listen(selectedTagProvider, (previous, next) {
    if (previous != next) {
      notifier.loadNotes();
    }
  });

  // 当文件变化时，重新加载笔记
  ref.listen(fileWatcherProvider, (previous, next) {
    if (next.lastEvent != null) {
      notifier.loadNotes();
    }
  });

  // 当选中的文件夹变化时，重新加载笔记
  ref.listen(selectedFolderProvider, (previous, next) {
    if (previous != next) {
      notifier.loadNotes();
    }
  });

  return notifier;
});

/// 笔记数量 Provider (受筛选条件影响)
final notesCountProvider = Provider<int>((ref) {
  return ref.watch(notesProvider).notes.length;
});

/// 全部笔记总数 Provider (不受筛选条件影响)
final allNotesCountProvider = FutureProvider<int>((ref) async {
  // 监听文件变化以刷新计数
  ref.watch(fileWatcherProvider);
  final noteRepo = ref.watch(noteRepositoryProvider);
  return await noteRepo.count();
});

/// 当前排序方式 Provider
final noteSortTypeProvider = Provider<NoteSortType>((ref) {
  return ref.watch(notesProvider).sortType;
});

/// 排序方向 Provider
final noteSortAscendingProvider = Provider<bool>((ref) {
  return ref.watch(notesProvider).sortAscending;
});
