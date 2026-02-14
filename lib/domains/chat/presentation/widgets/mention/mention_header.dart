import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../app/theme/app_colors.dart';

/// 提及弹窗头部组件
class MentionHeader extends StatelessWidget {
  const MentionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: AppColors.hoverBackground.withValues(alpha: 0.5),
      child: Row(
        children: [
          Icon(LucideIcons.atSign, size: 14, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '选择引用',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
