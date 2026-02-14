import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/notes/data/repositories/tag_repository.dart';
import 'package:luckynote/domains/notes/presentation/providers/tags_provider.dart';
import 'package:luckynote/domains/navigation/presentation/providers/navigation_provider.dart';

/// 标签区域组件
/// 显示在侧边栏中，用于筛选笔记
class TagsSection extends ConsumerStatefulWidget {
  const TagsSection({super.key});

  @override
  ConsumerState<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends ConsumerState<TagsSection> {
  /// 默认显示的标签数量
  static const int _defaultVisibleCount = 5;

  /// 是否展开全部标签
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tagsState = ref.watch(tagsProvider);
    final activeTags = ref.watch(activeTagsProvider);
    final navState = ref.watch(navigationProvider);

    // 计算显示的标签
    final hasMoreTags = activeTags.length > _defaultVisibleCount;
    final visibleTags = _isExpanded || !hasMoreTags
        ? activeTags
        : activeTags.take(_defaultVisibleCount).toList();
    final hiddenCount = activeTags.length - _defaultVisibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        _buildHeader(),

        // 标签列表（使用 Flexible 适应剩余空间）
        Flexible(
          child: tagsState.isLoading
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.sidebarTextSecondary,
                      ),
                    ),
                  ),
                )
              : activeTags.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        '暂无标签',
                        style: TextStyle(
                          color: AppColors.sidebarTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        ...visibleTags.map(
                          (tagWithCount) => _TagItem(
                            key: ValueKey(tagWithCount.tag.name),
                            tag: tagWithCount,
                            isSelected:
                                navState.selectedTag == tagWithCount.tag.name,
                            onTap: () {
                              ref
                                  .read(navigationProvider.notifier)
                                  .switchToTag(tagWithCount.tag.name);
                            },
                          ),
                        ),
                        // 展开/收起按钮
                        if (hasMoreTags) _buildExpandButton(hiddenCount),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            AnimatedRotation(
              turns: _isExpanded ? 0 : -0.25,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppColors.sidebarTextSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '标签',
              style: TextStyle(
                color: AppColors.sidebarTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandButton(int hiddenCount) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 12,
              color: AppColors.sidebarTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              _isExpanded ? '收起' : '展开更多 ($hiddenCount)',
              style: TextStyle(
                color: AppColors.sidebarTextSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个标签项组件
class _TagItem extends StatefulWidget {
  const _TagItem({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  final TagWithCount tag;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TagItem> createState() => _TagItemState();
}

class _TagItemState extends State<_TagItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : _isHovered
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.hash,
                size: 14,
                color: widget.isSelected
                    ? AppColors.accent
                    : AppColors.sidebarTextSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.tag.tag.name,
                  style: TextStyle(
                    color: widget.isSelected
                        ? AppColors.sidebarText
                        : AppColors.sidebarTextSecondary,
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${widget.tag.noteCount}',
                style: TextStyle(
                  color: AppColors.sidebarTextSecondary.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
