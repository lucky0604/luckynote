import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../database/database.dart';

/// 任务列表项组件
class TaskListItem extends StatefulWidget {
  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  final TaskWithDocument task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.noteListBackground.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered ? AppColors.border : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              _buildCheckbox(),
              const SizedBox(width: 12),
              // 任务内容和来源
              Expanded(child: _buildContent()),
              // 跳转箭头
              if (_isHovered)
                Icon(
                  LucideIcons.arrowRight,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return GestureDetector(
      onTap: widget.onToggle,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.task.isCompleted
                ? AppColors.accent
                : AppColors.textSecondary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
          color: widget.task.isCompleted ? AppColors.accent : Colors.transparent,
        ),
        child: widget.task.isCompleted
            ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.task.content,
          style: TextStyle(
            color: widget.task.isCompleted
                ? AppColors.textSecondary.withValues(alpha: 0.6)
                : AppColors.textPrimary,
            fontSize: 14,
            decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              LucideIcons.fileText,
              size: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.task.documentTitle,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
