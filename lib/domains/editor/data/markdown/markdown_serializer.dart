import 'package:super_editor/super_editor.dart';

import 'code_block_node.dart';
import 'parsers/inline_parser.dart';
import 'parsers/markdown_ast_parser.dart';
import 'serializers/block_serializer.dart';
import 'serializers/inline_serializer.dart';
import 'models/wikilink_utils.dart';

/// Markdown 序列化器
/// 负责 Markdown 文本与 Super Editor Document 之间的转换
class MarkdownSerializer {
  MarkdownSerializer()
      : _inlineParser = InlineParser(),
        _inlineSerializer = InlineSerializer() {
    _astParser = MarkdownAstParser(inlineParser: _inlineParser);
    _blockSerializer = BlockSerializer(inlineSerializer: _inlineSerializer);
  }

  late final InlineParser _inlineParser;
  late final MarkdownAstParser _astParser;
  late final InlineSerializer _inlineSerializer;
  late final BlockSerializer _blockSerializer;

  /// 将 Markdown 文本解析为 Super Editor Document
  /// 使用 AST 解析器正确处理列表缩进
  MutableDocument deserialize(String markdown) {
    _astParser.reset();
    final nodes = _astParser.parse(markdown);
    return MutableDocument(nodes: nodes);
  }

  /// 将 Super Editor Document 序列化为 Markdown 文本
  String serialize(Document document) {
    final buffer = StringBuffer();
    final nodeCount = document.nodeCount;

    for (var i = 0; i < nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node == null) continue;

      if (node is TextNode && node.metadata['isLatex'] == true) {
        buffer.writeln(_inlineSerializer.serializeLatexNode(node));
      } else if (node is CodeBlockNode) {
        buffer.writeln(_blockSerializer.serializeCodeBlock(node));
      } else if (node is ParagraphNode) {
        buffer.writeln(_blockSerializer.serializeParagraph(node));
      } else if (node is ListItemNode) {
        buffer.writeln(_blockSerializer.serializeListItem(node));
      } else if (node is TaskNode) {
        buffer.writeln(_blockSerializer.serializeTaskItem(node));
      } else if (node is HorizontalRuleNode) {
        buffer.writeln(_blockSerializer.serializeHorizontalRule());
      }

      // 在节点之间添加空行（除了最后一个节点）
      if (i < nodeCount - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// 从文本中提取所有 WikiLink 标题
  static List<String> extractWikiLinkTitles(String text) {
    return WikiLinkUtils.extractWikiLinkTitles(text);
  }

  /// 从文本中查找给定位置处的 WikiLink 标题
  static String? findWikiLinkAtPosition(String text, int position) {
    return WikiLinkUtils.findWikiLinkAtPosition(text, position);
  }
}
