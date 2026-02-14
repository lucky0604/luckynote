import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_context.dart';
import '../../data/models/mention_item.dart';
import '../../../../database/database.dart';
import '../../../shared_infra/providers/database_provider.dart';
import '../../../editor/presentation/providers/editor_provider.dart';
import '../../../notes/presentation/providers/tags_provider.dart';

/// 提及建议状态
class MentionState {
  const MentionState({
    this.isVisible = false,
    this.query = '',
    this.suggestions = const [],
    this.selectedIndex = 0,
    this.triggerPosition,
  });

  final bool isVisible;
  final String query;
  final List<MentionItem> suggestions;
  final int selectedIndex;
  final Offset? triggerPosition;

  MentionState copyWith({
    bool? isVisible,
    String? query,
    List<MentionItem>? suggestions,
    int? selectedIndex,
    Offset? triggerPosition,
  }) {
    return MentionState(
      isVisible: isVisible ?? this.isVisible,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      triggerPosition: triggerPosition ?? this.triggerPosition,
    );
  }
}

/// 提及建议 Notifier
class MentionNotifier extends StateNotifier<MentionState> {
  MentionNotifier(this._ref) : super(const MentionState());

  final Ref _ref;

  /// 获取当前笔记
  Note? get _currentNote {
    return _ref.read(currentNoteProvider);
  }

  /// 构建智能推荐（当前笔记、当前文件夹、全库）
  List<MentionItem> _buildSmartSuggestions() {
    final suggestions = <MentionItem>[];

    // 1. 当前笔记（优先推荐）
    final currentNote = _currentNote;
    if (currentNote != null) {
      suggestions.add(
        MentionItem.currentNote(
          filePath: currentNote.filePath,
          title: currentNote.title,
        ),
      );
    }

    // 2. 浏览文件
    suggestions.add(MentionItem.browseFiles());

    // 3. 全库检索
    suggestions.add(MentionItem.allNotes());

    return suggestions;
  }

  /// 搜索建议
  Future<List<MentionItem>> _searchSuggestions(String query) async {
    if (query.isEmpty) return [];

    final suggestions = <MentionItem>[];
    final lowercaseQuery = query.toLowerCase();

    // 搜索笔记
    try {
      final noteRepo = _ref.read(noteRepositoryProvider);
      final notes = await noteRepo.search(query);
      final limitedNotes = notes.take(5);

      for (final note in limitedNotes) {
        suggestions.add(
          MentionItem.note(
            filePath: note.filePath,
            title: note.title,
            queryMatch: query,
          ),
        );
      }
    } catch (_) {
      // 忽略搜索错误
    }

    // 搜索标签
    try {
      final tagsState = _ref.read(tagsProvider);
      final allTags = tagsState.tags;

      for (final tagWithCount in allTags) {
        if (tagWithCount.tag.name.toLowerCase().contains(lowercaseQuery)) {
          suggestions.add(
            MentionItem.tag(
              name: tagWithCount.tag.name,
              noteCount: tagWithCount.noteCount,
              queryMatch: query,
            ),
          );
          if (suggestions.length >= 10) break;
        }
      }
    } catch (_) {
      // 忽略标签搜索错误
    }

    return suggestions;
  }

  /// 触发提及建议
  Future<void> trigger(String query, Offset position) async {
    if (query.isEmpty) {
      // 显示智能推荐
      state = state.copyWith(
        isVisible: true,
        query: '',
        suggestions: _buildSmartSuggestions(),
        selectedIndex: 0,
        triggerPosition: position,
      );
      return;
    }

    // 搜索建议
    final searchResults = await _searchSuggestions(query);
    final allSuggestions = [..._buildSmartSuggestions(), ...searchResults];

    state = state.copyWith(
      isVisible: true,
      query: query,
      suggestions: allSuggestions,
      selectedIndex: 0,
      triggerPosition: position,
    );
  }

  /// 选择上一个建议
  void selectPrevious() {
    if (!state.isVisible || state.suggestions.isEmpty) return;

    final newIndex =
        (state.selectedIndex - 1 + state.suggestions.length) %
        state.suggestions.length;
    state = state.copyWith(selectedIndex: newIndex);
  }

  /// 选择下一个建议
  void selectNext() {
    if (!state.isVisible || state.suggestions.isEmpty) return;

    final newIndex = (state.selectedIndex + 1) % state.suggestions.length;
    state = state.copyWith(selectedIndex: newIndex);
  }

  /// 确认选择当前建议
  MentionItem? confirmSelection() {
    if (!state.isVisible || state.suggestions.isEmpty) return null;

    final selected = state.suggestions[state.selectedIndex];
    hide();
    return selected;
  }

  /// 将 MentionItem 转换为 ChatContext
  ChatContext? mentionToContext(MentionItem item) {
    switch (item.type) {
      case MentionType.currentNote:
      case MentionType.note:
        return ChatContext.note(
          filePath: item.id,
          title: item.displayName,
        );
      case MentionType.currentFolder:
      case MentionType.folder:
        return ChatContext.folder(
          path: item.id,
          name: item.displayName,
        );
      case MentionType.tag:
        return ChatContext.tag(name: item.id);
      case MentionType.allNotes:
        return ChatContext.all();
      case MentionType.browseFiles:
        // 浏览文件是操作，不是上下文
        return null;
    }
  }

  /// 取消并隐藏建议
  void hide() {
    state = const MentionState();
  }
}

/// 提及建议 Provider
final mentionProvider = StateNotifierProvider<MentionNotifier, MentionState>(
  (ref) {
    return MentionNotifier(ref);
  },
);

/// 提及建议是否可见 Provider
final mentionVisibleProvider = Provider<bool>((ref) {
  return ref.watch(mentionProvider).isVisible;
});

/// 提及建议列表 Provider
final mentionSuggestionsProvider = Provider<List<MentionItem>>((ref) {
  return ref.watch(mentionProvider).suggestions;
});
