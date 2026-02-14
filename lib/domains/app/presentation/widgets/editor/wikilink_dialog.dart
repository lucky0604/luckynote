import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/association/presentation/providers/wikilink_autocomplete_provider.dart';

/// WikiLink 自动补全对话框
/// 显示笔记标题列表供用户选择
class WikiLinkAutocompleteDialog extends StatelessWidget {
  const WikiLinkAutocompleteDialog({
    super.key,
    required this.onSelected,
  });

  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return _WikiLinkDialogContent(onSelected: onSelected);
  }
}

/// WikiLink 自动补全对话框内容
class _WikiLinkDialogContent extends ConsumerWidget {
  const _WikiLinkDialogContent({
    required this.onSelected,
  });

  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wikiLinkAutocompleteProvider);

    return Container(
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
          _buildHeader(),
          _buildSuggestionsList(state),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
    );
  }

  Widget _buildSuggestionsList(WikiLinkAutocompleteState state) {
    if (state.suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '暂无可用笔记',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPlaceholder,
          ),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: state.suggestions.length,
        itemBuilder: (context, index) {
          final title = state.suggestions[index];
          final isSelected = index == state.selectedIndex;
          return _SuggestionTile(
            title: title,
            isSelected: isSelected,
            onTap: () => onSelected(title),
          );
        },
      ),
    );
  }
}

/// 建议项组件
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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

/// 显示 WikiLink 自动补全对话框
/// 返回选中的笔记标题，如果取消则返回 null
Future<String?> showWikiLinkDialog({
  required BuildContext context,
  required WidgetRef ref,
  Offset? position,
}) async {
  // 计算对话框位置
  final renderBox = context.findRenderObject() as RenderBox?;
  final dialogPosition = position ??
      (renderBox != null
          ? Offset(
              renderBox.size.width / 2 - 150,
              renderBox.size.height / 3,
            )
          : const Offset(100, 100));

  // 触发自动补全
  ref.read(wikiLinkAutocompleteProvider.notifier).trigger('', dialogPosition);

  // 显示对话框
  return showDialog<String>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (ctx) => Stack(
      children: [
        Positioned(
          left: dialogPosition.dx,
          top: dialogPosition.dy,
          child: Material(
            color: Colors.transparent,
            child: WikiLinkAutocompleteDialog(
              onSelected: (title) {
                Navigator.of(ctx).pop(title);
              },
            ),
          ),
        ),
      ],
    ),
  );
}
