import 'package:super_editor/super_editor.dart';

import '../../models/latex_attribution.dart';
import 'package:luckynote/domains/association/data/models/wikilink_attribution.dart';

/// Inline markdown parser.
///
/// Parses inline markdown elements (LaTeX, WikiLinks, formatting).
class InlineParser {
  InlineParser();

  /// 解析行内元素（LaTeX 和 WikiLink）
  AttributedText parse(String text) {
    // 先移除粗体、斜体等格式
    String processed = text
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1)!);

    // 解析行内 LaTeX 和 WikiLink
    return _parseLatexAndWikiLinks(processed);
  }

  /// 组合解析行内 LaTeX 和 WikiLink
  /// 先解析 LaTeX，再在结果上解析 WikiLink
  AttributedText _parseLatexAndWikiLinks(String text) {
    // 收集所有标记
    final allMarkers = <SpanMarker>[];
    final buffer = StringBuffer();
    var lastEnd = 0;

    // 合并的正则模式：匹配行内 LaTeX ($...$) 或 WikiLink ([[...]])
    // LaTeX 使用负向先行断言避免匹配 $$
    final combinedPattern = RegExp(
      r'(?<!\$)\$([^\$]+?)\$(?!\$)|\[\[([^\[\]]+?)(?:\|([^\[\]]+?))?\]\]',
    );

    for (final match in combinedPattern.allMatches(text)) {
      // 添加匹配前的普通文本
      if (match.start > lastEnd) {
        buffer.write(text.substring(lastEnd, match.start));
      }

      // 检查是 LaTeX 还是 WikiLink
      if (match.group(1) != null) {
        // 这是行内 LaTeX: $expression$
        final expression = match.group(1)!;
        final spanStart = buffer.length;
        buffer.write(expression);
        final spanEnd = buffer.length - 1;

        if (spanEnd >= spanStart) {
          final attribution = LatexAttribution(
            expression: expression,
            isBlockLevel: false,
          );
          allMarkers.add(SpanMarker(
            attribution: attribution,
            offset: spanStart,
            markerType: SpanMarkerType.start,
          ));
          allMarkers.add(SpanMarker(
            attribution: attribution,
            offset: spanEnd,
            markerType: SpanMarkerType.end,
          ));
        }
      } else if (match.group(2) != null) {
        // 这是 WikiLink: [[Title]] 或 [[Title|Alias]]
        final targetTitle = match.group(2)!;
        final alias = match.group(3);
        final displayText = alias ?? targetTitle;

        final spanStart = buffer.length;
        buffer.write(displayText);
        final spanEnd = buffer.length - 1;

        if (spanEnd >= spanStart) {
          final attribution = WikiLinkAttribution(
            targetTitle: targetTitle,
            alias: alias,
          );
          allMarkers.add(SpanMarker(
            attribution: attribution,
            offset: spanStart,
            markerType: SpanMarkerType.start,
          ));
          allMarkers.add(SpanMarker(
            attribution: attribution,
            offset: spanEnd,
            markerType: SpanMarkerType.end,
          ));
        }
      }

      lastEnd = match.end;
    }

    // 添加剩余文本
    if (lastEnd < text.length) {
      buffer.write(text.substring(lastEnd));
    }

    final resultText = buffer.toString();

    if (allMarkers.isEmpty) {
      return AttributedText(resultText);
    }

    return AttributedText(resultText, AttributedSpans(attributions: allMarkers));
  }
}
