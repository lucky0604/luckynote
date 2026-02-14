import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';

class EditorEmptyState extends StatelessWidget {
  const EditorEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.pencil,
              size: 64,
              color: AppColors.textPlaceholder.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '选择或创建一篇笔记开始写作',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textPlaceholder),
            ),
            const SizedBox(height: 8),
            Text(
              '按 Cmd+N 快速创建新笔记',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPlaceholder.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
