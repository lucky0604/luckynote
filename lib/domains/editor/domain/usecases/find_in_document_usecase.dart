import '../../data/models/find_match.dart';

/// 在文本中查找的用例
/// 基于原始 Markdown 文本进行查找替换
class FindInDocumentUseCase {
  const FindInDocumentUseCase();

  /// 在文本中查找所有匹配项
  ///
  /// [text] 要搜索的文本
  /// [searchTerm] 搜索关键词
  /// [caseSensitive] 是否区分大小写，默认不区分
  List<FindMatch> execute(
    String text,
    String searchTerm, {
    bool caseSensitive = false,
  }) {
    if (searchTerm.isEmpty || text.isEmpty) return [];

    final matches = <FindMatch>[];
    final termToFind = caseSensitive ? searchTerm : searchTerm.toLowerCase();
    final textToSearch = caseSensitive ? text : text.toLowerCase();

    int startIndex = 0;
    int matchIndex = 0;

    while (true) {
      final index = textToSearch.indexOf(termToFind, startIndex);
      if (index == -1) break;

      matches.add(FindMatch(
        nodeId: 'match_$matchIndex',
        startOffset: index,
        endOffset: index + searchTerm.length,
        text: text.substring(index, index + searchTerm.length),
      ));

      startIndex = index + 1;
      matchIndex++;
    }

    return matches;
  }

  /// 替换文本中的指定匹配项
  ///
  /// [text] 原始文本
  /// [match] 要替换的匹配项
  /// [replacement] 替换文本
  /// 返回替换后的新文本
  String replaceMatch(String text, FindMatch match, String replacement) {
    if (match.startOffset < 0 || match.endOffset > text.length) {
      return text;
    }

    final before = text.substring(0, match.startOffset);
    final after = text.substring(match.endOffset);
    return '$before$replacement$after';
  }

  /// 替换文本中的所有匹配项
  ///
  /// [text] 原始文本
  /// [searchTerm] 搜索关键词
  /// [replacement] 替换文本
  /// [caseSensitive] 是否区分大小写
  /// 返回替换后的新文本
  String replaceAll(
    String text,
    String searchTerm,
    String replacement, {
    bool caseSensitive = false,
  }) {
    if (caseSensitive) {
      return text.replaceAll(searchTerm, replacement);
    }
    return text.replaceAll(RegExp(RegExp.escape(searchTerm), caseSensitive: false), replacement);
  }
}
