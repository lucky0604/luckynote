import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/domains/chat/data/models/chat_context.dart';

/// 上下文气泡组件
///
/// 根据 ai_chat.md 规格设计：
/// - 圆角矩形，背景色根据类型变化
/// - 🟦 Current Note: 淡蓝色背景 + 文件图标
/// - 🟨 Folder: 淡黄色背景 + 文件夹图标
/// - 🟩 Tag: 淡绿色背景 + Hash 图标
class ContextChip extends StatelessWidget {
  const ContextChip({
    super.key,
    required this.context,
    this.onRemove,
  });

  /// 上下文数据
  final ChatContext context;

  /// 移除回调
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 14,
            color: colors.foreground,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              this.context.displayName,
              style: TextStyle(
                fontSize: 12,
                color: colors.foreground,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 2),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                LucideIcons.x,
                size: 12,
                color: colors.foreground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    return this.context.icon ?? _getDefaultIcon();
  }

  IconData _getDefaultIcon() {
    switch (this.context.type) {
      case ContextType.note:
        return LucideIcons.fileText;
      case ContextType.folder:
        return LucideIcons.folder;
      case ContextType.tag:
        return LucideIcons.hash;
      case ContextType.all:
        return LucideIcons.database;
    }
  }

  _ChipColors _getColors() {
    switch (this.context.type) {
      case ContextType.note:
        return _ChipColors(
          background: const Color(0xFFE3F2FD),
          border: const Color(0xFF90CAF9),
          foreground: const Color(0xFF1565C0),
        );
      case ContextType.folder:
        return _ChipColors(
          background: const Color(0xFFFFF8E1),
          border: const Color(0xFFFFE082),
          foreground: const Color(0xFFF57C00),
        );
      case ContextType.tag:
        return _ChipColors(
          background: const Color(0xFFE8F5E9),
          border: const Color(0xFFA5D6A7),
          foreground: const Color(0xFF2E7D32),
        );
      case ContextType.all:
        return _ChipColors(
          background: const Color(0xFFF3E5F5),
          border: const Color(0xFFCE93D8),
          foreground: const Color(0xFF7B1FA2),
        );
    }
  }
}

/// Chip 颜色配置
class _ChipColors {
  const _ChipColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
