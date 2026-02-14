import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';

/// 聊天空状态组件
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: 48,
            color: AppColors.textPlaceholder,
          ),
          const SizedBox(height: 16),
          Text(
            '开始对话',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '向 AI 提问或使用快捷操作',
            style: TextStyle(fontSize: 13, color: AppColors.textPlaceholder),
          ),
        ],
      ),
    );
  }
}
