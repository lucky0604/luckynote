import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/database/database.dart';
import 'package:luckynote/domains/shared_infra/providers/database_provider.dart';

/// 笔记列表项组件（Bear风格）
///
/// 显示笔记的标题、预览、修改时间等元数据
class NoteListItem extends ConsumerStatefulWidget {
  const NoteListItem({
    super.key,
    required this.note,
    this.isSelected = false,
    this.onTap,
  });

  /// 笔记数据
  final Note note;

  /// 是否选中
  final bool isSelected;

  /// 点击回调
  final VoidCallback? onTap;

  @override
  ConsumerState<NoteListItem> createState() => _NoteListItemState();
}

class _NoteListItemState extends ConsumerState<NoteListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _getBackgroundColor(theme),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行（粗体，1行 + pin 指示器）
                  _buildTitleRow(theme),
                  const SizedBox(height: 6),

                  // 摘要（灰色，2行）
                  Text(
                    widget.note.preview,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 12,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 标签行（如果有标签）
                  _buildTagsRow(),

                  const SizedBox(height: 8),

                  // 元数据行（时间）
                  _buildMetadataRow(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标题行（包含 pin 指示器）
  Widget _buildTitleRow(ThemeData theme) {
    return Row(
      children: [
        // Pin 指示器（如果是置顶的笔记）
        if (widget.note.isPinned) ...[
          Icon(LucideIcons.pin, size: 12, color: AppColors.accent),
          const SizedBox(width: 6),
        ],
        // 标题
        Expanded(
          child: Text(
            widget.note.title,
            style: TextStyle(
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
              color: widget.isSelected
                  ? AppColors.accent
                  : theme.textTheme.bodyLarge?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 构建标签行
  Widget _buildTagsRow() {
    return FutureBuilder<List<Tag>>(
      future: _loadTags(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: snapshot.data!.map(_buildTagChip).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// 构建标签芯片
  Widget _buildTagChip(Tag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '#${tag.name}',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 加载笔记的标签
  Future<List<Tag>> _loadTags() async {
    try {
      final tagRepo = ref.read(tagRepositoryProvider);
      return await tagRepo.getTagsForNote(widget.note);
    } catch (e) {
      return [];
    }
  }

  /// 构建元数据行（时间）
  Widget _buildMetadataRow(ThemeData theme) {
    return Row(
      children: [
        // 时间图标
        Icon(LucideIcons.clock, size: 12, color: AppColors.textPlaceholder),
        const SizedBox(width: 4),

        // 相对时间
        Text(
          _formatRelativeTime(widget.note.modifiedAt),
          style: TextStyle(color: AppColors.textPlaceholder, fontSize: 11),
        ),
      ],
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor(ThemeData theme) {
    if (widget.isSelected) {
      return AppColors.accent.withValues(alpha: 0.1);
    }
    if (_isHovered) {
      return Colors.white.withValues(alpha: 0.05);
    }
    return Colors.transparent;
  }

  /// 格式化相对时间（如"2小时前"）
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes分钟前';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours小时前';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days天前';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks周前';
    } else {
      final months = difference.inDays ~/ 30;
      return '$months月前';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteListItem && other.note.id == widget.note.id;
  }

  @override
  int get hashCode => widget.note.id.hashCode;
}
