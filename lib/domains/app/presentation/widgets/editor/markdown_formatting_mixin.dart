import 'package:super_editor/super_editor.dart';

/// Markdown 格式化操作 Mixin
/// 提供粗体、斜体、标题等格式化操作
mixin MarkdownFormattingMixin {
  /// 子类需要实现：获取编辑器实例
  Editor get editor;

  /// 子类需要实现：获取 Composer 实例
  MutableDocumentComposer get composer;

  /// 在光标位置插入文本
  void insertText(String text) {
    final selection = composer.selection;
    if (selection != null && selection.isCollapsed) {
      editor.execute([
        InsertTextRequest(
          documentPosition: selection.extent,
          textToInsert: text,
          attributions: const {},
        ),
      ]);
    }
  }

  /// 切换粗体格式
  void toggleBold() => _toggleMarkdownFormat('**');

  /// 切换斜体格式
  void toggleItalic() => _toggleMarkdownFormat('*');

  /// 切换删除线格式
  void toggleStrikethrough() => _toggleMarkdownFormat('~~');

  /// 插入标题
  void insertHeading(int level) {
    final prefix = '#' * level;
    _insertPrefix('$prefix ');
  }

  /// 插入无序列表
  void insertBulletList() => _insertPrefix('- ');

  /// 插入有序列表
  void insertOrderedList() => _insertPrefix('1. ');

  /// 插入代码块
  void insertCodeBlock() {
    final selection = composer.selection;
    if (selection != null && selection.isCollapsed) {
      editor.execute([
        InsertTextRequest(
          documentPosition: selection.extent,
          textToInsert: '```\n\n```',
          attributions: const {},
        ),
      ]);
    }
  }

  /// 插入 WikiLink
  void insertWikiLink(String title) {
    final selection = composer.selection;
    if (selection != null && selection.isCollapsed) {
      editor.execute([
        InsertTextRequest(
          documentPosition: selection.extent,
          textToInsert: '[[$title]]',
          attributions: const {},
        ),
      ]);
    }
  }

  void _toggleMarkdownFormat(String delimiter) {
    final selection = composer.selection;
    if (selection == null) return;

    if (selection.isCollapsed) {
      editor.execute([
        InsertTextRequest(
          documentPosition: selection.extent,
          textToInsert: '$delimiter$delimiter',
          attributions: const {},
        ),
      ]);
    } else {
      editor.execute([
        InsertTextRequest(
          documentPosition: selection.extent,
          textToInsert: delimiter,
          attributions: const {},
        ),
      ]);
      editor.execute([
        InsertTextRequest(
          documentPosition: selection.base,
          textToInsert: delimiter,
          attributions: const {},
        ),
      ]);
    }
  }

  void _insertPrefix(String prefix) {
    final selection = composer.selection;
    if (selection != null && selection.isCollapsed) {
      editor.execute([
        InsertTextRequest(
          documentPosition: selection.extent,
          textToInsert: prefix,
          attributions: const {},
        ),
      ]);
    }
  }
}
