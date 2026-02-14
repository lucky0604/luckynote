import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';

/// 提及弹窗底部组件（快捷键提示）
class MentionFooter extends StatelessWidget {
  const MentionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.hoverBackground.withValues(alpha: 0.3),
      child: Row(
        children: [
          _buildKeyHint('↑↓', '选择'),
          const SizedBox(width: 12),
          _buildKeyHint('↵', '确认'),
          const SizedBox(width: 12),
          _buildKeyHint('esc', '取消'),
        ],
      ),
    );
  }

  Widget _buildKeyHint(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            key,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textPlaceholder),
        ),
      ],
    );
  }
}
