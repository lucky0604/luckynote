import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';

import 'package:luckynote/core/constants/app_constants.dart';
import 'package:luckynote/core/utils/debouncer.dart';
import 'package:luckynote/domains/association/data/models/wikilink_attribution.dart';
import 'package:luckynote/domains/editor/presentation/providers/clipboard_image_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/find_replace_provider.dart';
import 'code_block_component.dart';
import 'editor_stylesheet.dart';
import 'keyboard_shortcuts.dart';
import 'latex_component_builder.dart';
import 'markdown_formatting_mixin.dart';
import 'wikilink_dialog.dart';
import 'wikilink_handler.dart';
import 'wikilink_tap_delegate.dart';

/// Markdown 编辑器组件
/// 基于 Super Editor 封装，提供类似 Typora 的编辑体验
class MarkdownEditor extends ConsumerStatefulWidget {
  const MarkdownEditor({
    super.key,
    required this.document,
    required this.onChanged,
    this.onAutoSave,
    this.editorKey,
    this.initialScrollRatio = 0.0,
  });

  final MutableDocument document;
  final VoidCallback onChanged;
  final VoidCallback? onAutoSave;
  final GlobalKey<MarkdownEditorState>? editorKey;

  /// 初始滚动位置比例 (0.0 ~ 1.0)，用于模式切换时同步滚动
  final double initialScrollRatio;

  @override
  ConsumerState<MarkdownEditor> createState() => MarkdownEditorState();
}

class MarkdownEditorState extends ConsumerState<MarkdownEditor>
    with MarkdownFormattingMixin {
  late Editor _editor;
  late MutableDocumentComposer _composer;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  late Debouncer _autoSaveDebouncer;
  late WikiLinkHandler _wikiLinkHandler;
  bool _hasRestoredScroll = false;

  @override
  Editor get editor => _editor;

  @override
  MutableDocumentComposer get composer => _composer;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _composer = MutableDocumentComposer();
    _autoSaveDebouncer = Debouncer(milliseconds: AppConstants.autoSaveDelayMs);
    _wikiLinkHandler = WikiLinkHandler(ref);
    _initEditor();

    // 在首次布局后恢复滚动位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
    });
  }

  void _restoreScrollPosition() {
    if (_hasRestoredScroll) return;
    _hasRestoredScroll = true;

    if (widget.initialScrollRatio > 0 && _scrollController.hasClients) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent > 0) {
        final offset = widget.initialScrollRatio * maxExtent;
        _scrollController.jumpTo(offset);
      }
    }
  }

  /// 获取当前滚动比例
  double get currentScrollRatio {
    if (!_scrollController.hasClients) return 0.0;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return 0.0;
    return _scrollController.offset / maxExtent;
  }

  void _initEditor() {
    _editor = createDefaultDocumentEditor(
      document: widget.document,
      composer: _composer,
    );
    widget.document.addListener(_onDocumentChanged);
  }

  void _onDocumentChanged(DocumentChangeLog changeLog) {
    widget.onChanged();
    _autoSaveDebouncer.run(() {
      widget.onAutoSave?.call();
    });
  }

  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.document != oldWidget.document) {
      oldWidget.document.removeListener(_onDocumentChanged);
      _composer = MutableDocumentComposer();
      _initEditor();
    }
  }

  @override
  void dispose() {
    widget.document.removeListener(_onDocumentChanged);
    _autoSaveDebouncer.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _composer.dispose();
    super.dispose();
  }

  // ==================== 私有方法 ====================

  void _handleNavigateToWikiLink() {
    _wikiLinkHandler.navigateToWikiLinkAtCursor(
      _editor.document,
      _composer.selection,
      context,
    );
  }

  Future<void> _showWikiLinkAutocomplete() async {
    final title = await showWikiLinkDialog(context: context, ref: ref);
    if (title != null) {
      insertWikiLink(title);
    }
  }

  /// 处理图片粘贴
  /// 尝试从剪贴板读取图片，保存到本地并插入 Markdown 引用
  Future<void> _handleImagePaste() async {
    final markdownRef = await ref.read(clipboardImagePasteProvider.notifier).pasteImage();
    if (markdownRef != null) {
      insertText(markdownRef);
    }
  }

  /// 检查位置是否有 WikiLink 并导航
  void _handleDocumentTap(DocumentTapDetails details) {
    final position = details.documentLayout
        .getDocumentPositionNearestToOffset(details.layoutOffset);

    if (position == null) return;

    // 查找节点
    DocumentNode? targetNode;
    for (var i = 0; i < _editor.document.nodeCount; i++) {
      final node = _editor.document.getNodeAt(i);
      if (node != null && node.id == position.nodeId) {
        targetNode = node;
        break;
      }
    }

    if (targetNode is! TextNode) return;

    final offset = position.nodePosition is TextNodePosition
        ? (position.nodePosition as TextNodePosition).offset
        : 0;

    final attributedText = targetNode.text;
    if (offset >= attributedText.length) return;

    // 检查是否有 WikiLink Attribution
    final attributions = attributedText.getAllAttributionsAt(offset);
    for (final attr in attributions) {
      if (attr is WikiLinkAttribution) {
        _wikiLinkHandler.handleTapAtPosition(
          _editor.document,
          position,
          context,
        );
        break;
      }
    }
  }

  /// 打开查找面板
  void _handleFind() {
    ref.read(findReplaceProvider.notifier).toggle();
  }

  @override
  Widget build(BuildContext context) {
    return EditorKeyboardListener(
      onSave: widget.onAutoSave,
      onWikiLinkAutocomplete: _showWikiLinkAutocomplete,
      onNavigateToWikiLink: _handleNavigateToWikiLink,
      onFind: _handleFind,
      onImagePaste: _handleImagePaste,
      onUndo: () => ref.read(editorProvider.notifier).undo(),
      onRedo: () => ref.read(editorProvider.notifier).redo(),
      child: SuperEditor(
        editor: _editor,
        focusNode: _focusNode,
        scrollController: _scrollController,
        stylesheet: EditorStylesheet.build(),
        documentLayoutKey: GlobalKey(),
        gestureMode: DocumentGestureMode.mouse,
        componentBuilders: [
          // 代码块组件构建器（语法高亮）
          CodeBlockComponentBuilder(),
          // LaTeX 组件构建器
          LatexComponentBuilder(),
          // 任务组件构建器
          TaskComponentBuilder(_editor),
          // 默认组件构建器（处理其他标准文档节点）
          ...defaultComponentBuilders,
        ],
        contentTapDelegateFactories: [
          (editContext) => WikiLinkTapDelegate(tapHandler: _handleDocumentTap),
        ],
      ),
    );
  }
}
