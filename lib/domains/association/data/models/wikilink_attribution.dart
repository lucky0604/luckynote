import 'package:super_editor/super_editor.dart';

/// WikiLink 链接属性
/// 用于在 Super Editor 中标识和渲染 [[Title]] 或 [[Title|Alias]] 格式的链接
class WikiLinkAttribution implements Attribution {
  WikiLinkAttribution({
    required this.targetTitle,
    this.alias,
  });

  /// 目标笔记标题
  final String targetTitle;

  /// 显示别名（可选）
  /// 如果设置了别名，则显示别名但链接到 targetTitle
  final String? alias;

  @override
  String get id => 'wikilink';

  @override
  bool canMergeWith(Attribution other) {
    // WikiLink 属性只在完全相同时可以合并
    return this == other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WikiLinkAttribution &&
        other.targetTitle == targetTitle &&
        other.alias == alias;
  }

  @override
  int get hashCode => Object.hash(targetTitle, alias);

  @override
  String toString() {
    if (alias != null) {
      return 'WikiLinkAttribution(targetTitle: $targetTitle, alias: $alias)';
    }
    return 'WikiLinkAttribution(targetTitle: $targetTitle)';
  }
}
