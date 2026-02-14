import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/notes/data/models/file_node.dart';
import 'package:luckynote/domains/notes/presentation/providers/file_tree_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/tags_provider.dart';
import 'package:luckynote/domains/shared_infra/providers/database_provider.dart';
import '../../file_tree_dialogs.dart';

/// Action handler for deleting a file or folder.
class DeleteAction {
  /// Delete the specified node.
  static Future<void> execute(
    BuildContext context,
    WidgetRef ref,
    FileNode node,
  ) async {
    final isDirectory = node.type == FileNodeType.directory;
    int noteCount = 0;

    if (isDirectory) {
      final folderManager = ref.read(folderManagerServiceProvider);
      noteCount = await folderManager.getNoteCount(node.path);
    }

    final confirmed = await FileTreeDialogs.showDeleteConfirmDialog(
      context,
      itemName: node.name,
      isFolder: isDirectory,
      noteCount: noteCount,
    );

    if (!confirmed || !context.mounted) return;

    if (isDirectory) {
      final folderManager = ref.read(folderManagerServiceProvider);
      final result = await folderManager.deleteFolder(node.path);

      FileTreeDialogs.showResultSnackBar(
        context,
        success: result.success,
        message: result.message ?? '删除完成',
      );

      if (result.success) {
        ref.read(fileTreeProvider.notifier).loadTree();
        ref.read(tagsProvider.notifier).refresh();
      }
    } else {
      // Delete note file
      if (node.associatedNote != null) {
        await ref.read(notesProvider.notifier).deleteNote(node.associatedNote!.id);
        FileTreeDialogs.showResultSnackBar(
          context,
          success: true,
          message: '删除成功',
        );
        ref.read(fileTreeProvider.notifier).loadTree();
      }
    }
  }
}
