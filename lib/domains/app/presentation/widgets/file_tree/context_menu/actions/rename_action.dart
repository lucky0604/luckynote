import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/notes/data/models/file_node.dart';
import 'package:luckynote/domains/notes/presentation/providers/file_tree_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';
import 'package:luckynote/domains/shared_infra/providers/database_provider.dart';
import '../../file_tree_dialogs.dart';

/// Action handler for renaming a file or folder.
class RenameAction {
  /// Rename the specified node.
  static Future<void> execute(
    BuildContext context,
    WidgetRef ref,
    FileNode node,
  ) async {
    final newName = await FileTreeDialogs.showRenameDialog(context, node.name);
    if (newName == null || !context.mounted) return;

    final isDirectory = node.type == FileNodeType.directory;

    if (isDirectory) {
      final folderManager = ref.read(folderManagerServiceProvider);
      final result = await folderManager.renameFolder(node.path, newName);

      FileTreeDialogs.showResultSnackBar(
        context,
        success: result.success,
        message: result.message ?? '操作完成',
      );

      if (result.success) {
        ref.read(fileTreeProvider.notifier).loadTree();
      }
    } else {
      // Rename note file
      if (node.associatedNote != null) {
        final updatedNote = await ref
            .read(notesProvider.notifier)
            .renameNote(node.associatedNote!.id, newName);

        if (updatedNote != null) {
          FileTreeDialogs.showResultSnackBar(
            context,
            success: true,
            message: '重命名成功',
          );
          ref.read(fileTreeProvider.notifier).loadTree();
        } else {
          FileTreeDialogs.showResultSnackBar(
            context,
            success: false,
            message: '重命名失败',
          );
        }
      }
    }
  }
}
