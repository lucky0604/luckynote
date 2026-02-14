import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/notes/data/repositories/tag_repository.dart';

/// 单个标签项组件
class TagListItem extends StatefulWidget {
  const TagListItem({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  final TagWithCount tag;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<TagListItem> createState() => _TagListItemState();
}

class _TagListItemState extends State<TagListItem> {
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