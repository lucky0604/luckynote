import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';

import 'package:luckynote/domains/association/data/models/wikilink_attribution.dart';
import 'package:luckynote/domains/shared_infra/providers/database_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';

/// WikiLink 点击处理器
/// 负责检测和处理 WikiLink 的点击导航
class WikiLinkHandler {
  WikiLinkHandler(this._ref);

  final WidgetRef _ref;

  /// 检测光标位置的 WikiLink 并导航
  /// 返回 true 表示找到并处理了 WikiLink
  Future<bool> navigateToWikiLinkAtCursor(
    Document document,
    DocumentSelection? selection,
    BuildContext context,
  ) async {
    if (selection == null) return false;

    final extent = selection.extent;

    // 查找光标所在的节点
    DocumentNode? targetNode;
    for (var i = 0; i < document.nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node != null && node.id == extent.nodeId) {
        targetNode = node;
        break;
      }
    }

    if (targetNode is! TextNode) return false;

    // 获取光标偏移量
    final offset = extent.nodePosition is TextNodePosition
        ? (extent.nodePosition as TextNodePosition).offset
        : 0;

    // 检查光标位置是否有 WikiLink Attribution
    final attributedText = targetNode.text;
    final attributions = attributedText.getAllAttributionsAt(offset);

    WikiLinkAttribution? wikiLinkAttr;
    for (final attr in attributions) {
      if (attr is WikiLinkAttribution) {
        wikiLinkAttr = attr;
        break;
      }
    }

    if (wikiLinkAttr == null) return false;

    // 导航到目标笔记
    await _handleWikiLinkTap(wikiLinkAttr.targetTitle, context);
    return true;
  }

  /// 从点击位置检测 WikiLink 并导航
  Future<bool> handleTapAtPosition(
    Document document,
    DocumentPosition? position,
    BuildContext context,
  ) async {
    if (position == null) return false;

    // 查找点击位置的节点
    DocumentNode? targetNode;
    for (var i = 0; i < document.nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node != null && node.id == position.nodeId) {
        targetNode = node;
        break;
      }
    }

    if (targetNode is! TextNode) return false;

    // 获取点击偏移量
    final offset = position.nodePosition is TextNodePosition
        ? (position.nodePosition as TextNodePosition).offset
        : 0;

    // 检查点击位置是否有 WikiLink Attribution
    final attributedText = targetNode.text;
    
    // 如果偏移量超出范围，返回 false
    if (offset >= attributedText.length) return false;

    final attributions = attributedText.getAllAttributionsAt(offset);

    WikiLinkAttribution? wikiLinkAttr;
    for (final attr in attributions) {
      if (attr is WikiLinkAttribution) {
        wikiLinkAttr = attr;
        break;
      }
    }

    if (wikiLinkAttr == null) return false;

    // 导航到目标笔记
    await _handleWikiLinkTap(wikiLinkAttr.targetTitle, context);
    return true;
  }

  /// 处理 WikiLink 点击导航
  Future<void> _handleWikiLinkTap(
    String targetTitle,
    BuildContext context,
  ) async {
    final noteRepo = _ref.read(noteRepositoryProvider);
    final note = await noteRepo.getByTitle(targetTitle);

    if (note != null) {
      // 笔记存在，打开它
      await _ref.read(editorProvider.notifier).openNote(note);
    } else {
      // 笔记不存在，询问用户
      if (!context.mounted) return;

      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('笔记不存在'),
          content: Text('"$targetTitle" 还不存在，是否创建？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('创建'),
            ),
          ],
        ),
      );

      if (shouldCreate == true && context.mounted) {
        await _createAndOpenNote(targetTitle);
      }
    }
  }

  /// 创建并打开新笔记
  Future<void> _createAndOpenNote(String title) async {
    final newNote = await _ref.read(notesProvider.notifier).createNote(
      title: title,
    );

    if (newNote != null) {
      await _ref.read(editorProvider.notifier).openNote(newNote);
    }
  }
}
