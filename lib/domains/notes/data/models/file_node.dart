import 'package:flutter/foundation.dart';
import 'package:luckynote/database/database.dart';
import 'package:luckynote/core/utils/file_utils.dart';

/// File node type
enum FileNodeType { file, directory }

/// File tree node model
@immutable
class FileNode {
  const FileNode({
    required this.path,
    required this.name,
    required this.type,
    this.children,
    this.isExpanded = false,
    this.associatedNote,
  });

  /// Absolute path of node
  final String path;

  /// Display name (filename or folder name)
  final String name;

  /// Node type (file or directory)
  final FileNodeType type;

  /// Child nodes (null for files, list for directories)
  final List<FileNode>? children;

  /// UI state: whether folder is expanded
  final bool isExpanded;

  /// Associated note metadata (only for files)
  final Note? associatedNote;

  /// Check if node has children
  bool get hasChildren {
    return type == FileNodeType.directory && (children?.isNotEmpty ?? false);
  }

  /// Get depth from root (derived from path)
  int get depth {
    final separator = RegExp(r'[\\/]');
    return path.split(separator).length;
  }

  /// Check if this node is ancestor of another node
  bool isAncestorOf(String otherPath) {
    final separator = RegExp(r'[\\/]');
    final thisParts = path.split(separator);
    final otherParts = otherPath.split(separator);

    if (otherParts.length <= thisParts.length) return false;

    for (var i = 0; i < thisParts.length; i++) {
      if (thisParts[i] != otherParts[i]) return false;
    }

    return true;
  }

  /// Check if this node is descendant of another node
  bool isDescendantOf(String otherPath) {
    final separator = RegExp(r'[\\/]');
    final thisParts = path.split(separator);
    final otherParts = otherPath.split(separator);

    if (thisParts.length <= otherParts.length) return false;

    for (var i = 0; i < otherParts.length; i++) {
      if (thisParts[i] != otherParts[i]) return false;
    }

    return true;
  }

  /// Create a copy with updated fields
  FileNode copyWith({
    String? path,
    String? name,
    FileNodeType? type,
    List<FileNode>? children,
    bool? isExpanded,
    Note? associatedNote,
  }) {
    return FileNode(
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      associatedNote: associatedNote ?? this.associatedNote,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileNode && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return 'FileNode($type: $name, path: $path, isExpanded: $isExpanded)';
  }
}
