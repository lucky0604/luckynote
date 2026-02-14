import 'package:flutter/material.dart';

import 'package:luckynote/app/theme/app_colors.dart';

/// 文件树对话框工具类
class FileTreeDialogs {
  /// 显示创建文件夹对话框
  static Future<String?> showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '文件夹名称'),
          autofocus: true,
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(dialogContext, true);
            }
          },
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
      return controller.text.trim();
    }
    return null;
  }

  /// 显示重命名对话框
  static Future<String?> showRenameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '新名称'),
          autofocus: true,
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty &&
                controller.text.trim() != currentName) {
              Navigator.pop(dialogContext, true);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty ||
                  controller.text.trim() == currentName) {
                Navigator.pop(dialogContext, false);
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('重命名'),
          ),
        ],
      ),
    );

    if (result == true &&
        controller.text.trim().isNotEmpty &&
        controller.text.trim() != currentName) {
      return controller.text.trim();
    }
    return null;
  }

  /// 显示删除确认对话框
  static Future<bool> showDeleteConfirmDialog(
    BuildContext context, {
    required String itemName,
    required bool isFolder,
    int noteCount = 0,
  }) async {
    String message;
    if (isFolder) {
      message = noteCount > 0
          ? '确定要删除文件夹 "$itemName" 及其包含的 $noteCount 个笔记吗？'
          : '确定要删除文件夹 "$itemName" 吗？';
    } else {
      message = '确定要删除笔记 "$itemName" 吗？';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 显示操作结果 SnackBar
  static void showResultSnackBar(
    BuildContext context, {
    required bool success,
    required String message,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }
}
