import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/editor/presentation/providers/editor_state.dart';
import 'package:luckynote/domains/editor/presentation/providers/find_replace_provider.dart';
import 'package:luckynote/domains/editor/data/markdown/markdown_serializer.dart';
import 'editor_width_container.dart';
import 'markdown_editor.dart';
import 'source_mode_editor.dart';

/// 编辑器内容区域
/// 负责在源码模式和预览模式之间切换，并同步滚动位置
class EditorContent extends ConsumerStatefulWidget {
  const EditorContent({
    super.key,
    required this.editorState,
    required this.editorKey,
    required this.onRawMarkdownChanged,
    required this.onAutoSave,
    required this.onDocumentChanged,
  });

  final EditorState editorState;
  final GlobalKey<MarkdownEditorState> editorKey;
  final ValueChanged<String> onRawMarkdownChanged;
  final VoidCallback onAutoSave;
  final VoidCallback onDocumentChanged;

  @override
  ConsumerState<EditorContent> createState() => _EditorContentState();
}

class _EditorContentState extends ConsumerState<EditorContent> {
  final _serializer = MarkdownSerializer();

  @override
  void initState() {
    super.initState();
    _updateFindReplaceContext();
  }

  @override
  void didUpdateWidget(EditorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateFindReplaceContext();
  }

  void _updateFindReplaceContext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      String text;
      if (widget.editorState.viewMode == EditorViewMode.source) {
        text = widget.editorState.rawMarkdown;
      } else if (widget.editorState.document != null) {
        text = _serializer.serialize(widget.editorState.document!);
      } else {
        text = '';
      }

      ref.read(findReplaceProvider.notifier).setContext(
        text,
        onReplace: (newContent) {
          widget.onRawMarkdownChanged(newContent);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: widget.editorState.viewMode == EditorViewMode.source
            ? EditorWidthContainer(
                key: const ValueKey('source_editor'),
                child: SourceModeEditor(
                  content: widget.editorState.rawMarkdown,
                  onChanged: widget.onRawMarkdownChanged,
                  onAutoSave: widget.onAutoSave,
                  initialScrollRatio: widget.editorState.scrollRatio,
                ),
              )
            : widget.editorState.document != null
                ? EditorWidthContainer(
                    key: const ValueKey('markdown_editor'),
                    child: MarkdownEditor(
                      key: widget.editorKey,
                      document: widget.editorState.document!,
                      onChanged: widget.onDocumentChanged,
                      onAutoSave: widget.onAutoSave,
                      initialScrollRatio: widget.editorState.scrollRatio,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty_editor')),
      ),
    );
  }
}
