import 'package:super_editor/super_editor.dart';

import '../markdown_latex_parser.dart';
import 'inline_parser.dart';

/// Block-level markdown parser.
///
/// Parses markdown into document nodes (headings, paragraphs, lists, etc.).
class BlockParser {
  BlockParser({
    required this.inlineParser,
  });

  final InlineParser inlineParser;
  int _nodeIdCounter = 0;

  /// 生成唯一的节点 ID
  String _createNodeId() {
    _nodeIdCounter++;
    return 'node_$_nodeIdCounter';
  }

  /// Reset node ID counter for new document
  void reset() {
    _nodeIdCounter = 0;
  }

  /// 解析 Markdown 文本为文档节点列表
  List<DocumentNode> parse(String markdown) {
    if (markdown.isEmpty) {
      return [_createEmptyParagraph()];
    }

    final nodes = <DocumentNode>[];
    final lines = markdown.split('\n');
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // 检查块级 LaTeX 公式: $$...$$
      if (MarkdownLatexParser.isBlockMathLine(line)) {
        final expression = MarkdownLatexParser.extractBlockMathExpression(line);
        if (expression != null) {
          nodes.add(_createLatexBlockTextNode(expression));
          i++;
          continue;
        }
      }

      // 检查代码块
      if (line.startsWith('```')) {
        final codeLines = <String>[];
        i++; // 跳过开始的 ```
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        i++; // 跳过结束的 ```
        nodes.add(_createCodeBlock(codeLines.join('\n')));
        continue;
      }

      // 检查标题
      final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final text = headingMatch.group(2)!;
        nodes.add(_createHeading(text, level));
        i++;
        continue;
      }

      // 检查引用块
      if (line.startsWith('>')) {
        final quoteText = line.substring(1).trim();
        nodes.add(_createBlockquote(quoteText));
        i++;
        continue;
      }

      // 检查任务列表（必须在无序列表之前，因为任务也以 - 开头）
      final taskMatch = RegExp(
        r'^(\s*)[-*+]\s+\[([ xX])\]\s+(.*)$',
      ).firstMatch(line);
      if (taskMatch != null) {
        final isChecked = taskMatch.group(2)!.toLowerCase() == 'x';
        final text = taskMatch.group(3)!;
        nodes.add(_createTaskItem(text, isChecked));
        i++;
        continue;
      }

      // 检查无序列表
      final unorderedMatch = RegExp(r'^[-*+]\s+(.*)$').firstMatch(line);
      if (unorderedMatch != null) {
        final text = unorderedMatch.group(1)!;
        nodes.add(_createListItem(text, ListItemType.unordered));
        i++;
        continue;
      }

      // 检查有序列表
      final orderedMatch = RegExp(r'^\d+\.\s+(.*)$').firstMatch(line);
      if (orderedMatch != null) {
        final text = orderedMatch.group(1)!;
        nodes.add(_createListItem(text, ListItemType.ordered));
        i++;
        continue;
      }

      // 检查水平分割线
      if (RegExp(r'^[-*_]{3,}$').hasMatch(line.trim())) {
        nodes.add(HorizontalRuleNode(id: _createNodeId()));
        i++;
        continue;
      }

      // 空行
      if (line.trim().isEmpty) {
        // 连续空行只添加一个空段落
        if (nodes.isNotEmpty && nodes.last is! ParagraphNode) {
          nodes.add(_createParagraph(AttributedText('')));
        } else if (nodes.isEmpty) {
          nodes.add(_createParagraph(AttributedText('')));
        }
        i++;
        continue;
      }

      // 普通段落（包含行内 LaTeX 和 WikiLink）
      nodes.add(_createParagraphWithInlineElements(line));
      i++;
    }

    if (nodes.isEmpty) {
      return [_createEmptyParagraph()];
    }

    return nodes;
  }

  /// 创建空段落节点
  ParagraphNode _createEmptyParagraph() {
    return ParagraphNode(id: _createNodeId(), text: AttributedText(''));
  }

  /// 创建标题节点
  ParagraphNode _createHeading(String text, int level) {
    final attribution = switch (level) {
      1 => header1Attribution,
      2 => header2Attribution,
      3 => header3Attribution,
      4 => header4Attribution,
      5 => header5Attribution,
      6 => header6Attribution,
      _ => header1Attribution,
    };

    return ParagraphNode(
      id: _createNodeId(),
      text: inlineParser.parse(text),
      metadata: {'blockType': attribution},
    );
  }

  /// 创建段落节点
  ParagraphNode _createParagraph(AttributedText text) {
    return ParagraphNode(id: _createNodeId(), text: text);
  }

  /// 创建带行内元素的段落节点（LaTeX + WikiLink）
  ParagraphNode _createParagraphWithInlineElements(String text) {
    return ParagraphNode(
      id: _createNodeId(),
      text: inlineParser.parse(text),
    );
  }

  /// 创建引用块节点
  ParagraphNode _createBlockquote(String text) {
    return ParagraphNode(
      id: _createNodeId(),
      text: inlineParser.parse(text),
      metadata: {'blockType': blockquoteAttribution},
    );
  }

  /// 创建代码块节点
  ParagraphNode _createCodeBlock(String code) {
    return ParagraphNode(
      id: _createNodeId(),
      text: AttributedText(code),
      metadata: {'blockType': codeAttribution},
    );
  }

  /// 创建 LaTeX 数学公式节点（块级）
  TextNode _createLatexBlockTextNode(String expression) {
    return TextNode(
      id: _createNodeId(),
      text: AttributedText(expression),
      metadata: {
        'isLatex': true,
        'isBlockLevel': true,
        'latexExpression': expression,
      },
    );
  }

  /// 创建列表项节点
  ListItemNode _createListItem(String text, ListItemType type) {
    return ListItemNode(
      id: _createNodeId(),
      itemType: type,
      text: inlineParser.parse(text),
    );
  }

  /// 创建任务项节点
  TaskNode _createTaskItem(String text, bool isComplete) {
    return TaskNode(
      id: _createNodeId(),
      text: inlineParser.parse(text),
      isComplete: isComplete,
    );
  }
}
