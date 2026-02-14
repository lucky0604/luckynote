import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/association/data/models/mention_candidate.dart';
import 'package:luckynote/domains/association/presentation/providers/unlinked_mentions_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';

/// Unlinked Mentions Panel - shows detected unlinked mentions
class UnlinkedMentionsPanel extends ConsumerWidget {
  const UnlinkedMentionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unlinkedMentionsProvider);
    final currentNote = ref.watch(currentNoteProvider);

    if (currentNote == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state, ref),
          const SizedBox(height: 12),
          if (state.isLoading)
            _buildLoadingState()
          else if (state.error != null)
            _buildErrorState(state.error!)
          else if (state.mentions.isEmpty)
            _buildEmptyState()
          else
            _buildMentionsList(state.mentions, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(UnlinkedMentionsState state, WidgetRef ref) {
    return Row(
      children: [
        Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '未关联的提及',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        if (state.mentions.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${state.mentions.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
        const Spacer(),
        // Refresh button
        IconButton(
          icon: Icon(
            state.isLoading ? LucideIcons.loader2 : LucideIcons.refreshCw,
            size: 14,
            color: AppColors.textSecondary,
          ),
          onPressed: state.isLoading
              ? null
              : () => ref.read(unlinkedMentionsProvider.notifier).refresh(),
          tooltip: '刷新',
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.all(6),
            minimumSize: const Size(28, 28),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(24),
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
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, size: 14, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            '未发现未关联的提及',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPlaceholder,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionsList(List<MentionCandidate> mentions, WidgetRef ref) {
    return Column(
      children: mentions.map((mention) {
        return _buildMentionTile(mention, ref);
      }).toList(),
    );
  }

  Widget _buildMentionTile(MentionCandidate mention, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _handleLinkMention(mention, ref),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target note title
              Row(
                children: [
                  Icon(
                    LucideIcons.fileText,
                    size: 12,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      mention.targetNoteTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Link button
                  TextButton.icon(
                    onPressed: () => _handleLinkMention(mention, ref),
                    icon: Icon(LucideIcons.link, size: 12),
                    label: Text('关联'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Matched text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '"${mention.matchedText}"',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (mention.context.isNotEmpty) ...[
                const SizedBox(height: 6),
                // Context preview
                Text(
                  _highlightMatchInContext(mention.context, mention.matchedText),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Highlight the matched text in context
  String _highlightMatchInContext(String context, String matchedText) {
    // For text display, we'll just show the context with quotes
    // The highlighting could be done with TextSpan for richer UI
    final maxLength = 80;
    if (context.length <= maxLength) {
      return context;
    }
    return '...${context.substring(0, maxLength)}...';
  }

  /// Handle converting mention to WikiLink
  void _handleLinkMention(MentionCandidate mention, WidgetRef ref) {
    // Use the editor provider's convertToWikiLink method
    ref.read(editorProvider.notifier).convertToWikiLink(
      startIndex: mention.startIndex,
      endIndex: mention.endIndex,
      targetTitle: mention.targetNoteTitle,
    );
  }
}
