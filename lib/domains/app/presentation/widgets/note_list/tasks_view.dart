import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/database/database.dart';
import 'package:luckynote/domains/tasks/presentation/providers/tasks_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';

/// 任务主视图
/// 显示所有任务，支持筛选（未完成/已完成/全部）
class TasksView extends ConsumerWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);

    return Column(
      children: [
        // 筛选栏
        _buildFilterBar(context, ref, tasksState),
        const Divider(height: 1),
        // 任务列表
        Expanded(
          child: _buildTasksList(context, ref, tasksState),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, TasksState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: '待完成',
            isSelected: state.filter == TaskFilter.pending,
            onTap: () => ref.read(tasksProvider.notifier).setFilter(TaskFilter.pending),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '已完成',
            isSelected: state.filter == TaskFilter.completed,
            onTap: () => ref.read(tasksProvider.notifier).setFilter(TaskFilter.completed),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '全部',
            isSelected: state.filter == TaskFilter.all,
            onTap: () => ref.read(tasksProvider.notifier).setFilter(TaskFilter.all),
          ),
          const Spacer(),
          // 任务计数
          Text(
            '${state.tasks.length} 项',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, WidgetRef ref, TasksState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(tasksProvider.notifier).refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.filter == TaskFilter.pending
                  ? LucideIcons.checkCircle
                  : LucideIcons.listTodo,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              state.filter == TaskFilter.pending
                  ? '太棒了！没有待办任务'
                  : state.filter == TaskFilter.completed
                      ? '暂无已完成任务'
                      : '暂无任务',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.tasks.length,
      itemBuilder: (context, index) {
        final task = state.tasks[index];
        return _TaskListItem(
          task: task,
          onTap: () => ref.read(editorProvider.notifier).openNoteByPath(task.filePath),
          onToggle: () => ref.read(tasksProvider.notifier).toggleTask(task.id),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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

class _TaskListItem extends StatefulWidget {
  const _TaskListItem({
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  final TaskWithDocument task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  State<_TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<_TaskListItem> {
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
              GestureDetector(
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
              ),
              const SizedBox(width: 12),
              // 任务内容和来源
              Expanded(
                child: Column(
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
                ),
              ),
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
}
