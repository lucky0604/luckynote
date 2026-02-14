import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 提及类型
enum MentionType { currentNote, currentFolder, allNotes, note, folder, tag, browseFiles }

/// 提及项（用于建议列表）
///
/// 表示在 @ 符号触发的建议列表中的每一项
class MentionItem {
  const MentionItem({
    required this.type,
    required this.id,
    required this.displayName,
    this.icon,
    this.subtitle,
    this.queryMatch,
  });

  /// 提及类型
  final MentionType type;

  /// 唯一标识符
  /// - 文件路径 (对于 note/folder)
  /// - 标签名 (对于 tag)
  /// - 特殊标识 (对于 currentNote, currentFolder, allNotes)
  final String id;

  /// 显示名称
  final String displayName;

  /// 图标
  final IconData? icon;

  /// 副标题（可选，如笔记数量）
  final String? subtitle;

  /// 匹配的查询部分（用于高亮显示）
  final String? queryMatch;

  /// 创建笔记提及项
  factory MentionItem.note({
    required String filePath,
    required String title,
    String? queryMatch,
  }) {
    return MentionItem(
      type: MentionType.note,
      id: filePath,
      displayName: title,
      icon: LucideIcons.fileText,
      queryMatch: queryMatch,
    );
  }

  /// 创建文件夹提及项
  factory MentionItem.folder({
    required String path,
    required String name,
    String? queryMatch,
  }) {
    return MentionItem(
      type: MentionType.folder,
      id: path,
      displayName: name,
      icon: LucideIcons.folder,
      queryMatch: queryMatch,
    );
  }

  /// 创建标签提及项
  factory MentionItem.tag({
    required String name,
    int noteCount = 0,
    String? queryMatch,
  }) {
    return MentionItem(
      type: MentionType.tag,
      id: name,
      displayName: name,
      icon: LucideIcons.hash,
      subtitle: noteCount > 0 ? '$noteCount 篇笔记' : null,
      queryMatch: queryMatch,
    );
  }

  /// 创建当前笔记提及项（优先推荐）
  factory MentionItem.currentNote({
    required String filePath,
    required String title,
  }) {
    return MentionItem(
      type: MentionType.currentNote,
      id: filePath,
      displayName: '当前笔记: $title',
      icon: LucideIcons.fileText,
      subtitle: '高亮推荐',
    );
  }

  /// 创建当前文件夹提及项（优先推荐）
  factory MentionItem.currentFolder({
    required String path,
    required String name,
  }) {
    return MentionItem(
      type: MentionType.currentFolder,
      id: path,
      displayName: '当前文件夹: $name',
      icon: LucideIcons.folder,
      subtitle: '高亮推荐',
    );
  }

  /// 创建全库检索提及项（特殊指令）
  factory MentionItem.allNotes() {
    return const MentionItem(
      type: MentionType.allNotes,
      id: 'all',
      displayName: '全库检索',
      icon: LucideIcons.database,
      subtitle: '搜索所有笔记',
    );
  }

  /// 创建浏览文件提及项
  factory MentionItem.browseFiles() {
    return const MentionItem(
      type: MentionType.browseFiles,
      id: 'browse_files',
      displayName: '浏览文件...',
      icon: LucideIcons.folderOpen,
      subtitle: '选择任意文件',
    );
  }

  /// 创建特殊指令提及项
  factory MentionItem.special({
    required MentionType type,
    required String displayName,
    required String id,
    IconData? icon,
    String? subtitle,
  }) {
    return MentionItem(
      type: type,
      id: id,
      displayName: displayName,
      icon: icon,
      subtitle: subtitle,
    );
  }

  @override
  String toString() {
    return 'MentionItem(type: $type, displayName: $displayName, id: $id)';
  }
}
