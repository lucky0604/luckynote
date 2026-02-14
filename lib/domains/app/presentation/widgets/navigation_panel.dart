import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/navigation/presentation/providers/navigation_provider.dart';
import 'navigation_content.dart';
import 'navigation_header.dart';

/// 多态导航面板
///
/// 根据NavigationProvider的viewType切换显示不同视图：
/// - List View -> NoteListView（含工具栏）
/// - Tree View -> FileTreeView（文件树，无工具栏）
/// - Tasks View -> TasksView（任务列表视图）
class NavigationPanel extends ConsumerWidget {
  const NavigationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);

    return Container(
      color: AppColors.noteListBackground,
      child: Column(
        children: [
          // 导航栏头部（列表视图和任务视图显示标题和工具）
          NavigationHeader(navState: navState),

          // 内容区域（根据viewType切换）
          Expanded(
            child: NavigationContent(navState: navState),
          ),
        ],
      ),
    );
  }
}
