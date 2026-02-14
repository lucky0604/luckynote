import 'package:super_editor/super_editor.dart';

import '../code_block_node.dart';
import 'inline_serializer.dart';

/// Block-level markdown serializer.
///
/// Serializes document nodes to markdown text.
class BlockSerializer {
  BlockSerializer({
    required this.inlineSerializer,
  });

  final InlineSerializer inlineSerializer;

  /// 序列化段落节点
  String serializeParagraph(ParagraphNode node) {
    final blockType = node.metadata['blockType'];
    final text = inlineSerializer.serialize(node.text);

    if (blockType == header1Attribution) {
      return '# $text';
    } else if (blockType == header2Attribution) {
      return '## $text';
    } else if (blockType == header3Attribution) {
      return '### $text';
    } else if (blockType == header4Attribution) {
      return '#### $text';
    } else if (blockType == header5Attribution) {
      return '##### $text';
    } else if (blockType == header6Attribution) {
      return '###### $text';
    } else if (blockType == blockquoteAttribution) {
      return '> $text';
    }

    return text;
  }

  /// 序列化代码块节点（保留语言信息）
  String serializeCodeBlock(CodeBlockNode node) {
    final language = node.language != 'plaintext' ? node.language : '';
    return '```$language\n${node.code}\n```';
  }

  /// 序列化列表项（支持缩进）
  String serializeListItem(ListItemNode node) {
    final text = inlineSerializer.serialize(node.text);
    final indentStr = '  ' * node.indent; // 每级缩进2个空格
    return switch (node.type) {
      ListItemType.unordered => '$indentStr- $text',
      ListItemType.ordered => '${indentStr}1. $text',
    };
  }

  /// 序列化任务项
  String serializeTaskItem(TaskNode node) {
    final text = inlineSerializer.serialize(node.text);
    final checkbox = node.isComplete ? '[x]' : '[ ]';
    return '- $checkbox $text';
  }

  /// 序列化水平分割线
  String serializeHorizontalRule() {
    return '---';
  }
}
