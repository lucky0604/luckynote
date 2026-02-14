import 'package:super_editor/super_editor.dart';

/// 代码块节点
/// 存储代码内容和语言标识，用于语法高亮渲染
class CodeBlockNode extends TextNode {
  CodeBlockNode({
    required super.id,
    required AttributedText code,
    this.language = 'plaintext',
  }) : super(text: code);

  /// 代码语言标识（如 'dart', 'python', 'javascript'）
  /// 默认为 'plaintext'
  final String language;

  /// 获取代码文本
  String get code => text.toPlainText();

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is CodeBlockNode &&
        language == other.language &&
        text == other.text;
  }

  @override
  CodeBlockNode copy() {
    return CodeBlockNode(
      id: id,
      code: text.copyText(0),
      language: language,
    );
  }

  @override
  String toString() => '[CodeBlockNode] - language: $language, code: "${code.length > 50 ? '${code.substring(0, 50)}...' : code}"';
}
