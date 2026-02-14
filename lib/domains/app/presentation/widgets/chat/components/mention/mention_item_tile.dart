import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/data/models/mention_item.dart';
import 'mention_styles.dart';

/// A single mention item tile for suggestion lists.
///
/// Shared component used by both MentionPopup and MentionOverlay.
class MentionItemTile extends StatelessWidget {
  const MentionItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.showCheckIndicator = false,
  });

  final MentionItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showCheckIndicator;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectedBackground : Colors.transparent,
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 10),
            Expanded(child: _buildContent()),
            if (isSelected)
              Icon(
                showCheckIndicator ? LucideIcons.check : LucideIcons.cornerDownLeft,
                size: 14,
                color: AppColors.textPlaceholder,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final colors = MentionIconColors.forType(item.type);
    final icon = MentionIconMapper.getIconOrNull(item);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: colors.foreground),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.displayName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.subtitle != null)
          Text(
            item.subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
