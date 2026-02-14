import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/tasks_provider.dart';

/// 任务筛选栏组件
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.currentFilter,
    required this.taskCount,
    required this.onFilterChanged,
  });

  final TaskFilter currentFilter;
  final int taskCount;
  final void Function(TaskFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          TaskFilterChip(
            label: '待完成',
            isSelected: currentFilter == TaskFilter.pending,
            onTap: () => onFilterChanged(TaskFilter.pending),
          ),
          const SizedBox(width: 8),
          TaskFilterChip(
            label: '已完成',
            isSelected: currentFilter == TaskFilter.completed,
            onTap: () => onFilterChanged(TaskFilter.completed),
          ),
          const SizedBox(width: 8),
          TaskFilterChip(
            label: '全部',
            isSelected: currentFilter == TaskFilter.all,
            onTap: () => onFilterChanged(TaskFilter.all),
          ),
          const Spacer(),
          // 任务计数
          Text(
            '$taskCount 项',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个筛选 Chip
class TaskFilterChip extends StatelessWidget {
  const TaskFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
