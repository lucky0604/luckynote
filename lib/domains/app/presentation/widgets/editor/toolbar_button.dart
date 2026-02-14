import 'package:flutter/material.dart';
import 'package:luckynote/app/theme/app_colors.dart';

/// 工具栏按钮组件
class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 16,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(
        foregroundColor: isActive ? AppColors.accent : AppColors.textSecondary,
        backgroundColor: isActive ? AppColors.hoverBackground : null,
        hoverColor: AppColors.hoverBackground,
        disabledForegroundColor: AppColors.textPlaceholder.withValues(alpha: 0.5),
      ),
    );
  }
}
