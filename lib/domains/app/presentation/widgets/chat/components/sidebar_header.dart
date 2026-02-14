import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';

/// 聊天侧边栏头部
class ChatSidebarHeader extends ConsumerWidget {
  const ChatSidebarHeader({super.key, this.onClose});

  /// 关闭回调
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPinned = ref.watch(chatIsPinnedProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'AI 助手',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: Icon(
              isPinned ? LucideIcons.pin : LucideIcons.pinOff,
              size: 16,
              color: isPinned ? AppColors.accent : AppColors.textSecondary,
            ),
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).togglePin();
            },
            tooltip: isPinned ? '取消固定' : '固定',
          ),

          IconButton(
            icon: const Icon(LucideIcons.x, size: 16),
            color: AppColors.textSecondary,
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).closeSidebar();
              onClose?.call();
            },
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }
}
