import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/settings/data/models/theme_model.dart';
import 'package:luckynote/domains/settings/presentation/providers/theme_provider.dart';

/// 主题选择器组件
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.palette, size: 20),
                const SizedBox(width: 12),
                Text('主题', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              context,
              ref,
              title: '跟随系统',
              icon: LucideIcons.monitor,
              themeType: AppThemeType.system,
              isSelected: currentTheme == AppThemeType.system,
            ),
            _buildThemeOption(
              context,
              ref,
              title: '温暖白昼',
              icon: LucideIcons.sun,
              themeType: AppThemeType.warmLight,
              isSelected: currentTheme == AppThemeType.warmLight,
            ),
            _buildThemeOption(
              context,
              ref,
              title: '清新森林',
              icon: LucideIcons.leaf,
              themeType: AppThemeType.freshForest,
              isSelected: currentTheme == AppThemeType.freshForest,
            ),
            _buildThemeOption(
              context,
              ref,
              title: '暗黑模式',
              icon: LucideIcons.moon,
              themeType: AppThemeType.dark,
              isSelected: currentTheme == AppThemeType.dark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required AppThemeType themeType,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => ref.read(themeNotifierProvider.notifier).setTheme(themeType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.selectedBackground : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.check, size: 18, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
