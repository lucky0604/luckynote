import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/database/database.dart';
import 'package:luckynote/domains/tasks/presentation/providers/tasks_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'package:luckynote/domains/navigation/presentation/providers/navigation_provider.dart';

/// 侧边栏任务概览组件
/// 显示未完成任务的精简列表（最多10条），提供"查看全部"入口
class TasksSection extends ConsumerWidget {
  const TasksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用流式数据实现实时更新
    final tasksAsync = ref.watch(sidebarTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref, tasksAsync),
        Flexible(
          child: tasksAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '加载失败',
                style: TextStyle(
                  color: AppColors.sidebarTextSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            data: (tasks) {
              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '暂无待办任务',
                    style: TextStyle(
                      color: AppColors.sidebarTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _TaskItem(
                          key: ValueKey(task.id),
                          task: task,
                          onTap: () => ref
                              .read(editorProvider.notifier)
                              .openNoteByPath(task.filePath),
                          onToggle: () => ref
                              .read(tasksProvider.notifier)
                              .toggleTask(task.id),
                        );
                      },
                    ),
                  ),
                  // 查看全部入口
                  _buildViewAllButton(context, ref),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AsyncValue<List<TaskWithDocument>> tasksAsync) {
    final count = tasksAsync.valueOrNull?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(LucideIcons.checkSquare, size: 14, color: AppColors.sidebarTextSecondary),
          const SizedBox(width: 8),
          Text('待办任务', style: TextStyle(color: AppColors.sidebarTextSecondary, fontSize: 12)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(navigationProvider.notifier).switchToTasks();
          },
          borderRadius: BorderRadius.circular(6),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.arrowRight, size: 12, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  '查看全部任务',
                  style: TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskItem extends StatefulWidget {
  const _TaskItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  final TaskWithDocument task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  State<_TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<_TaskItem> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onToggle,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.task.isCompleted
                          ? AppColors.accent
                          : AppColors.sidebarTextSecondary,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    color: widget.task.isCompleted ? AppColors.accent : Colors.transparent,
                  ),
                  child: widget.task.isCompleted
                      ? const Icon(LucideIcons.check, size: 10, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.content,
                      style: TextStyle(
                        color: widget.task.isCompleted
                            ? AppColors.sidebarTextSecondary.withValues(alpha: 0.6)
                            : AppColors.sidebarText,
                        fontSize: 13,
                        decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.task.documentTitle,
                      style: TextStyle(
                        color: AppColors.sidebarTextSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
