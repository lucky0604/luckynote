import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/data/models/chat_context.dart';
import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';
import 'package:luckynote/domains/chat/presentation/providers/mention_provider.dart';
import 'context_chip.dart';

/// 胶囊输入框组件
///
/// 根据 ai_chat.md 规格设计的悬浮式输入框
/// - 形状: StadiumBorder (两端半圆)
/// - 阴影: BoxShadow(blurRadius: 10)
/// - 支持 @ 引用系统
class CapsuleInput extends ConsumerStatefulWidget {
  const CapsuleInput({
    super.key,
    this.onSend,
    this.onAtTriggered,
  });

  /// 发送回调
  final void Function(String text, List<ChatContext> contexts)? onSend;

  /// @ 触发回调
  final void Function(String query, Offset position)? onAtTriggered;

  @override
  ConsumerState<CapsuleInput> createState() => _CapsuleInputState();
}

class _CapsuleInputState extends ConsumerState<CapsuleInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final hasContent = text.trim().isNotEmpty;

    if (hasContent != _hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
    }

    // 检测 @ 符号
    _detectAtSymbol(text);
  }

  void _detectAtSymbol(String text) {
    final cursorPosition = _controller.selection.baseOffset;
    if (cursorPosition <= 0) return;

    // 查找光标前最近的 @ 符号
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) {
      ref.read(mentionProvider.notifier).hide();
      return;
    }

    // 检查 @ 后是否有空格（有空格则不触发）
    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ')) {
      ref.read(mentionProvider.notifier).hide();
      return;
    }

    // 触发 @ 建议
    final query = textAfterAt;
    widget.onAtTriggered?.call(query, _getCaretPosition());
    ref.read(mentionProvider.notifier).trigger(query, _getCaretPosition());
  }

  Offset _getCaretPosition() {
    // 简单返回输入框位置，实际可以根据光标计算精确位置
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    return renderBox.localToGlobal(Offset.zero);
  }

  /// 处理提及选择
  void handleMentionSelection(ChatContext selectedContext) {
    // 替换 @query 为上下文
    final text = _controller.text;
    final cursorPosition = _controller.selection.baseOffset;
    if (cursorPosition <= 0) return;

    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) return;

    // 移除 @query
    final newText = text.substring(0, lastAtIndex) + text.substring(cursorPosition);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: lastAtIndex);

    // 添加上下文
    ref.read(chatNotifierProvider.notifier).addContext(selectedContext);

    // 隐藏提及建议
    ref.read(mentionProvider.notifier).hide();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final contexts = ref.read(chatActiveContextsProvider);

    _controller.clear();
    _focusNode.requestFocus();

    // 调用回调或直接发送
    if (widget.onSend != null) {
      widget.onSend!(text, contexts);
    } else {
      await ref.read(chatNotifierProvider.notifier).sendMessage(text);
    }

    // 清空上下文
    ref.read(chatNotifierProvider.notifier).clearContexts();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(chatLoadingProvider);
    final activeContexts = ref.watch(chatActiveContextsProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 上下文气泡
          if (activeContexts.isNotEmpty)
            _buildContextChips(activeContexts),

          // 输入区域
          _buildInputRow(isLoading),
        ],
      ),
    );
  }

  Widget _buildContextChips(List<ChatContext> contexts) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: contexts.map((ctx) {
          return ContextChip(
            context: ctx,
            onRemove: () {
              ref.read(chatNotifierProvider.notifier).removeContext(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputRow(bool isLoading) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 附件按钮
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: IconButton(
            icon: Icon(
              LucideIcons.plus,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              // TODO: 实现附件功能
            },
            tooltip: '添加附件',
          ),
        ),

        // 输入框
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              decoration: InputDecoration(
                hintText: '向 AI 提问... (使用 @ 引用笔记)',
                hintStyle: TextStyle(color: AppColors.textPlaceholder),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              maxLines: null,
              enabled: !isLoading,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              inputFormatters: [
                // 允许 Shift+Enter 换行，Enter 发送
              ],
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),

        // 发送按钮
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: _buildSendButton(isLoading),
        ),
      ],
    );
  }

  Widget _buildSendButton(bool isLoading) {
    if (isLoading) {
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      );
    }

    return Material(
      color: _hasContent ? AppColors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _hasContent ? _sendMessage : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.arrowUp,
            size: 18,
            color: _hasContent ? Colors.white : AppColors.textPlaceholder,
          ),
        ),
      ),
    );
  }
}
