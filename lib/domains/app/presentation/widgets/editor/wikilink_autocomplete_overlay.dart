import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/association/presentation/providers/wikilink_autocomplete_provider.dart';

/// WikiLink 自动补全 Overlay
/// 当用户输入 [[ 时显示笔记标题补全列表
class WikiLinkAutocompleteOverlay extends ConsumerStatefulWidget {
  const WikiLinkAutocompleteOverlay({
    super.key,
    required this.onSelected,
  });

  final void Function(String title) onSelected;

  @override
  ConsumerState<WikiLinkAutocompleteOverlay> createState() =>
      _WikiLinkAutocompleteOverlayState();
}

class _WikiLinkAutocompleteOverlayState
    extends ConsumerState<WikiLinkAutocompleteOverlay> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    final notifier = ref.read(wikiLinkAutocompleteProvider.notifier);

    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      notifier.selectNext();
      _scrollToSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      notifier.selectPrevious();
      _scrollToSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      final selected = notifier.confirmSelection();
      if (selected != null) {
        widget.onSelected(selected);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      notifier.hide();
      Navigator.of(context).pop();
    }
  }

  void _scrollToSelected() {
    final state = ref.read(wikiLinkAutocompleteProvider);
    if (state.selectedIndex >= 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        state.selectedIndex * 40.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wikiLinkAutocompleteProvider);

    if (!state.isVisible || state.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.noteListBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.link, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '链接到笔记',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '↑↓ 选择 Enter 确认',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ),
            // Suggestions list
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: state.suggestions.length,
                itemBuilder: (context, index) {
                  final title = state.suggestions[index];
                  final isSelected = index == state.selectedIndex;
                  return _buildSuggestionTile(title, isSelected);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(String title, bool isSelected) {
    return InkWell(
      onTap: () => widget.onSelected(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectedBackground : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.fileText,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.arrowRight,
                size: 12,
                color: AppColors.textPlaceholder,
              ),
          ],
        ),
      ),
    );
  }
}
