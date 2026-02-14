import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/notes/presentation/providers/file_tree_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';
import '../../../../notes/presentation/providers/vault_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'package:luckynote/domains/shared_infra/providers/database_provider.dart';
import 'file_tree_tile.dart';

/// File tree view widget with toolbar
class FileTreeView extends ConsumerWidget {
  const FileTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(fileTreeProvider);

    return treeState.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('加载文件树失败', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                '$e',
                style: TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(fileTreeProvider.notifier).loadTree();
                },
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      data: (state) {
        // 无论是否有文件，都显示 toolbar，这样用户可以在空目录时创建文件夹/文件
        return Column(
          children: [
            // Toolbar - 始终显示
            _buildToolbar(context, ref),

            // File tree 或空状态
            Expanded(
              child: state.tree.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.folderOpen,
                            size: 48,
                            color: AppColors.textPlaceholder,
                          ),
                          const SizedBox(height: 16),
                          Text('暂无文件夹', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text(
                            '点击右上角的 + 按钮创建文件夹或笔记',
                            style: TextStyle(
                              color: AppColors.textPlaceholder,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: state.tree.length,
                      itemBuilder: (buildContext, index) {
                        return FileTreeTile(
                          node: state.tree[index],
                          depth: 0,
                          isSelected: state.selectedPath == state.tree[index].path,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // 刷新按钮
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            onPressed: () => ref.read(fileTreeProvider.notifier).loadTree(),
            tooltip: '刷新',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.sidebarTextSecondary,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(32, 32),
            ),
          ),
          const Spacer(),

          // 新建文件夹按钮
          IconButton(
            icon: const Icon(LucideIcons.folderPlus, size: 16),
            onPressed: () => _createNewFolder(context, ref),
            tooltip: '新建文件夹',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(32, 32),
            ),
          ),
          const SizedBox(width: 4),

          // 新建笔记按钮
          IconButton(
            icon: const Icon(LucideIcons.fileText, size: 16),
            onPressed: () => _createNewNote(context, ref),
            tooltip: '新建笔记',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewFolder(BuildContext context, WidgetRef ref) async {
    final vaultPath = ref.read(vaultProvider).value;
    if (vaultPath == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请先设置笔记仓库')));
      }
      return;
    }

    final folderManager = ref.read(folderManagerServiceProvider);
    final selectedFolder = ref.read(selectedFolderProvider);
    final parentPath = selectedFolder ?? vaultPath;

    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '文件夹名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      final operationResult = await folderManager.createFolder(
        parentPath,
        controller.text.trim(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(operationResult.message ?? '操作完成'),
            backgroundColor: operationResult.success
                ? AppColors.success
                : AppColors.error,
          ),
        );

        if (operationResult.success) {
          ref.read(fileTreeProvider.notifier).loadTree();
        }
      }
    }
  }

  Future<void> _createNewNote(BuildContext context, WidgetRef ref) async {
    final vaultPath = ref.read(vaultProvider).value;
    final selectedFolder = ref.read(selectedFolderProvider);
    final parentPath = selectedFolder ?? vaultPath;

    if (parentPath == null) {
      return;
    }

    // 传入目标文件夹路径
    final note = await ref.read(notesProvider.notifier).createNote(
      folderPath: parentPath,
    );
    if (note != null) {
      ref.read(editorProvider.notifier).openNote(note);
      // 刷新文件树
      ref.read(fileTreeProvider.notifier).loadTree();
    }
  }
}
