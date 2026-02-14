import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/notes/presentation/providers/file_tree_provider.dart';
import 'package:luckynote/domains/shared_infra/providers/database_provider.dart';
import '../../file_tree_dialogs.dart';

/// Action handler for creating a subfolder.
class CreateFolderAction {
  /// Create a subfolder in the specified parent path.
  static Future<void> execute(
    BuildContext context,
    WidgetRef ref,
    String parentPath,
  ) async {
    final folderName = await FileTreeDialogs.showCreateFolderDialog(context);
    if (folderName == null || !context.mounted) return;

    final folderManager = ref.read(folderManagerServiceProvider);
    final result = await folderManager.createFolder(parentPath, folderName);

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
