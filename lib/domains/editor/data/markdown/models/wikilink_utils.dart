/// WikiLink utilities.
///
/// Provides helper methods for WikiLink parsing and extraction.
class WikiLinkUtils {
  WikiLinkUtils._();

  /// WikiLink 正则表达式：匹配 [[Title]] 或 [[Title|Alias]]
  static final _wikilinkRegex =
      RegExp(r'\[\[([^\[\]]+?)(?:\|([^\[\]]+?))?\]\]');

  /// 从文本中提取所有 WikiLink 标题
  static List<String> extractWikiLinkTitles(String text) {
    final titles = <String>[];
    for (final match in _wikilinkRegex.allMatches(text)) {
      titles.add(match.group(1)!);
    }
    return titles;
  }

  /// 从文本中查找给定位置处的 WikiLink 标题
  static String? findWikiLinkAtPosition(String text, int position) {
    for (final match in _wikilinkRegex.allMatches(text)) {
      if (position >= match.start && position <= match.end) {
        return match.group(1);
      }
    }
    return null;
  }

  /// 获取正则表达式用于其他地方的匹配
  static RegExp get wikilinkRegex => _wikilinkRegex;
}
