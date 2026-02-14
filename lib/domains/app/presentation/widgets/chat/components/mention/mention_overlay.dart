import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/data/models/chat_context.dart';
import 'package:luckynote/domains/chat/data/models/mention_item.dart';
import 'package:luckynote/domains/chat/presentation/providers/mention_provider.dart';
import 'mention_item_tile.dart';

/// @ 提及建议 Overlay
///
/// 根据 ai_chat.md 规格设计：
/// - 在输入框上方弹出浮层菜单
/// - 支持键盘上下选择
/// - 支持回车/点击确认
class MentionOverlay extends ConsumerWidget {
  const MentionOverlay({
    super.key,
    required this.onSelect,
    this.maxHeight = 300,
  });

  /// 选择回调
  final void Function(MentionItem item, ChatContext context) onSelect;

  /// 最大高度
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionState = ref.watch(mentionProvider);

    if (!mentionState.isVisible || mentionState.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.cardBackground,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 320,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              _buildHeader(context),

              // 分割线
              Divider(height: 1, color: AppColors.divider),

              // 建议列表
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: mentionState.suggestions.length,
                  itemBuilder: (context, index) {
                    final item = mentionState.suggestions[index];
                    final isSelected = index == mentionState.selectedIndex;

                    return MentionItemTile(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => _handleSelect(ref, item),
                      showCheckIndicator: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            LucideIcons.atSign,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            '选择上下文',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '↑↓ 选择  ↵ 确认',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textPlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSelect(WidgetRef ref, MentionItem item) {
    final notifier = ref.read(mentionProvider.notifier);
    final chatContext = notifier.mentionToContext(item);

    if (chatContext != null) {
      onSelect(item, chatContext);
    }

    notifier.hide();
  }
}

/// @ 提及 Overlay 入口点组件
///
/// 包装输入框和建议列表，处理键盘事件
class MentionOverlayWrapper extends ConsumerStatefulWidget {
  const MentionOverlayWrapper({
    super.key,
    required this.child,
    required this.onMentionSelect,
  });

  /// 子组件（输入框）
  final Widget child;

  /// 提及选择回调
  final void Function(ChatContext context) onMentionSelect;

  @override
  ConsumerState<MentionOverlayWrapper> createState() =>
      _MentionOverlayWrapperState();
}

class _MentionOverlayWrapperState extends ConsumerState<MentionOverlayWrapper> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    final isVisible = ref.read(mentionProvider).isVisible;

    if (isVisible && _overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else if (!isVisible && _overlayEntry != null) {
      _removeOverlay();
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -8),
          followerAnchor: Alignment.bottomLeft,
          targetAnchor: Alignment.topLeft,
          child: MentionOverlay(
            onSelect: (item, chatContext) {
              widget.onMentionSelect(chatContext);
              _removeOverlay();
            },
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final mentionState = ref.read(mentionProvider);
    if (!mentionState.isVisible) return KeyEventResult.ignored;

    final notifier = ref.read(mentionProvider.notifier);

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      notifier.selectPrevious();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      notifier.selectNext();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      final selected = notifier.confirmSelection();
      if (selected != null) {
        final chatContext = notifier.mentionToContext(selected);
        if (chatContext != null) {
          widget.onMentionSelect(chatContext);
        }
      }
      _removeOverlay();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      notifier.hide();
      _removeOverlay();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // 监听 mention 状态变化
    ref.listen(mentionProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateOverlay();
      });
    });

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: widget.child,
      ),
    );
  }
}
