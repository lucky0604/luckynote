import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/editor/presentation/providers/find_replace_provider.dart';
import 'find_replace_input.dart';

/// 查找替换面板
class FindReplacePanel extends ConsumerStatefulWidget {
  const FindReplacePanel({super.key});

  @override
  ConsumerState<FindReplacePanel> createState() => _FindReplacePanelState();
}

class _FindReplacePanelState extends ConsumerState<FindReplacePanel> {
  final _searchController = TextEditingController();
  final _replaceController = TextEditingController();
  bool _showReplace = false;

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(findReplaceProvider);

    if (!state.isOpen) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 搜索行
          _buildSearchRow(state),

          // 替换行（可展开）
          if (_showReplace) ...[
            const SizedBox(height: 8),
            _buildReplaceRow(state),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchRow(FindReplaceState state) {
    return Row(
      children: [
        // 展开/收起替换
        _buildToggleReplaceButton(),
        const SizedBox(width: 8),

        // 搜索输入框
        Expanded(
          child: FindReplaceInput(
            controller: _searchController,
            hintText: '查找',
            autofocus: true,
            onChanged: (value) {
              ref.read(findReplaceProvider.notifier).search(value);
            },
            onSubmitted: (_) {
              ref.read(findReplaceProvider.notifier).next();
            },
            trailing: _buildSearchTrailing(state),
          ),
        ),
        const SizedBox(width: 8),

        // 导航按钮
        FindNavigationButton(
          icon: LucideIcons.chevronUp,
          tooltip: '上一个 (Shift+Enter)',
          onPressed: () => ref.read(findReplaceProvider.notifier).previous(),
          enabled: state.hasMatches,
        ),
        FindNavigationButton(
          icon: LucideIcons.chevronDown,
          tooltip: '下一个 (Enter)',
          onPressed: () => ref.read(findReplaceProvider.notifier).next(),
          enabled: state.hasMatches,
        ),
        const SizedBox(width: 8),

        // 关闭按钮
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildReplaceRow(FindReplaceState state) {
    return Row(
      children: [
        const SizedBox(width: 32), // 对齐搜索行
        Expanded(
          child: FindReplaceInput(
            controller: _replaceController,
            hintText: '替换',
            onChanged: (value) {
              ref.read(findReplaceProvider.notifier).setReplaceTerm(value);
            },
          ),
        ),
        const SizedBox(width: 8),

        // 替换按钮
        _buildActionButton(
          label: '替换',
          onPressed: state.currentMatch != null
              ? () => ref.read(findReplaceProvider.notifier).replaceCurrent()
              : null,
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          label: '全部替换',
          onPressed: state.hasMatches
              ? () => ref.read(findReplaceProvider.notifier).replaceAll()
              : null,
        ),
      ],
    );
  }

  Widget _buildToggleReplaceButton() {
    return InkWell(
      onTap: () => setState(() => _showReplace = !_showReplace),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          _showReplace ? LucideIcons.chevronDown : LucideIcons.chevronRight,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSearchTrailing(FindReplaceState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 结果计数
        if (state.searchTerm.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              state.countText,
              style: TextStyle(
                fontSize: 12,
                color: state.hasMatches
                    ? AppColors.textSecondary
                    : AppColors.error,
              ),
            ),
          ),

        // 大小写敏感按钮
        Tooltip(
          message: '区分大小写',
          child: InkWell(
            onTap: () =>
                ref.read(findReplaceProvider.notifier).toggleCaseSensitive(),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: state.caseSensitive
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: state.caseSensitive
                      ? AppColors.accent
                      : AppColors.textPlaceholder,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildCloseButton() {
    return InkWell(
      onTap: () => ref.read(findReplaceProvider.notifier).close(),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          LucideIcons.x,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: onPressed != null ? AppColors.accent : AppColors.textPlaceholder,
        ),
      ),
    );
  }
}
