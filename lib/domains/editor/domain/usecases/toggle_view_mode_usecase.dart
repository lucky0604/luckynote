import 'package:super_editor/super_editor.dart';
import '../../data/markdown/markdown_serializer.dart';

/// 视图模式
enum EditorViewMode { preview, source }

/// 切换视图模式用例的结果
class ToggleViewModeResult {
  ToggleViewModeResult({
    required this.newMode,
    this.document,
    this.rawMarkdown,
  });

  final EditorViewMode newMode;
  final MutableDocument? document;
  final String? rawMarkdown;
}

/// 切换视图模式用例
class ToggleViewModeUseCase {
  ToggleViewModeUseCase({
    required this.markdownSerializer,
  });

  final MarkdownSerializer markdownSerializer;

  /// 执行切换视图模式操作
  ToggleViewModeResult execute({
    required EditorViewMode currentMode,
    required MutableDocument? document,
    required String rawMarkdown,
  }) {
    final newMode = currentMode == EditorViewMode.source
        ? EditorViewMode.preview
        : EditorViewMode.source;

    if (newMode == EditorViewMode.source) {
      // Switching to source mode: serialize document to markdown
      final markdown = document != null
          ? markdownSerializer.serialize(document)
          : rawMarkdown;
      return ToggleViewModeResult(
        newMode: newMode,
        rawMarkdown: markdown,
      );
    } else {
      // Switching to preview mode: deserialize markdown to document
      final newDocument = markdownSerializer.deserialize(rawMarkdown);
      return ToggleViewModeResult(
        newMode: newMode,
        document: newDocument,
      );
    }
  }
}
