import 'package:markdown/markdown.dart' as md;
import 'package:super_editor/super_editor.dart';

import '../code_block_node.dart';
import 'inline_parser.dart';

/// Markdown AST 解析器
/// 使用 markdown 包将 Markdown 转换为 AST，再映射为 SuperEditor 节点
/// 主要用于正确解析列表缩进层级
class MarkdownAstParser {
  MarkdownAstParser({required this.inlineParser});

  final InlineParser inlineParser;
  int _nodeIdCounter = 0;

  String _createNodeId() {
    _nodeIdCounter++;
    return 'ast_node_$_nodeIdCounter';
  }

  void reset() {
    _nodeIdCounter = 0;
  }

  /// 解析 Markdown 文本为文档节点列表
  List<DocumentNode> parse(String markdown) {
    if (markdown.trim().isEmpty) {
      return [_createEmptyParagraph()];
    }

    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    final lines = markdown.split('\n');
    final astNodes = document.parseLines(lines);

    final nodes = <DocumentNode>[];
    for (final astNode in astNodes) {
      _visitNode(astNode, nodes, indent: 0);
    }

    if (nodes.isEmpty) {
      return [_createEmptyParagraph()];
    }

    return nodes;
  }

  /// 递归访问 AST 节点并转换为 DocumentNode
  void _visitNode(md.Node astNode, List<DocumentNode> nodes, {int indent = 0}) {
    if (astNode is md.Element) {
      _visitElement(astNode, nodes, indent: indent);
    } else if (astNode is md.Text) {
      // 文本节点通常在 Element 内部处理
      // 但独立的文本节点作为段落
      final text = astNode.text.trim();
      if (text.isNotEmpty) {
        nodes.add(_createParagraph(text));
      }
    }
  }

  /// 处理 Element 类型的 AST 节点
  void _visitElement(
    md.Element element,
    List<DocumentNode> nodes, {
    int indent = 0,
  }) {
    switch (element.tag) {
      case 'h1':
        nodes.add(_createHeading(_extractText(element), 1));
      case 'h2':
        nodes.add(_createHeading(_extractText(element), 2));
      case 'h3':
        nodes.add(_createHeading(_extractText(element), 3));
      case 'h4':
        nodes.add(_createHeading(_extractText(element), 4));
      case 'h5':
        nodes.add(_createHeading(_extractText(element), 5));
      case 'h6':
        nodes.add(_createHeading(_extractText(element), 6));
      case 'p':
        nodes.add(_createParagraph(_extractText(element)));
      case 'blockquote':
        nodes.add(_createBlockquote(_extractText(element)));
      case 'pre':
        final code = _extractCodeFromPre(element);
        final language = _extractLanguageFromPre(element);
        nodes.add(_createCodeBlock(code, language: language));
      case 'ul':
        _visitListItems(element, nodes, ListItemType.unordered, indent);
      case 'ol':
        _visitListItems(element, nodes, ListItemType.ordered, indent);
      case 'hr':
        nodes.add(HorizontalRuleNode(id: _createNodeId()));
      default:
        // 其他元素递归处理子节点
        if (element.children != null) {
          for (final child in element.children!) {
            _visitNode(child, nodes, indent: indent);
          }
        }
    }
  }

  /// 处理列表项
  void _visitListItems(
    md.Element listElement,
    List<DocumentNode> nodes,
    ListItemType type,
    int indent,
  ) {
    if (listElement.children == null) return;

    for (final child in listElement.children!) {
      if (child is md.Element && child.tag == 'li') {
        _visitListItem(child, nodes, type, indent);
      }
    }
  }

  /// 处理单个列表项（支持嵌套）
  void _visitListItem(
    md.Element liElement,
    List<DocumentNode> nodes,
    ListItemType type,
    int indent,
  ) {
    // 提取列表项的文本内容（排除嵌套列表）
    final textContent = _extractListItemText(liElement);

    // 检查是否是任务列表项（checkbox）
    final taskInfo = _parseTaskItem(textContent);
    if (taskInfo != null) {
      nodes.add(_createTaskItem(taskInfo.text, taskInfo.isComplete, indent));
    } else {
      nodes.add(_createListItem(textContent, type, indent));
    }

    // 处理嵌套列表
    if (liElement.children != null) {
      for (final child in liElement.children!) {
        if (child is md.Element) {
          if (child.tag == 'ul') {
            _visitListItems(child, nodes, ListItemType.unordered, indent + 1);
          } else if (child.tag == 'ol') {
            _visitListItems(child, nodes, ListItemType.ordered, indent + 1);
          }
        }
      }
    }
  }

  /// 提取列表项文本（不包括嵌套列表）
  String _extractListItemText(md.Element liElement) {
    final buffer = StringBuffer();
    if (liElement.children != null) {
      for (final child in liElement.children!) {
        if (child is md.Text) {
          buffer.write(child.text);
        } else if (child is md.Element) {
          // 跳过嵌套列表
          if (child.tag != 'ul' && child.tag != 'ol') {
            buffer.write(_extractText(child));
          }
        }
      }
    }
    return buffer.toString().trim();
  }

  /// 提取元素的文本内容
  String _extractText(md.Element element) {
    final buffer = StringBuffer();
    if (element.children != null) {
      for (final child in element.children!) {
        if (child is md.Text) {
          buffer.write(child.text);
        } else if (child is md.Element) {
          buffer.write(_extractText(child));
        }
      }
    }
    return buffer.toString();
  }

  /// 从 pre 元素提取代码
  String _extractCodeFromPre(md.Element preElement) {
    if (preElement.children != null) {
      for (final child in preElement.children!) {
        if (child is md.Element && child.tag == 'code') {
          return _extractText(child);
        }
      }
    }
    return _extractText(preElement);
  }

  /// 从 pre 元素提取语言标识
  String? _extractLanguageFromPre(md.Element preElement) {
    if (preElement.children != null) {
      for (final child in preElement.children!) {
        if (child is md.Element && child.tag == 'code') {
          final className = child.attributes['class'];
          if (className != null && className.startsWith('language-')) {
            return className.substring('language-'.length);
          }
        }
      }
    }
    return null;
  }

  /// 解析任务列表项
  _TaskInfo? _parseTaskItem(String text) {
    final match = RegExp(r'^\[([ xX])\]\s*(.*)$').firstMatch(text);
    if (match != null) {
      return _TaskInfo(
        isComplete: match.group(1)!.toLowerCase() == 'x',
        text: match.group(2)!,
      );
    }
    return null;
  }

  // ==================== 节点创建方法 ====================

  ParagraphNode _createEmptyParagraph() {
    return ParagraphNode(id: _createNodeId(), text: AttributedText(''));
  }

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

  ParagraphNode _createParagraph(String text) {
    return ParagraphNode(
      id: _createNodeId(),
      text: inlineParser.parse(text),
    );
  }

  ParagraphNode _createBlockquote(String text) {
    return ParagraphNode(
      id: _createNodeId(),
      text: inlineParser.parse(text),
      metadata: {'blockType': blockquoteAttribution},
    );
  }

  CodeBlockNode _createCodeBlock(String code, {String? language}) {
    return CodeBlockNode(
      id: _createNodeId(),
      code: AttributedText(code),
      language: language ?? 'plaintext',
    );
  }

  ListItemNode _createListItem(String text, ListItemType type, int indent) {
    return ListItemNode(
      id: _createNodeId(),
      itemType: type,
      indent: indent,
      text: inlineParser.parse(text),
    );
  }

  TaskNode _createTaskItem(String text, bool isComplete, int indent) {
    return TaskNode(
      id: _createNodeId(),
      text: inlineParser.parse(text),
      isComplete: isComplete,
    );
  }
}

/// 任务项信息
class _TaskInfo {
  _TaskInfo({required this.isComplete, required this.text});
  final bool isComplete;
  final String text;
}
