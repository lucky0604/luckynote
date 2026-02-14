import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/navigation_state.dart';
import '../../../notes/presentation/providers/tags_provider.dart';
import '../../../notes/presentation/providers/file_tree_provider.dart';

/// 导航状态管理器
///
/// 负责管理中间栏的视图模式、筛选条件、标题等状态
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier(this._ref) : super(const NavigationState());

  final Ref _ref;

  /// 切换到所有笔记视图
  void switchToAllNotes() {
    state = state.copyWith(
      viewType: NavigationViewType.list,
      filterType: NavigationFilterType.all,
      selectedTag: null,
      selectedFolder: null,
      title: '所有笔记',
    );

    // 清除标签选择
    _ref.read(tagsProvider.notifier).clearSelection();
  }

  /// 切换到已置顶视图
  void switchToFavorites() {
    state = state.copyWith(
      viewType: NavigationViewType.list,
      filterType: NavigationFilterType.favorites,
      selectedTag: null,
      selectedFolder: null,
      title: '已置顶',
    );

    // 清除标签选择
    _ref.read(tagsProvider.notifier).clearSelection();
  }

  /// 切换到标签视图
  ///
  /// [tagName] 标签名称（不含#）
  void switchToTag(String tagName) {
    state = state.copyWith(
      viewType: NavigationViewType.list,
      filterType: NavigationFilterType.tag,
      selectedTag: tagName,
      selectedFolder: null,
      title: '#$tagName',
    );

    // 通知tagsProvider选中标签
    _ref.read(tagsProvider.notifier).selectTag(tagName);
  }

  /// 切换到文件夹树形视图
  void switchToFolderTree() {
    state = state.copyWith(
      viewType: NavigationViewType.tree,
      filterType: NavigationFilterType.folderRoot,
      selectedTag: null,
      selectedFolder: null,
      title: 'Folders',
    );

    // 清除标签选择
    _ref.read(tagsProvider.notifier).clearSelection();
  }

  /// 切换到任务视图
  void switchToTasks() {
    state = state.copyWith(
      viewType: NavigationViewType.list,
      filterType: NavigationFilterType.tasks,
      selectedTag: null,
      selectedFolder: null,
      title: '任务',
    );

    // 清除标签选择
    _ref.read(tagsProvider.notifier).clearSelection();
  }

  /// 切换到特定文件夹路径
  ///
  /// [folderPath] 文件夹绝对路径
  /// [folderName] 文件夹名称（用于显示标题）
  void switchToFolder(String folderPath, String folderName) {
    state = state.copyWith(
      viewType: NavigationViewType.list,
      filterType: NavigationFilterType.folderPath,
      selectedTag: null,
      selectedFolder: folderPath,
      title: folderName,
    );

    // 清除标签选择
    _ref.read(tagsProvider.notifier).clearSelection();

    // 通知file_tree_provider选中文件夹
    _ref.read(fileTreeProvider.notifier).selectNode(folderPath);
  }

  /// 清除所有筛选条件，返回默认状态
  void reset() {
    switchToAllNotes();
  }

  /// 设置加载状态
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// 设置错误信息
  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

/// 导航Provider
///
/// 全局单例，管理中间栏的导航状态
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
      return NavigationNotifier(ref);
    });
