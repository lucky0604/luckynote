import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/domains/navigation/data/models/navigation_state.dart';
import 'package:luckynote/domains/navigation/presentation/providers/navigation_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';
import 'package:luckynote/domains/tasks/presentation/providers/tasks_provider.dart';
import 'sidebar_menu_item.dart';

class SidebarMenu extends ConsumerWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesCountAsync = ref.watch(allNotesCountProvider);
    final notesCount = notesCountAsync.valueOrNull ?? 0;
    final navState = ref.watch(navigationProvider);

    return Column(
      children: [
        SidebarMenuItem(
          icon: LucideIcons.fileText,
          label: '所有笔记',
          count: notesCount > 0 ? notesCount : null,
          isSelected: navState.filterType == NavigationFilterType.all,
          onTap: () {
            ref.read(navigationProvider.notifier).switchToAllNotes();
          },
        ),
        SidebarMenuItem(
          icon: LucideIcons.pin,
          label: '已置顶',
          isSelected: navState.filterType == NavigationFilterType.favorites,
          onTap: () {
            ref.read(navigationProvider.notifier).switchToFavorites();
          },
        ),
        SidebarMenuItem(
          icon: LucideIcons.folder,
          label: '文件夹',
          isSelected: navState.isTreeView,
          onTap: () {
            ref.read(navigationProvider.notifier).switchToFolderTree();
          },
        ),
        Consumer(
          builder: (context, ref, _) {
            final tasksAsync = ref.watch(sidebarTasksProvider);
            final count = tasksAsync.valueOrNull?.length ?? 0;
            return SidebarMenuItem(
              icon: LucideIcons.checkSquare,
              label: '任务',
              count: count > 0 ? count : null,
              isSelected: navState.filterType == NavigationFilterType.tasks,
              onTap: () {
                ref.read(navigationProvider.notifier).switchToTasks();
              },
            );
          },
        ),
      ],
    );
  }
}
