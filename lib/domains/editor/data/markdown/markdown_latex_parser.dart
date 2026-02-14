import 'package:super_editor/super_editor.dart';

import '../models/latex_attribution.dart';

/// LaTeX 解析器
/// 负责识别和解析 Markdown 中的 LaTeX 公式
class MarkdownLatexParser {
  /// 行内数学公式正则表达式: $E=mc^2$
  /// 使用负向断言避免匹配 $$ (块级公式)
  static final _inlineMathRegex = RegExp(r'(?<!\$)\$([^\$]+?)\$(?!\$)');

  /// 块级数学公式正则表达式: $$\int_0^\infty...$$
  static final _blockMathRegex = RegExp(r'\$\$([^$]+?)\$\$', multiLine: true);

  /// 检测行是否包含块级公式
  static bool isBlockMathLine(String line) {
    return _blockMathRegex.hasMatch(line.trim());
  }

  /// 从块级公式行中提取表达式
  static String? extractBlockMathExpression(String line) {
    final match = _blockMathRegex.firstMatch(line);
    return match?.group(1)?.trim();
  }

  /// 在文本中解析行内公式并添加 Attribution
  /// 返回带有 LatexAttribution 标记的 AttributedText
  static AttributedText parseInlineMath(String text) {
    final markers = <SpanMarker>[];
    final buffer = StringBuffer();
    var lastEnd = 0;

    for (final match in _inlineMathRegex.allMatches(text)) {
      // 添加匹配前的普通文本
      if (match.start > lastEnd) {
        buffer.write(text.substring(lastEnd, match.start));
      }

      final expression = match.group(1)!;
      final spanStart = buffer.length;
      buffer.write(expression);
      final spanEnd = buffer.length - 1;

      final attribution = LatexAttribution(
        expression: expression,
        isBlockLevel: false,
      );

      markers.add(SpanMarker(
        attribution: attribution,
        offset: spanStart,
        markerType: SpanMarkerType.start,
      ));
      markers.add(SpanMarker(
        attribution: attribution,
        offset: spanEnd,
        markerType: SpanMarkerType.end,
      ));

      lastEnd = match.end;
    }

    // 添加剩余文本
    if (lastEnd < text.length) {
      buffer.write(text.substring(lastEnd));
    }

    final resultText = buffer.toString();
    if (markers.isEmpty) {
      return AttributedText(resultText);
    }

    return AttributedText(resultText, AttributedSpans(attributions: markers));
  }

  /// 从 AttributedText 中恢复原始 LaTeX 语法
  /// 用于序列化时将渲染的公式恢复为 $...$ 格式
  static String restoreInlineMathSyntax(AttributedText attributedText) {
    final plainText = attributedText.toPlainText();
    if (plainText.isEmpty) return '';

    // 收集所有 LaTeX 的位置和内容
    final latexSpans = <_LatexSpan>[];

    for (var i = 0; i < plainText.length; i++) {
      final attributions = attributedText.getAllAttributionsAt(i);
      for (final attr in attributions) {
        if (attr is LatexAttribution && !attr.isBlockLevel) {
          // 找到这个 attribution 的完整范围
          final range = attributedText.getAttributedRange({attr}, i);
          final existingIndex = latexSpans.indexWhere(
            (w) => w.start == range.start && w.end == range.end,
          );
          if (existingIndex == -1) {
            latexSpans.add(_LatexSpan(
              start: range.start,
              end: range.end,
              expression: attr.expression,
            ));
          }
          break;
        }
      }
    }

    if (latexSpans.isEmpty) {
      return plainText;
    }

    // 按位置排序
    latexSpans.sort((a, b) => a.start.compareTo(b.start));

    // 重建文本，将 LaTeX 恢复为 $...$ 格式
    final buffer = StringBuffer();
    var lastEnd = 0;

    for (final span in latexSpans) {
      // 添加 LaTeX 前的普通文本
      if (span.start > lastEnd) {
        buffer.write(plainText.substring(lastEnd, span.start));
      }

      // 添加 LaTeX 公式
      buffer.write('\$${span.expression}\$');

      lastEnd = span.end + 1;
    }

    // 添加剩余文本
    if (lastEnd < plainText.length) {
      buffer.write(plainText.substring(lastEnd));
    }

    return buffer.toString();
  }
}

/// 用于记录 LaTeX 位置的辅助类
class _LatexSpan {
  _LatexSpan({
    required this.start,
    required this.end,
    required this.expression,
  });

  final int start;
  final int end;
  final String expression;
}
