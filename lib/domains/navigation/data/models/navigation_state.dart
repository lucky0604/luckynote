/// 导航视图类型
enum NavigationViewType {
  /// 文件夹树形视图
  tree,

  /// 笔记平铺列表
  list,
}

/// 筛选类型
enum NavigationFilterType {
  /// 所有笔记
  all,

  /// 已置顶
  favorites,

  /// 特定标签
  tag,

  /// 文件夹根视图
  folderRoot,

  /// 特定文件夹
  folderPath,

  /// 任务视图
  tasks,
}

/// 导航状态
///
/// 管理中间栏的视图模式、筛选条件、选中状态等
class NavigationState {
  const NavigationState({
    this.viewType = NavigationViewType.list,
    this.filterType = NavigationFilterType.all,
    this.selectedTag,
    this.selectedFolder,
    this.title = '所有笔记',
    this.isLoading = false,
    this.error,
  });

  /// 当前视图类型（树形或列表）
  final NavigationViewType viewType;

  /// 当前筛选类型
  final NavigationFilterType filterType;

  /// 选中的标签名称（当filterType == tag时使用）
  final String? selectedTag;

  /// 选中的文件夹路径（当filterType == folderPath时使用）
  final String? selectedFolder;

  /// 显示在中间栏顶部的标题
  final String title;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  /// 判断当前是否为列表视图
  bool get isListView => viewType == NavigationViewType.list;

  /// 判断当前是否为树形视图
  bool get isTreeView => viewType == NavigationViewType.tree;

  /// 判断是否有选中的标签
  bool get hasSelectedTag => selectedTag != null && selectedTag!.isNotEmpty;

  /// 判断是否有选中的文件夹
  bool get hasSelectedFolder =>
      selectedFolder != null && selectedFolder!.isNotEmpty;

  /// 判断当前是否为任务视图
  bool get isTasksView => filterType == NavigationFilterType.tasks;

  NavigationState copyWith({
    NavigationViewType? viewType,
    NavigationFilterType? filterType,
    String? selectedTag,
    String? selectedFolder,
    String? title,
    bool? isLoading,
    String? error,
  }) {
    return NavigationState(
      viewType: viewType ?? this.viewType,
      filterType: filterType ?? this.filterType,
      selectedTag: selectedTag ?? this.selectedTag,
      selectedFolder: selectedFolder ?? this.selectedFolder,
      title: title ?? this.title,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NavigationState &&
        other.viewType == viewType &&
        other.filterType == filterType &&
        other.selectedTag == selectedTag &&
        other.selectedFolder == selectedFolder &&
        other.title == title &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      viewType,
      filterType,
      selectedTag,
      selectedFolder,
      title,
      isLoading,
      error,
    );
  }

  @override
  String toString() {
    return 'NavigationState('
        'viewType: $viewType, '
        'filterType: $filterType, '
        'selectedTag: $selectedTag, '
        'selectedFolder: $selectedFolder, '
        'title: $title, '
        'isLoading: $isLoading, '
        'error: $error)';
  }
}
