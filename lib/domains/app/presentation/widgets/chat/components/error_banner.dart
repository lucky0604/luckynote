import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';
import 'chat_banner_container.dart';

/// 错误提示横幅
class ChatErrorBanner extends ConsumerWidget {
  const ChatErrorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(chatErrorProvider);

    if (error == null) return const SizedBox.shrink();

    return ChatBannerContainer(
      backgroundColor: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              error,
              style: TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.textSecondary,
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).clearError();
            },
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }
}
