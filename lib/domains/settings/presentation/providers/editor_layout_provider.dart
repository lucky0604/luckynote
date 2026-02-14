import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';

part 'editor_layout_provider.g.dart';

/// 编辑器布局设置状态
class EditorLayoutSettings {
  final double maxWidth;
  final bool isFullWidth;
  final double horizontalPadding;

  const EditorLayoutSettings({
    this.maxWidth = double.infinity,
    this.isFullWidth = true,
    this.horizontalPadding = 0.0, // 全宽模式下不需要额外边距，由编辑器自己控制
  });

  EditorLayoutSettings copyWith({
    double? maxWidth,
    bool? isFullWidth,
    double? horizontalPadding,
  }) {
    return EditorLayoutSettings(
      maxWidth: maxWidth ?? this.maxWidth,
      isFullWidth: isFullWidth ?? this.isFullWidth,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
    );
  }

  @override
  String toString() =>
      'EditorLayoutSettings(maxWidth: $maxWidth, isFullWidth: $isFullWidth, '
      'horizontalPadding: $horizontalPadding)';
}

/// 编辑器布局设置 Provider
@riverpod
class EditorLayoutNotifier extends _$EditorLayoutNotifier {
  @override
  EditorLayoutSettings build() {
    _loadSettings();
    return const EditorLayoutSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final maxWidth = prefs.getDouble(AppConstants.keyEditorMaxWidth);
    final isFullWidth = prefs.getBool(AppConstants.keyEditorFullWidth);

    if (maxWidth != null || isFullWidth != null) {
      state = EditorLayoutSettings(
        maxWidth: maxWidth ?? state.maxWidth,
        isFullWidth: isFullWidth ?? state.isFullWidth,
      );
    }
  }

  /// 切换全宽模式
  Future<void> toggleFullWidth() async {
    final newValue = !state.isFullWidth;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyEditorFullWidth, newValue);

    final newMaxWidth = newValue ? double.infinity : AppConstants.defaultEditorMaxWidth;
    state = state.copyWith(isFullWidth: newValue, maxWidth: newMaxWidth);
  }

  /// 设置最大宽度
  Future<void> setMaxWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyEditorMaxWidth, width);
    state = state.copyWith(maxWidth: width, isFullWidth: false);
  }
}
