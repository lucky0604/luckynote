import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';
import 'package:luckynote/domains/navigation/presentation/providers/navigation_provider.dart';
import 'package:luckynote/domains/tasks/presentation/providers/tasks_provider.dart';
import 'package:luckynote/domains/notes/data/repositories/note_repository.dart';

/// 笔记列表头部工具栏
///
/// 包含标题、搜索框、排序按钮
/// 在任务视图下显示任务标题和刷新按钮
class NoteListHeader extends ConsumerWidget {
  const NoteListHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);

    // 任务视图使用不同的头部
    if (navState.isTasksView) {
      return _buildTasksHeader(context, ref);
    }

    final notesState = ref.watch(notesProvider);
    final sortType = notesState.sortType;
    final sortAscending = notesState.sortAscending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 排序按钮
          _buildSortButton(context, ref, sortType, sortAscending),

          const Spacer(),

          // 刷新按钮
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            onPressed: () => ref.read(notesProvider.notifier).refresh(),
            tooltip: '刷新',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建任务视图头部
  Widget _buildTasksHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(LucideIcons.checkSquare, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(
            '任务',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // 刷新按钮
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            onPressed: () => ref.read(tasksProvider.notifier).refresh(),
            tooltip: '刷新',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建排序按钮
  Widget _buildSortButton(
    BuildContext context,
    WidgetRef ref,
    NoteSortType sortType,
    bool sortAscending,
  ) {
    return PopupMenuButton<NoteSortType>(
      icon: Icon(
        _getSortIcon(sortType),
        size: 16,
        color: AppColors.textSecondary,
      ),
      onSelected: (type) {
        ref.read(notesProvider.notifier).setSortType(type);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: NoteSortType.modifiedAt,
          child: Row(
            children: [
              const Text('修改时间'),
              const Spacer(),
              if (sortType == NoteSortType.modifiedAt)
                Icon(LucideIcons.check, size: 14, color: AppColors.accent),
            ],
          ),
        ),
        PopupMenuItem(
          value: NoteSortType.createdAt,
          child: Row(
            children: [
              const Text('创建时间'),
              const Spacer(),
              if (sortType == NoteSortType.createdAt)
                Icon(LucideIcons.check, size: 14, color: AppColors.accent),
            ],
          ),
        ),
        PopupMenuItem(
          value: NoteSortType.title,
          child: Row(
            children: [
              const Text('标题'),
              const Spacer(),
              if (sortType == NoteSortType.title)
                Icon(LucideIcons.check, size: 14, color: AppColors.accent),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            ref.read(notesProvider.notifier).toggleSortDirection();
          },
          child: Row(
            children: [
              Text(sortAscending ? '降序' : '升序'),
              Icon(
                sortAscending ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
      tooltip: '排序',
    );
  }

  /// 获取排序图标
  IconData _getSortIcon(NoteSortType type) {
    switch (type) {
      case NoteSortType.modifiedAt:
        return LucideIcons.clock;
      case NoteSortType.createdAt:
        return LucideIcons.calendar;
      case NoteSortType.title:
        return LucideIcons.type;
    }
  }
}
