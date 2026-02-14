import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luckynote/domains/chat/data/models/chat_context.dart';
import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';
import 'package:luckynote/domains/chat/presentation/providers/mention_provider.dart';
import 'chat_input_context_chips.dart';
import 'chat_input_row.dart';
import 'mention/mention_popup.dart';

/// 聊天输入区域 - 集成 @ 提及功能
class ChatInputArea extends ConsumerStatefulWidget {
  const ChatInputArea({super.key});
  @override
  ConsumerState<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends ConsumerState<ChatInputArea> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasContent = _controller.text.trim().isNotEmpty;
    if (hasContent != _hasContent) setState(() => _hasContent = hasContent);
    _detectAtSymbol(_controller.text);
  }

  void _detectAtSymbol(String text) {
    final cursor = _controller.selection.baseOffset;
    if (cursor <= 0) { _hideOverlay(); return; }

    final beforeCursor = text.substring(0, cursor);
    final atIdx = beforeCursor.lastIndexOf('@');
    if (atIdx == -1) { _hideOverlay(); return; }

    final afterAt = beforeCursor.substring(atIdx + 1);
    if (afterAt.contains(' ') || afterAt.contains('\n')) { _hideOverlay(); return; }

    ref.read(mentionProvider.notifier).trigger(afterAt, Offset.zero);
    _showOverlay();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -8),
          followerAnchor: Alignment.bottomLeft,
          targetAnchor: Alignment.topLeft,
          child: MentionPopup(onSelect: _handleMentionSelect, onDismiss: _hideOverlay),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    ref.read(mentionProvider.notifier).hide();
    _removeOverlay();
  }

  void _removeOverlay() { _overlayEntry?.remove(); _overlayEntry = null; }

  void _handleMentionSelect(ChatContext ctx) {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    if (cursor <= 0) return;

    final atIdx = text.substring(0, cursor).lastIndexOf('@');
    if (atIdx == -1) return;

    _controller.text = text.substring(0, atIdx) + text.substring(cursor);
    _controller.selection = TextSelection.collapsed(offset: atIdx);
    ref.read(chatNotifierProvider.notifier).addContext(ctx);
    _hideOverlay();
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final mentionState = ref.read(mentionProvider);
    if (!mentionState.isVisible) {
      if (event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isShiftPressed) {
        _sendMessage();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final notifier = ref.read(mentionProvider.notifier);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        notifier.selectPrevious();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        notifier.selectNext();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.tab:
        final selected = notifier.confirmSelection();
        if (selected != null) {
          final chatCtx = notifier.mentionToContext(selected);
          if (chatCtx != null) _handleMentionSelect(chatCtx);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        _hideOverlay();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _focusNode.requestFocus();
    await ref.read(chatNotifierProvider.notifier).sendMessage(text);
    ref.read(chatNotifierProvider.notifier).clearContexts();
  }

  void _insertAtSymbol() {
    final sel = _controller.selection;
    _controller.text = _controller.text.replaceRange(sel.start, sel.end, '@');
    _controller.selection = TextSelection.collapsed(offset: sel.start + 1);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(chatLoadingProvider);
    final activeContexts = ref.watch(chatActiveContextsProvider);

    ref.listen(mentionProvider, (prev, next) {
      if (prev?.isVisible == true && !next.isVisible) _removeOverlay();
    });

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeContexts.isNotEmpty)
                ChatInputContextChips(
                  contexts: activeContexts,
                  onRemove: (contextItem) {
                    ref
                        .read(chatNotifierProvider.notifier)
                        .removeContext(contextItem);
                  },
                ),
              ChatInputRow(
                controller: _controller,
                focusNode: _focusNode,
                hasContent: _hasContent,
                isLoading: isLoading,
                onInsertAt: _insertAtSymbol,
                onSend: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
