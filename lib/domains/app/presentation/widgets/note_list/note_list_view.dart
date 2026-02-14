import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/navigation/data/models/navigation_state.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'package:luckynote/domains/navigation/presentation/providers/navigation_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';
import 'note_list_content.dart';
import 'note_list_empty.dart';
import 'note_list_error.dart';
import 'note_list_loading.dart';

/// 笔记列表主视图
///
/// 根据不同的筛选条件显示笔记列表：
/// - 所有笔记
/// - 已置顶（Favorites）
/// - 特定标签
/// - 特定文件夹
class NoteListView extends ConsumerWidget {
  const NoteListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(notesProvider);
    final editorState = ref.watch(editorProvider);
    final navState = ref.watch(navigationProvider);

    // 树形视图模式（文件夹根），不显示笔记列表
    if (navState.filterType == NavigationFilterType.folderRoot) {
      return const SizedBox.shrink();
    }

    // 加载中
    if (notesState.isLoading) {
      return const NoteListLoading();
    }

    // 错误状态
    if (notesState.error != null) {
      return NoteListError(message: notesState.error!);
    }

    // 空列表
    if (notesState.notes.isEmpty) {
      return NoteListEmpty(navState: navState);
    }

    // 渲染笔记列表
    return NoteListContent(
      notes: notesState.notes,
      currentNoteId: editorState.currentNote?.id,
    );
  }
}
