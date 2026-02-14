import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/chat/data/models/chat_context.dart';
import 'package:luckynote/domains/notes/data/models/file_node.dart';
import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';
import '../../file_tree_dialogs.dart';

/// Action handler for adding a note to chat context.
class AddToChatAction {
  /// Add the note associated with the node to chat context.
  static Future<void> execute(
    BuildContext context,
    WidgetRef ref,
    FileNode node,
  ) async {
    // Verify it's a file, not a folder
    if (node.type == FileNodeType.directory) {
      return;
    }

    // Check if there's an associated note
    if (node.associatedNote == null) {
      if (context.mounted) {
        FileTreeDialogs.showResultSnackBar(
          context,
          success: false,
          message: '未找到关联的笔记',
        );
      }
      return;
    }

    final note = node.associatedNote!;

    // Check if file exists and size limit
    final file = File(note.filePath);
    if (!file.existsSync()) {
      if (context.mounted) {
        FileTreeDialogs.showResultSnackBar(
          context,
          success: false,
          message: '文件不存在',
        );
      }
      return;
    }

    // Check file size (500KB limit)
    const maxSizeInBytes = 500 * 1024; // 500KB
    final fileSize = await file.length();
    if (fileSize > maxSizeInBytes) {
      final sizeInKB = (fileSize / 1024).toStringAsFixed(1);
      if (context.mounted) {
        FileTreeDialogs.showResultSnackBar(
          context,
          success: false,
          message: '文件过大 ($sizeInKB KB)，最大支持 500KB',
        );
      }
      return;
    }

    // Check if it's a .md file
    if (!note.filePath.toLowerCase().endsWith('.md')) {
      if (context.mounted) {
        FileTreeDialogs.showResultSnackBar(
          context,
          success: false,
          message: '仅支持添加 Markdown 文件',
        );
      }
      return;
    }

    // Check if already added
    final chatNotifier = ref.read(chatNotifierProvider.notifier);
    final activeContexts = ref.read(chatNotifierProvider).activeContexts;
    final alreadyAdded = activeContexts.any(
      (ctx) => ctx.id == note.filePath && ctx.type == ContextType.note,
    );

    if (alreadyAdded) {
      if (context.mounted) {
        FileTreeDialogs.showResultSnackBar(
          context,
          success: false,
          message: '该文件已在聊天上下文中',
        );
      }
      return;
    }

    // Add to chat context
    final chatContext = ChatContext.note(
      filePath: note.filePath,
      title: note.title,
    );
    chatNotifier.addContext(chatContext);

    if (context.mounted) {
      FileTreeDialogs.showResultSnackBar(
        context,
        success: true,
        message: '已添加 ${note.title} 到聊天上下文',
      );
    }
  }
}
