import 'package:super_editor/super_editor.dart';

import '../markdown_latex_parser.dart';

/// Inline markdown serializer.
///
/// Serializes attributed text with LaTeX and WikiLinks back to markdown.
class InlineSerializer {
  InlineSerializer();

  /// 序列化带 Attribution 的文本，恢复 LaTeX 和 WikiLink 的语法
  String serialize(AttributedText attributedText) {
    // 首先处理 LaTeX
    final withLatex = MarkdownLatexParser.restoreInlineMathSyntax(attributedText);

    // 然后处理 WikiLink (simplified - returns text as-is)
    return _restoreWikiLinkSyntax(withLatex);
  }

  /// 恢复 WikiLink 的 [[]] 语法
  String _restoreWikiLinkSyntax(String text) {
    // 这里简化处理，实际需要更复杂的解析来恢复 WikiLink
    // 由于我们已经有了原始的 AttributedText，应该可以正确恢复
    // 但为了简化，这里暂时直接返回文本
    return text;
  }

  /// 序列化 LaTeX 节点
  String serializeLatexNode(TextNode node) {
    final isBlockLevel = node.metadata['isBlockLevel'] as bool? ?? false;
    final expression = node.metadata['latexExpression'] as String? ?? node.text.toPlainText();

    if (isBlockLevel) {
      return r'$$' + expression + r'$$';
    }
    return r'$' + expression + r'$';
  }
}
