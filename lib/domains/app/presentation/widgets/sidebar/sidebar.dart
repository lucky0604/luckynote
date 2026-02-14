import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'sidebar_footer.dart';
import 'sidebar_header.dart';
import 'sidebar_menu.dart';
import 'sidebar_sections.dart';

/// 侧边栏组件
/// 显示标签列表、设置入口等
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo 和应用名
          const SidebarHeader(),

          Divider(
            color: AppColors.sidebarTextSecondary,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),

          const SizedBox(height: 8),

          // 快捷菜单
          const SidebarMenu(),

          const SizedBox(height: 8),

          Divider(
            color: AppColors.sidebarTextSecondary,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),

          const SizedBox(height: 8),

          // 任务概览和标签区域
          const SidebarSections(),

          // 底部操作
          const SidebarFooter(),
        ],
      ),
    );
  }
}
