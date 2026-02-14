import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/app/router.dart';
import 'package:luckynote/domains/notes/presentation/providers/file_watcher_provider.dart';
import 'ai_assistant_button.dart';
import 'sidebar_menu_item.dart';

class SidebarFooter extends ConsumerWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Divider(
          color: AppColors.sidebarTextSecondary,
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
        const AIAssistantButton(),
        SidebarMenuItem(
          icon: LucideIcons.refreshCw,
          label: '刷新索引',
          onTap: () async {
            await ref.read(fileWatcherProvider.notifier).rescan();
          },
        ),
        SidebarMenuItem(
          icon: LucideIcons.settings,
          label: '设置',
          onTap: () {
            context.push(AppRoutes.settings);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
