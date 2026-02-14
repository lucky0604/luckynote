import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 聊天附件类型
enum AttachmentType {
  image, // 图片
  note, // 笔记
  file, // 其他文件
}

/// 聊天附件模型
class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.previewUrl,
  });

  /// 唯一标识符
  final String id;

  /// 显示名称
  final String name;

  /// 文件路径
  final String path;

  /// 附件类型
  final AttachmentType type;

  /// 预览 URL（仅图片）
  final String? previewUrl;

  /// 获取图标
  IconData get icon {
    switch (type) {
      case AttachmentType.image:
        return LucideIcons.image;
      case AttachmentType.note:
        return LucideIcons.fileText;
      case AttachmentType.file:
        return LucideIcons.file;
    }
  }

  /// 从图片路径创建
  factory ChatAttachment.image({
    required String path,
    required String name,
  }) {
    return ChatAttachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      path: path,
      type: AttachmentType.image,
      previewUrl: path,
    );
  }

  /// 从笔记创建
  factory ChatAttachment.note({
    required String path,
    required String title,
  }) {
    return ChatAttachment(
      id: path,
      name: title,
      path: path,
      type: AttachmentType.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAttachment && id == other.id && path == other.path;

  @override
  int get hashCode => Object.hash(id, path);
}
