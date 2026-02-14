import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import '../providers/chat_provider.dart';

/// 重试消息按钮组件
/// 当消息发送失败时显示，允许用户重试
class RetryMessageAction extends ConsumerWidget {
  const RetryMessageAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatNotifierProvider);

    if (!chatState.canRetry || chatState.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).retryLastMessage();
            },
            icon: Icon(
              LucideIcons.refreshCw,
              size: 16,
              color: AppColors.accent,
            ),
            label: Text(
              '重试',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
