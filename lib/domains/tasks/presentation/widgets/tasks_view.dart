import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tasks_provider.dart';
import 'task_filter_bar.dart';
import 'task_list_item.dart';
import 'tasks_empty_state.dart';
import 'tasks_error_state.dart';

/// 任务主视图
/// 显示所有任务，支持筛选（未完成/已完成/全部）
class TasksView extends ConsumerWidget {
  const TasksView({
    super.key,
    required this.onOpenNote,
  });

  /// 打开笔记的回调，由外部提供以解耦 editor 依赖
  final void Function(String filePath) onOpenNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);

    return Column(
      children: [
        // 筛选栏
        TaskFilterBar(
          currentFilter: tasksState.filter,
          taskCount: tasksState.tasks.length,
          onFilterChanged: (filter) {
            ref.read(tasksProvider.notifier).setFilter(filter);
          },
        ),
        const Divider(height: 1),
        // 任务列表
        Expanded(
          child: _buildTasksList(context, ref, tasksState),
        ),
      ],
    );
  }

  Widget _buildTasksList(BuildContext context, WidgetRef ref, TasksState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return TasksErrorState(
        error: state.error!,
        onRetry: () => ref.read(tasksProvider.notifier).refresh(),
      );
    }

    if (state.tasks.isEmpty) {
      return TasksEmptyState(filter: state.filter);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.tasks.length,
      itemBuilder: (context, index) {
        final task = state.tasks[index];
        return TaskListItem(
          task: task,
          onTap: () => onOpenNote(task.filePath),
          onToggle: () => ref.read(tasksProvider.notifier).toggleTask(task.id),
        );
      },
    );
  }
}
