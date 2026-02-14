import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/database/database.dart';
import 'package:luckynote/domains/association/presentation/providers/backlinks_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';

/// 反向链接面板 - 显示引用当前笔记的其他笔记
class BacklinksPanel extends ConsumerWidget {
  const BacklinksPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backlinksProvider);
    final currentNote = ref.watch(currentNoteProvider);

    if (currentNote == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state.backlinks.length),
          if (state.isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            )
          else if (state.backlinks.isEmpty)
            _buildEmptyState()
          else
            _buildBacklinksList(state.backlinks, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      children: [
        Icon(LucideIcons.link2, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '反向链接',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '暂无其他笔记引用此笔记',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textPlaceholder,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildBacklinksList(List<BacklinkResult> backlinks, WidgetRef ref) {
    return Column(
      children: backlinks.map((backlink) {
        return _buildBacklinkTile(backlink, ref);
      }).toList(),
    );
  }

  Widget _buildBacklinkTile(BacklinkResult backlink, WidgetRef ref) {
    return InkWell(
      onTap: () {
        // 打开引用笔记
        ref.read(editorProvider.notifier).openNoteByPath(backlink.sourceFilePath);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: AppColors.noteListBackground,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.fileText,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                backlink.sourceTitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.arrowUpRight,
              size: 14,
              color: AppColors.textPlaceholder,
            ),
          ],
        ),
      ),
    );
  }
}
