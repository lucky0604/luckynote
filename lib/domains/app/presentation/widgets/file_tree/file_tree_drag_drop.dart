import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/notes/data/models/file_node.dart';
import 'package:luckynote/domains/shared_infra/providers/database_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/file_tree_provider.dart';
import 'file_tree_dialogs.dart';

/// 拖拽数据
class DragData {
  const DragData({
    required this.node,
    required this.sourcePath,
  });

  final FileNode node;
  final String sourcePath;
}

/// 可拖拽的文件树节点包装器
class DraggableTreeNode extends ConsumerWidget {
  const DraggableTreeNode({
    super.key,
    required this.node,
    required this.child,
  });

  final FileNode node;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Draggable<DragData>(
      data: DragData(node: node, sourcePath: node.path),
      feedback: _buildDragFeedback(context),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: child,
      ),
      child: child,
    );
  }

  Widget _buildDragFeedback(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sidebarBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              node.type == FileNodeType.directory
                  ? Icons.folder
                  : Icons.insert_drive_file,
              size: 16,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Text(
              node.name,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 可接收拖拽的文件夹节点包装器
class DropTargetFolder extends ConsumerStatefulWidget {
  const DropTargetFolder({
    super.key,
    required this.folderPath,
    required this.child,
  });

  final String folderPath;
  final Widget child;

  @override
  ConsumerState<DropTargetFolder> createState() => _DropTargetFolderState();
}

class _DropTargetFolderState extends ConsumerState<DropTargetFolder> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        // 不能拖到自己
        if (data.sourcePath == widget.folderPath) return false;
        // 不能拖到自己的子目录
        if (widget.folderPath.startsWith(data.sourcePath)) return false;
        // 不能拖到同一个目录（已经在这个目录了）
        if (_getParentPath(data.sourcePath) == widget.folderPath) return false;

        return true;
      },
      onAcceptWithDetails: (details) => _handleDrop(details.data),
      onMove: (_) {
        if (!_isHovering) {
          setState(() => _isHovering = true);
        }
      },
      onLeave: (_) {
        if (_isHovering) {
          setState(() => _isHovering = false);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: _isHovering
                ? AppColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: _isHovering
                ? Border.all(color: AppColors.accent, width: 2)
                : null,
          ),
          child: widget.child,
        );
      },
    );
  }

  String _getParentPath(String path) {
    final lastSeparator = path.lastIndexOf('/');
    if (lastSeparator == -1) return '';
    return path.substring(0, lastSeparator);
  }

  Future<void> _handleDrop(DragData data) async {
    setState(() => _isHovering = false);

    final folderManager = ref.read(folderManagerServiceProvider);
    final isFolder = data.node.type == FileNodeType.directory;

    final result = isFolder
        ? await folderManager.moveFolder(data.sourcePath, widget.folderPath)
        : await folderManager.moveFile(data.sourcePath, widget.folderPath);

    if (context.mounted) {
      FileTreeDialogs.showResultSnackBar(
        context,
        success: result.success,
        message: result.message ?? '操作完成',
      );

      if (result.success) {
        ref.read(fileTreeProvider.notifier).loadTree();
      }
    }
  }
}
