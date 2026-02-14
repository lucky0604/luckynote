import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import '../../data/models/chat_attachment.dart';

/// 附件显示芯片
class AttachmentChip extends StatelessWidget {
  const AttachmentChip({
    super.key,
    required this.attachment,
    this.onRemove,
  });

  final ChatAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 预览或图标
          _buildPreview(),

          // 名称
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                attachment.name,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // 删除按钮
          if (onRemove != null)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (attachment.type == AttachmentType.image &&
        attachment.previewUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          bottomLeft: Radius.circular(7),
        ),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Image.file(
            File(attachment.previewUrl!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildIconPreview(),
          ),
        ),
      );
    }
    return _buildIconPreview();
  }

  Widget _buildIconPreview() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          bottomLeft: Radius.circular(7),
        ),
      ),
      child: Icon(
        attachment.icon,
        size: 18,
        color: AppColors.accent,
      ),
    );
  }
}
