import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/domains/chat/data/models/mention_item.dart';

/// Icon colors for mention item types.
///
/// Provides consistent theming across mention components.
class MentionIconColors {
  const MentionIconColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  /// Get icon colors for a mention type.
  static MentionIconColors forType(MentionType type) {
    switch (type) {
      case MentionType.currentNote:
      case MentionType.note:
        return const MentionIconColors(
          background: Color(0xFFE3F2FD),
          foreground: Color(0xFF1565C0),
        );
      case MentionType.currentFolder:
      case MentionType.folder:
        return const MentionIconColors(
          background: Color(0xFFFFF8E1),
          foreground: Color(0xFFF57C00),
        );
      case MentionType.tag:
        return const MentionIconColors(
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF2E7D32),
        );
      case MentionType.allNotes:
        return const MentionIconColors(
          background: Color(0xFFF3E5F5),
          foreground: Color(0xFF7B1FA2),
        );
      case MentionType.browseFiles:
        return const MentionIconColors(
          background: Color(0xFFE0F2F1),
          foreground: Color(0xFF00695C),
        );
    }
  }
}

/// Icon mapper for mention item types.
///
/// Maps mention types to Lucide icons.
class MentionIconMapper {
  /// Get the icon for a mention type.
  static IconData getIcon(MentionType type) {
    switch (type) {
      case MentionType.currentNote:
      case MentionType.note:
        return LucideIcons.fileText;
      case MentionType.currentFolder:
      case MentionType.folder:
        return LucideIcons.folder;
      case MentionType.tag:
        return LucideIcons.hash;
      case MentionType.allNotes:
        return LucideIcons.database;
      case MentionType.browseFiles:
        return LucideIcons.folderOpen;
    }
  }

  /// Get the icon with custom override.
  static IconData getIconOrNull(MentionItem item) {
    if (item.icon != null) {
      return item.icon!;
    }
    return getIcon(item.type);
  }
}
