import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/tag_repository.dart';
import '../../../shared_infra/providers/database_provider.dart';
import 'file_watcher_provider.dart';

/// 标签列表状态
class TagsState {
  const TagsState({
    this.tags = const [],
    this.selectedTag,
    this.isLoading = false,
    this.error,
  });

  /// 所有标签（带笔记数量）
  final List<TagWithCount> tags;

  /// 当前选中的标签（用于筛选）
  final String? selectedTag;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  TagsState copyWith({
    List<TagWithCount>? tags,
    String? selectedTag,
    bool? isLoading,
    String? error,
    bool clearSelectedTag = false,
  }) {
    return TagsState(
      tags: tags ?? this.tags,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 标签状态管理器
class TagsNotifier extends StateNotifier<TagsState> {
  TagsNotifier(this._tagRepository) : super(const TagsState());

  final TagRepository _tagRepository;

  /// 加载所有标签
  Future<void> loadTags() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tags = await _tagRepository.getAllWithCount();
      state = state.copyWith(tags: tags, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载标签失败: $e');
    }
  }

  /// 刷新标签列表
  Future<void> refresh() => loadTags();

  /// 选择标签进行筛选
  void selectTag(String? tagName) {
    if (tagName == state.selectedTag) {
      // 再次点击相同标签，取消选择
      state = state.copyWith(clearSelectedTag: true);
    } else {
      state = state.copyWith(selectedTag: tagName);
    }
  }

  /// 清除选中的标签
  void clearSelection() {
    state = state.copyWith(clearSelectedTag: true);
  }
}

/// 标签 Provider
final tagsProvider = StateNotifierProvider<TagsNotifier, TagsState>((ref) {
  final tagRepo = ref.watch(tagRepositoryProvider);
  final notifier = TagsNotifier(tagRepo);

  // 当文件变化时，重新加载标签
  ref.listen(fileWatcherProvider, (previous, next) {
    if (next.lastEvent != null) {
      notifier.loadTags();
    }
  });

  return notifier;
});

/// 已选中的标签 Provider（便捷访问）
final selectedTagProvider = Provider<String?>((ref) {
  return ref.watch(tagsProvider).selectedTag;
});

/// 标签列表 Provider（便捷访问）
final tagListProvider = Provider<List<TagWithCount>>((ref) {
  return ref.watch(tagsProvider).tags;
});

/// 标签数量 Provider
final tagsCountProvider = Provider<int>((ref) {
  return ref.watch(tagsProvider).tags.length;
});

/// 带筛选的标签列表
/// 只显示有笔记的标签
final activeTagsProvider = Provider<List<TagWithCount>>((ref) {
  final tags = ref.watch(tagsProvider).tags;
  return tags.where((t) => t.noteCount > 0).toList();
});
