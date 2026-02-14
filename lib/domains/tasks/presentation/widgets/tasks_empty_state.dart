import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/tasks_provider.dart';

/// 任务列表空状态组件
class TasksEmptyState extends StatelessWidget {
  const TasksEmptyState({
    super.key,
    required this.filter,
  });

  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filter == TaskFilter.pending
                ? LucideIcons.checkCircle
                : LucideIcons.listTodo,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _getMessage(),
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getMessage() {
    return switch (filter) {
      TaskFilter.pending => '太棒了！没有待办任务',
      TaskFilter.completed => '暂无已完成任务',
      TaskFilter.all => '暂无任务',
    };
  }
}
