import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/navigation/data/models/navigation_state.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';

class NoteListEmpty extends ConsumerWidget {
  const NoteListEmpty({
    super.key,
    required this.navState,
  });

  final NavigationState navState;

  Future<void> _createNote(WidgetRef ref) async {
    final note = await ref.read(notesProvider.notifier).createNote();
    if (note != null) {
      ref.read(editorProvider.notifier).openNote(note);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _emptyConfig(navState);

    if (config.message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(config.icon, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),

            // 消息
            Text(
              config.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              config.subtitle,
              style: TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // CTA 按钮（仅在全部笔记或文件夹为空时显示）
            if (config.showCreateButton) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _createNote(ref),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('创建笔记'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _EmptyConfig _emptyConfig(NavigationState navState) {
    switch (navState.filterType) {
      case NavigationFilterType.favorites:
        return const _EmptyConfig(
          title: '没有已置顶的笔记',
          subtitle: '点击笔记卡片右上角的星标可以置顶',
          icon: '⭐',
          showCreateButton: false,
        );
      case NavigationFilterType.tag:
        return _EmptyConfig(
          title: '没有此标签的笔记',
          subtitle: '标签 #${navState.selectedTag} 下暂无笔记',
          icon: '🏷️',
          showCreateButton: false,
        );
      case NavigationFilterType.folderPath:
        return const _EmptyConfig(
          title: '文件夹为空',
          subtitle: '在此文件夹中创建第一篇笔记',
          icon: '📁',
          showCreateButton: true,
        );
      case NavigationFilterType.folderRoot:
      case NavigationFilterType.tasks:
        return const _EmptyConfig(
          title: '',
          subtitle: '',
          icon: '',
          showCreateButton: false,
        );
      case NavigationFilterType.all:
        return const _EmptyConfig(
          title: '开始记录你的想法',
          subtitle: '创建第一篇笔记，开启知识管理之旅',
          icon: '📝',
          showCreateButton: true,
        );
    }
  }
}

class _EmptyConfig {
  const _EmptyConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.showCreateButton,
  });

  final String title;
  final String subtitle;
  final String icon;
  final bool showCreateButton;

  String get message => title;
}
