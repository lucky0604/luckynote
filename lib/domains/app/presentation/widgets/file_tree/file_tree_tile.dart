import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/notes/data/models/file_node.dart';
import 'package:luckynote/domains/notes/presentation/providers/file_tree_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'context_menu/file_tree_context_menu.dart';
import 'file_tree_drag_drop.dart';

/// 文件树节点组件
class FileTreeTile extends ConsumerWidget {
  const FileTreeTile({
    super.key,
    required this.node,
    required this.depth,
    required this.isSelected,
  });

  final FileNode node;
  final int depth;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDirectory = node.type == FileNodeType.directory;
    final noteCount = _getNoteCount(node);

    // 缩进 (每层 16px)
    final indent = 8.0 + (depth * 16.0);

    // 构建节点行
    Widget nodeRow = GestureDetector(
      onTap: () => _handleTap(ref, isDirectory),
      onSecondaryTapDown: (details) {
        _showContextMenu(context, ref, details.globalPosition);
      },
      onLongPress: () {
        // 移动端长按显示菜单
        final box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        _showContextMenu(context, ref, position);
      },
      child: _buildNodeRow(context, ref, isDirectory, noteCount, indent),
    );

    // 包装拖拽功能
    nodeRow = DraggableTreeNode(node: node, child: nodeRow);

    // 目录节点可作为拖放目标
    if (isDirectory) {
      nodeRow = DropTargetFolder(folderPath: node.path, child: nodeRow);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nodeRow,

        // 子节点（递归）
        if (isDirectory && node.isExpanded && node.children != null)
          ...node.children!.map(
            (child) => FileTreeTile(
              node: child,
              depth: depth + 1,
              isSelected: ref.watch(fileTreeProvider).maybeWhen(
                    data: (state) => state.selectedPath == child.path,
                    orElse: () => false,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildNodeRow(
    BuildContext context,
    WidgetRef ref,
    bool isDirectory,
    int noteCount,
    double indent,
  ) {
    return Container(
      margin: EdgeInsets.only(left: indent, right: 8, top: 2, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 展开/折叠图标（仅目录）
          if (isDirectory) _buildExpandIcon(ref),

          // 类型图标
          _buildTypeIcon(isDirectory),
          const SizedBox(width: 12),

          // 名称（显示 title 而非文件名）
          Expanded(child: _buildNameText()),

          // 笔记数量徽章（仅目录）
          if (isDirectory && noteCount > 0) _buildNoteCountBadge(noteCount),
        ],
      ),
    );
  }

  Widget _buildExpandIcon(WidgetRef ref) {
    final hasChildren = node.children?.isNotEmpty ?? false;

    if (!hasChildren) {
      return const SizedBox(width: 20);
    }

    return SizedBox(
      width: 20,
      child: IconButton(
        icon: Icon(
          node.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
          size: 14,
          color: AppColors.textSecondary,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 20, height: 20),
        onPressed: () {
          ref.read(fileTreeProvider.notifier).toggleFolder(node.path);
        },
      ),
    );
  }

  Widget _buildTypeIcon(bool isDirectory) {
    if (isDirectory) {
      return Icon(
        node.isExpanded ? LucideIcons.folderOpen : LucideIcons.folder,
        size: 18,
        color: isSelected ? AppColors.accent : AppColors.textSecondary,
      );
    } else {
      return Icon(
        LucideIcons.fileText,
        size: 16,
        color: AppColors.textSecondary,
      );
    }
  }

  Widget _buildNameText() {
    // 笔记文件优先显示标题，文件夹显示文件夹名
    final displayName = node.type == FileNodeType.file
        ? (node.associatedNote?.title ?? node.name)
        : node.name;

    return Text(
      displayName,
      style: TextStyle(
        fontSize: 14,
        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNoteCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int _getNoteCount(FileNode node) {
    if (node.type == FileNodeType.file) {
      return node.associatedNote != null ? 1 : 0;
    }

    int count = 0;
    if (node.children != null) {
      for (final child in node.children!) {
        count += _getNoteCount(child);
      }
    }
    return count;
  }

  void _handleTap(WidgetRef ref, bool isDirectory) {
    if (isDirectory) {
      // 点击文件夹：切换展开状态并选中
      ref.read(fileTreeProvider.notifier).toggleFolder(node.path);
      ref.read(fileTreeProvider.notifier).selectNode(node.path);
    } else {
      // 点击文件：选中并打开编辑器
      ref.read(fileTreeProvider.notifier).selectNode(node.path);
      if (node.associatedNote != null) {
        ref.read(editorProvider.notifier).openNote(node.associatedNote!);
      }
    }
  }

  void _showContextMenu(BuildContext context, WidgetRef ref, Offset position) {
    FileTreeContextMenu.show(context, ref, node, position);
  }
}
