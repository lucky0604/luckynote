import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/image_provider.dart';
import 'backlinks_panel.dart';
import '../association/association_panel.dart';
import 'editor_content.dart';
import 'editor_empty_state.dart';
import 'editor_toolbar.dart';
import 'find_replace_panel.dart';
import 'markdown_editor.dart';
import 'wikilink_dialog.dart';

/// 编辑器面板
/// 包含工具栏和编辑区域
class EditorPanel extends ConsumerStatefulWidget {
  const EditorPanel({super.key});

  @override
  ConsumerState<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends ConsumerState<EditorPanel> {
  /// 编辑器的 GlobalKey，用于调用编辑器方法
  final GlobalKey<MarkdownEditorState> _editorKey = GlobalKey();

  /// 获取当前编辑器的滚动比例
  double _getCurrentScrollRatio() {
    // 优先从 MarkdownEditor 获取
    final markdownScrollRatio = _editorKey.currentState?.currentScrollRatio;
    if (markdownScrollRatio != null) {
      return markdownScrollRatio;
    }
    // 如果当前是源码模式，返回存储的滚动比例
    return ref.read(editorProvider).scrollRatio;
  }

  /// 显示 WikiLink 对话框并插入链接
  Future<void> _showWikiLinkDialog() async {
    final title = await showWikiLinkDialog(context: context, ref: ref);
    if (title != null) {
      _editorKey.currentState?.insertWikiLink(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final currentNote = editorState.currentNote;

    if (currentNote == null) {
      return const EditorEmptyState();
    }

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // 工具栏
          EditorToolbar(
            noteTitle: currentNote.title,
            isDirty: editorState.isDirty,
            isSaving: editorState.isSaving,
            onSave: () {
              ref.read(editorProvider.notifier).saveCurrentNote();
            },
            getScrollRatio: _getCurrentScrollRatio,
            onInsertImage: (imagePath) async {
              final markdownRef = await ref
                  .read(imageProvider.notifier)
                  .copyImageFromPath(imagePath);
              if (markdownRef != null) {
                // 使用编辑器 key 来插入图片
                _editorKey.currentState?.insertText(markdownRef);
              }
            },
            // 格式化回调
            onBold: () => _editorKey.currentState?.toggleBold(),
            onItalic: () => _editorKey.currentState?.toggleItalic(),
            onStrikethrough: () => _editorKey.currentState?.toggleStrikethrough(),
            onHeading1: () => _editorKey.currentState?.insertHeading(1),
            onHeading2: () => _editorKey.currentState?.insertHeading(2),
            onBulletList: () => _editorKey.currentState?.insertBulletList(),
            onOrderedList: () => _editorKey.currentState?.insertOrderedList(),
            onCode: () => _editorKey.currentState?.insertCodeBlock(),
            onWikiLink: () => _showWikiLinkDialog(),
          ),

          Divider(height: 1, color: AppColors.divider),

          // 查找替换面板
          const FindReplacePanel(),

          // 根据视图模式显示不同的编辑器
          EditorContent(
            editorState: editorState,
            editorKey: _editorKey,
            onRawMarkdownChanged: (markdown) {
              ref.read(editorProvider.notifier).updateRawMarkdown(markdown);
            },
            onAutoSave: () {
              ref.read(editorProvider.notifier).saveCurrentNote();
            },
            onDocumentChanged: () {
              ref.read(editorProvider.notifier).markDirty();
            },
          ),

          // 反向链接面板
          const BacklinksPanel(),

          // 关联面板（未关联的提及和关联图谱）
          const AssociationPanel(),
        ],
      ),
    );
  }
}
