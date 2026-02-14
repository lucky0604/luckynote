import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../data/models/mention_item.dart';

/// 提及建议条目
class MentionItemTile extends StatelessWidget {
  const MentionItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final MentionItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.accent.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (item.type) {
      case MentionType.currentNote:
        return Icon(LucideIcons.fileText, size: 14, color: AppColors.accent);
      case MentionType.note:
        return Icon(LucideIcons.file, size: 14, color: AppColors.textSecondary);
      case MentionType.tag:
        return Icon(LucideIcons.tag, size: 14, color: AppColors.textSecondary);
      case MentionType.allNotes:
        return Icon(LucideIcons.search, size: 14, color: AppColors.textSecondary);
      case MentionType.browseFiles:
        return Icon(
          LucideIcons.folderOpen,
          size: 14,
          color: AppColors.textSecondary,
        );
      case MentionType.currentFolder:
      case MentionType.folder:
        return Icon(
          LucideIcons.folder,
          size: 14,
          color: AppColors.textSecondary,
        );
    }
  }
}
