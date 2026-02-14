/// 应用常量定义
abstract final class AppConstants {
  /// 应用名称
  static const String appName = 'LuckyNote';

  /// 笔记文件扩展名
  static const String noteExtension = '.md';

  /// 资源文件夹名称
  static const String assetsFolder = 'assets';

  /// 自动保存延迟时间（毫秒），2.5秒延迟避免频繁保存
  static const int autoSaveDelayMs = 2500;

  /// 文件监听防抖时间（毫秒）
  static const int fileWatcherDebounceMs = 500;

  /// 新笔记默认标题
  static const String newNoteTitle = '未命名笔记';

  /// SharedPreferences Keys
  static const String keyVaultPath = 'vault_path';

  static const String keyThemeMode = 'theme_mode';
  static const String keyEditorFontFamily = 'editor_font_family';
  static const String keyEditorFontSize = 'editor_font_size';

  static const String keySidebarWidth = 'sidebar_width';
  static const String keyNoteListWidth = 'note_list_width';
  static const String keyEditorMaxWidth = 'editor_max_width';
  static const String keyEditorFullWidth = 'editor_full_width';

  /// 编辑器默认行高
  static const double editorLineHeight = 1.6;

  /// 编辑器默认字体大小
  static const double editorFontSize = 16.0;

  /// 侧边栏宽度
  static const double sidebarWidth = 220.0;

  /// 笔记列表面板宽度
  static const double noteListPanelWidth = 280.0;

  /// 笔记列表面板最小宽度
  static const double noteListPanelMinWidth = 200.0;

  /// 侧边栏最小宽度
  static const double sidebarMinWidth = 180.0;

  /// 侧边栏最大宽度
  static const double sidebarMaxWidth = 320.0;

  /// 笔记列表面板最大宽度
  static const double noteListPanelMaxWidth = 400.0;

  /// 卡片圆角半径
  static const double cardBorderRadius = 12.0;

  /// 按钮圆角半径
  static const double buttonBorderRadius = 8.0;

  /// 编辑器最大宽度（默认）
  static const double defaultEditorMaxWidth = 850.0;

  /// 编辑器最小宽度
  static const double editorMinWidth = 300.0;

  /// 响应式断点（窗口宽度小于此值时使用移动端边距）
  static const double responsiveBreakpoint = 900.0;

  /// 移动端编辑器边距
  static const double mobilePadding = 24.0;

  /// 编辑器水平内边距（源码/预览模式统一）
  static const double editorHorizontalPadding = 24.0;

  /// 编辑器垂直内边距（源码/预览模式统一）
  static const double editorVerticalPadding = 32.0;

  /// 源码模式字体（等宽字体）
  static const String sourceModeFontFamily = 'JetBrains Mono';

  /// 预览模式字体（衬线字体）
  static const String previewModeFontFamily = 'Georgia';
}
