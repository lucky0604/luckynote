import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/core/constants/app_constants.dart';
import 'package:luckynote/core/utils/debouncer.dart';

/// 源码模式编辑器
/// 显示原始 Markdown 文本，支持语法高亮
class SourceModeEditor extends ConsumerStatefulWidget {
  const SourceModeEditor({
    super.key,
    required this.content,
    required this.onChanged,
    this.onAutoSave,
    this.initialScrollRatio = 0.0,
  });

  final String content;
  final void Function(String) onChanged;
  final VoidCallback? onAutoSave;

  /// 初始滚动位置比例 (0.0 ~ 1.0)，用于模式切换时同步滚动
  final double initialScrollRatio;

  @override
  ConsumerState<SourceModeEditor> createState() => _SourceModeEditorState();
}

class _SourceModeEditorState extends ConsumerState<SourceModeEditor> {
  late final TextEditingController _controller;
  late final Debouncer _debouncer;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  bool _hasRestoredScroll = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
    _debouncer = Debouncer(milliseconds: AppConstants.autoSaveDelayMs);
    _focusNode = FocusNode();
    _scrollController = ScrollController();

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

  @override
  void didUpdateWidget(SourceModeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有当外部内容变化且不是由编辑引起时才更新
    if (widget.content != oldWidget.content && widget.content != _controller.text) {
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    widget.onChanged(text);

    // 防抖后自动保存
    _debouncer.run(() {
      widget.onAutoSave?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        // Cmd/Ctrl + S 保存
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyS) {
          final isMac = theme.platform == TargetPlatform.macOS;
          final modifiersPressed = isMac
              ? HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.meta)
              : HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.control);

          if (modifiersPressed) {
            widget.onAutoSave?.call();
          }
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.editorHorizontalPadding,
            vertical: AppConstants.editorVerticalPadding,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            scrollController: _scrollController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            // 光标颜色与主题色一致
            cursorColor: AppColors.accent,
            selectionControls: MaterialTextSelectionControls(),
            // 修复浅黄色背景问题：使用透明背景
            style: TextStyle(
              fontSize: AppConstants.editorFontSize,
              fontFamily: AppConstants.sourceModeFontFamily,
              height: AppConstants.editorLineHeight,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent, // 透明背景，修复浅黄色问题
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: _onChanged,
          ),
        ),
      ),
    );
  }
}
