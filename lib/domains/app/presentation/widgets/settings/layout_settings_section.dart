import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/settings/presentation/providers/layout_settings_provider.dart';

/// 布局设置组件
class LayoutSettingsSection extends ConsumerWidget {
  const LayoutSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.layout, size: 20),
                const SizedBox(width: 12),
                Text('布局设置', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              context,
              icon: LucideIcons.columns,
              title: '可调整面板宽度',
              description: '拖动分割线可调整侧边栏和笔记列表的宽度',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              context,
              icon: LucideIcons.keyboard,
              title: '快捷键',
              description: '按 Cmd/Ctrl + \\ 可折叠/展开侧边栏',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('重置布局设置'),
                      content: const Text('确定要将面板宽度恢复为默认值吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(layoutSettingsNotifierProvider.notifier)
                                .resetToDefault();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('布局设置已重置')),
                            );
                          },
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: const Text('重置为默认值'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.selectedBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
