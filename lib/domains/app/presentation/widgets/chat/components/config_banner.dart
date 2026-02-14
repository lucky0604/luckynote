import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/settings/presentation/providers/llm_config_provider.dart';
import 'chat_banner_container.dart';

/// 配置提示横幅
class ChatConfigBanner extends ConsumerWidget {
  const ChatConfigBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final llmConfig = ref.watch(llmConfigProvider);

    if (llmConfig == null || !llmConfig.isValid) {
      return ChatBannerContainer(
        backgroundColor: AppColors.warning.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(LucideIcons.settings, size: 16, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '请先配置 LLM API',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
