import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/notes/data/models/file_node.dart';
import 'actions/create_note_action.dart';
import 'actions/create_folder_action.dart';
import 'actions/add_to_chat_action.dart';
import 'actions/rename_action.dart';
import 'actions/delete_action.dart';

/// File tree context menu.
///
/// Provides context menu actions for file tree nodes.
class FileTreeContextMenu {
  /// Show context menu for a node at the given position.
  static void show(
    BuildContext context,
    WidgetRef ref,
    FileNode node,
    Offset position,
  ) {
    final isDirectory = node.type == FileNodeType.directory;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: _buildMenuItems(node, isDirectory),
    ).then((value) {
      if (value == null || !context.mounted) return;
      _handleMenuAction(context, ref, node, value);
    });
  }

  /// Build menu items for the given node.
  static List<PopupMenuEntry<String>> _buildMenuItems(
    FileNode node,
    bool isDirectory,
  ) {
    final items = <PopupMenuEntry<String>>[];

    // Directory-specific menu items
    if (isDirectory) {
      items
        ..add(_buildMenuItem('new_note', LucideIcons.filePlus, '新建笔记'))
        ..add(_buildMenuItem('new_folder', LucideIcons.folderPlus, '新建子文件夹'))
        ..add(const PopupMenuDivider());
    }

    // Common menu items
    if (!isDirectory) {
      items.add(_buildMenuItem(
        'add_to_chat',
        LucideIcons.messageSquarePlus,
        '添加到聊天上下文',
      ));
    }
    items
      ..add(_buildMenuItem('rename', LucideIcons.pencil, '重命名'))
      ..add(_buildMenuItem(
        'delete',
        LucideIcons.trash2,
        '删除',
        isDestructive: true,
      ));

    return items;
  }

  /// Build a single menu item.
  static PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDestructive ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// Handle menu action selection.
  static void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    FileNode node,
    String action,
  ) {
    switch (action) {
      case 'new_note':
        CreateNoteAction.execute(context, ref, node.path);
        break;
      case 'new_folder':
        CreateFolderAction.execute(context, ref, node.path);
        break;
      case 'add_to_chat':
        AddToChatAction.execute(context, ref, node);
        break;
      case 'rename':
        RenameAction.execute(context, ref, node);
        break;
      case 'delete':
        DeleteAction.execute(context, ref, node);
        break;
    }
  }
}
