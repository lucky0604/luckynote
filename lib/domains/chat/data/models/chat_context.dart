import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 聊天上下文类型
enum ContextType {
  note, // 当前笔记
  folder, // 文件夹
  tag, // 标签
  all, // 全库检索
}

/// 聊天上下文模型
///
/// 用于表示用户在聊天中引用的上下文信息，如当前笔记、文件夹、标签等
class ChatContext {
  const ChatContext({
    required this.id,
    required this.displayName,
    required this.type,
    this.icon,
    this.subtitle,
  });

  /// 唯一标识符
  /// - 文件路径 (对于 note/folder)
  /// - 标签名 (对于 tag)
  /// - 'all' (对于全库检索)
  final String id;

  /// 显示名称
  final String displayName;

  /// 上下文类型
  final ContextType type;

  /// 图标
  final IconData? icon;

  /// 副标题（可选，如笔记数量）
  final String? subtitle;

  /// 创建笔记上下文
  factory ChatContext.note({required String filePath, required String title}) {
    return ChatContext(
      id: filePath,
      displayName: title,
      type: ContextType.note,
      icon: LucideIcons.fileText,
      subtitle: '当前笔记',
    );
  }

  /// 创建文件夹上下文
  factory ChatContext.folder({required String path, required String name}) {
    return ChatContext(
      id: path,
      displayName: name,
      type: ContextType.folder,
      icon: LucideIcons.folder,
      subtitle: '文件夹',
    );
  }

  /// 创建标签上下文
  factory ChatContext.tag({required String name, int noteCount = 0}) {
    return ChatContext(
      id: name,
      displayName: name,
      type: ContextType.tag,
      icon: LucideIcons.hash,
      subtitle: noteCount > 0 ? '$noteCount 篇笔记' : null,
    );
  }

  /// 创建全库上下文
  factory ChatContext.all() {
    return const ChatContext(
      id: 'all',
      displayName: '全库检索',
      type: ContextType.all,
      icon: LucideIcons.database,
      subtitle: '搜索所有笔记',
    );
  }

  /// 转换为 Map 用于序列化
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'type': type.name,
      'subtitle': subtitle,
    };
  }

  /// 从 Map 反序列化
  factory ChatContext.fromMap(Map<String, dynamic> map) {
    return ChatContext(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      type: ContextType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ContextType.note,
      ),
      subtitle: map['subtitle'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatContext && id == other.id && type == other.type;

  @override
  int get hashCode => Object.hash(id, type);

  @override
  String toString() {
    return 'ChatContext(type: $type, displayName: $displayName, id: $id)';
  }
}
