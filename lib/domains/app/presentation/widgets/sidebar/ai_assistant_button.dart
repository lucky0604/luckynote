import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import '../chat/chat_sidebar.dart';

/// AI 助手按钮组件（带强调样式）
class AIAssistantButton extends ConsumerWidget {
  const AIAssistantButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChatSidebar(context, ref),
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.accent.withValues(alpha: 0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.08),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 18, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI 助手',
                    style: TextStyle(
                      color: AppColors.sidebarText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildShortcutHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '⌘J',
        style: TextStyle(
          color: AppColors.sidebarTextSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _openChatSidebar(BuildContext context, WidgetRef ref) {
    final currentNote = ref.read(currentNoteProvider);
    ref.read(chatNotifierProvider.notifier).setCurrentNote(currentNote);
    showChatSidebar(context);
  }
}
