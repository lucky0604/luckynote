import 'package:super_editor/super_editor.dart';
import '../models/latex_attribution.dart';

/// Markdown 节点构建器
/// 提供创建各种 Markdown 节点的方法
class MarkdownNodeBuilders {
  int _nodeIdCounter = 0;

  /// 生成唯一的节点 ID
  String _createNodeId() {
    _nodeIdCounter++;
    return 'node_$_nodeIdCounter';
  }

  /// 重置节点 ID 计数器
  void resetCounter() {
    _nodeIdCounter = 0;
  }

  /// 创建标题节点
  ParagraphNode createHeading(String text, int level) {
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
      text: _parseInlineTextWithWikiLinks(text),
      metadata: {'blockType': attribution},
    );
  }

  /// 创建段落节点
  ParagraphNode createParagraph(AttributedText text) {
    return ParagraphNode(id: _createNodeId(), text: text);
  }

  /// 创建带 WikiLink 的段落节点
  ParagraphNode createParagraphWithWikiLinks(String text) {
    return ParagraphNode(
      id: _createNodeId(),
      text: _parseInlineTextWithWikiLinks(text),
    );
  }

  /// 创建引用块节点
  ParagraphNode createBlockquote(String text) {
    return ParagraphNode(
      id: _createNodeId(),
      text: _parseInlineTextWithWikiLinks(text),
      metadata: {'blockType': blockquoteAttribution},
    );
  }

  /// 创建代码块节点
  ParagraphNode createCodeBlock(String code) {
    return ParagraphNode(
      id: _createNodeId(),
      text: AttributedText(code),
      metadata: {'blockType': codeAttribution},
    );
  }

  /// 创建 LaTeX 数学公式节点（块级）
  ParagraphNode createLatexBlock(String expression) {
    final text = AttributedText(
      expression,
      AttributedSpans(attributions: [
        SpanMarker(
          attribution: LatexAttribution(expression: expression, isBlockLevel: true),
          offset: 0,
          markerType: SpanMarkerType.start,
        ),
        SpanMarker(
          attribution: LatexAttribution(expression: expression, isBlockLevel: true),
          offset: expression.length - 1,
          markerType: SpanMarkerType.end,
        ),
      ]),
    );

    return ParagraphNode(
      id: _createNodeId(),
      text: text,
      metadata: {'blockType': 'latexBlock'},
    );
  }

  /// 创建列表项节点
  ListItemNode createListItem(String text, ListItemType type) {
    return ListItemNode(
      id: _createNodeId(),
      itemType: type,
      text: _parseInlineTextWithWikiLinks(text),
    );
  }

  /// 创建任务项节点
  TaskNode createTaskItem(String text, bool isComplete) {
    return TaskNode(
      id: _createNodeId(),
      text: _parseInlineTextWithWikiLinks(text),
      isComplete: isComplete,
    );
  }

  /// 解析行内文本，识别 WikiLink 并添加 Attribution
  /// 在预览模式下显示不带 [[]] 的文本，但保留链接信息
  AttributedText _parseInlineTextWithWikiLinks(String text) {
    // 先移除粗体、斜体等格式
    String processed = text
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) => m.group(1)!)
        .replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1)!);

    // 解析 WikiLink 并构建带 Attribution 的文本
    final wikilinkRegex = RegExp(r'\[\[([^\[\]]+?)(?:\|([^\[\]]+?))?\]\]');
    final markers = <SpanMarker>[];
    final buffer = StringBuffer();
    var lastEnd = 0;

    for (final match in wikilinkRegex.allMatches(processed)) {
      // 添加匹配前的普通文本
      if (match.start > lastEnd) {
        buffer.write(processed.substring(lastEnd, match.start));
      }

      // 获取目标标题和别名
      final targetTitle = match.group(1)!;
      final alias = match.group(2);
      final displayText = alias ?? targetTitle;

      // 记录 WikiLink 在输出文本中的位置
      final spanStart = buffer.length;
      buffer.write(displayText);
      final spanEnd = buffer.length - 1; // SpanMarker 的 end 是包含的

      // 添加 WikiLink Attribution 标记
      // Note: 这里需要导入 WikiLinkAttribution
      // 为了保持文件独立，这里暂时使用简单的字符串标记
      // 实际使用时需要替换为真正的 WikiLinkAttribution
      final attribution = _WikiLinkPlaceholderAttribution(
        targetTitle: targetTitle,
        alias: alias,
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
    if (lastEnd < processed.length) {
      buffer.write(processed.substring(lastEnd));
    }

    final resultText = buffer.toString();
    if (markers.isEmpty) {
      return AttributedText(resultText);
    }

    return AttributedText(resultText, AttributedSpans(attributions: markers));
  }

  /// 创建空文档
  MutableDocument createEmptyDocument() {
    return MutableDocument(
      nodes: [ParagraphNode(id: _createNodeId(), text: AttributedText(''))],
    );
  }
}

/// 临时的 WikiLink 占位符 Attribution
/// 实际使用时应该替换为真正的 WikiLinkAttribution
class _WikiLinkPlaceholderAttribution implements Attribution {
  _WikiLinkPlaceholderAttribution({
    required this.targetTitle,
    this.alias,
  });

  final String targetTitle;
  final String? alias;

  @override
  String get id => 'wikilink';

  @override
  bool canMergeWith(Attribution other) =>
      other is _WikiLinkPlaceholderAttribution &&
      other.targetTitle == targetTitle &&
      other.alias == alias;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _WikiLinkPlaceholderAttribution &&
        other.targetTitle == targetTitle &&
        other.alias == alias;
  }

  @override
  int get hashCode => Object.hash(targetTitle, alias);
}
