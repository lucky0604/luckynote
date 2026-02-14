import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../data/models/file_node.dart';
import '../../../../database/database.dart';
import '../../data/services/folder_storage_service.dart';
import '../../../shared_infra/providers/database_provider.dart';
import 'vault_provider.dart';
import 'file_watcher_provider.dart';

/// File tree state
class FileTreeState {
  const FileTreeState({
    required this.tree,
    this.selectedPath,
    this.expandedFolders = const {},
    this.isLoading = false,
    this.error,
  });

  final List<FileNode> tree;
  final String? selectedPath;
  final Set<String> expandedFolders;
  final bool isLoading;
  final String? error;

  FileTreeState copyWith({
    List<FileNode>? tree,
    String? selectedPath,
    Set<String>? expandedFolders,
    bool? isLoading,
    String? error,
  }) {
    return FileTreeState(
      tree: tree ?? this.tree,
      selectedPath: selectedPath ?? this.selectedPath,
      expandedFolders: expandedFolders ?? this.expandedFolders,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// File tree state notifier
class FileTreeNotifier extends StateNotifier<AsyncValue<FileTreeState>> {
  final Ref ref;
  final FolderStorageService _storageService = FolderStorageService();
  late String _vaultPath;

  FileTreeNotifier(this.ref) : super(const AsyncValue.loading()) {
    // 初始化存储服务
    _storageService.init();

    // Watch vault path changes
    ref.listen(vaultProvider, (previous, next) {
      next.whenData((path) {
        if (path != null && path != _vaultPath) {
          _vaultPath = path;
          loadTree();
        }
      });
    });

    // 监听文件变化，自动刷新树视图（解决重命名不更新问题）
    ref.listen(fileWatcherProvider, (previous, next) {
      if (next.lastEvent != null) {
        loadTree();
      }
    });

    // Initial load
    final path = ref.read(vaultProvider).value;
    if (path != null) {
      _vaultPath = path;
      loadTree();
    }
  }

  /// 加载或重建文件树
  Future<void> loadTree({Set<String>? initialExpanded}) async {
    state = const AsyncValue.loading();

    try {
      final directory = Directory(_vaultPath);
      if (!await directory.exists()) {
        state = const AsyncValue.data(FileTreeState(tree: []));
        return;
      }

      // Scan file system
      final fileSystemNodes = await _buildFileSystemTree();

      // Load notes from database
      final notes = await _loadNotesFromDatabase();

      // Apply saved expansion states
      final expandedFolders =
          initialExpanded ?? await _storageService.getExpandedFolders();

      // Associate notes with file nodes
      final treeWithNotes = _associateNotes(fileSystemNodes, notes);

      state = AsyncValue.data(
        FileTreeState(tree: treeWithNotes, expandedFolders: expandedFolders),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Build tree from file system (recursive)
  Future<List<FileNode>> _buildFileSystemTree() async {
    final directory = Directory(_vaultPath);
    final nodes = <FileNode>[];

    await for (final entity in directory.list(recursive: false)) {
      if (entity is Directory) {
        nodes.add(await _buildDirectoryNode(entity, depth: 0));
      } else if (entity is File && _isMarkdownFile(entity.path)) {
        nodes.add(_buildFileNode(entity));
      }
    }

    // Sort: folders first, then files, both alphabetically
    nodes.sort((a, b) {
      if (a.type != b.type) {
        return a.type == FileNodeType.directory ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    return nodes;
  }

  /// Build directory node recursively
  Future<FileNode> _buildDirectoryNode(
    Directory directory, {
    required int depth,
  }) async {
    final children = <FileNode>[];

    await for (final entity in directory.list()) {
      if (entity is Directory) {
        children.add(await _buildDirectoryNode(entity, depth: depth + 1));
      } else if (entity is File && _isMarkdownFile(entity.path)) {
        children.add(_buildFileNode(entity));
      }
    }

    // Sort children
    children.sort((a, b) {
      if (a.type != b.type) {
        return a.type == FileNodeType.directory ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    return FileNode(
      path: directory.path,
      name: p.basename(directory.path),
      type: FileNodeType.directory,
      children: children,
      isExpanded: false,
    );
  }

  /// Build file node
  FileNode _buildFileNode(File file) {
    return FileNode(
      path: file.path,
      name: p.basename(file.path),
      type: FileNodeType.file,
      children: null,
      isExpanded: false,
      associatedNote: null, // Will be loaded separately
    );
  }

  /// Load notes from database
  Future<Map<String, Note>> _loadNotesFromDatabase() async {
    final noteRepo = ref.read(noteRepositoryProvider);
    final notes = await noteRepo.getAll();

    final noteMap = <String, Note>{};
    for (final note in notes) {
      noteMap[note.filePath] = note;
    }

    return noteMap;
  }

  /// Associate notes with file nodes (recursive)
  List<FileNode> _associateNotes(
    List<FileNode> nodes,
    Map<String, Note> notes,
  ) {
    final result = <FileNode>[];

    for (final node in nodes) {
      if (node.type == FileNodeType.file) {
        final note = notes[node.path];
        result.add(node.copyWith(associatedNote: note));
      } else if (node.type == FileNodeType.directory && node.children != null) {
        final childrenWithNotes = _associateNotes(node.children!, notes);
        result.add(node.copyWith(children: childrenWithNotes));
      } else {
        result.add(node);
      }
    }

    return result;
  }

  /// Toggle folder expansion
  void toggleFolder(String path) {
    state.whenData((treeState) {
      final updatedTree = _toggleNodeExpansion(treeState.tree, path);
      final expandedFolders = Set<String>.from(treeState.expandedFolders);

      if (expandedFolders.contains(path)) {
        expandedFolders.remove(path);
      } else {
        expandedFolders.add(path);
      }

      state = AsyncValue.data(
        treeState.copyWith(tree: updatedTree, expandedFolders: expandedFolders),
      );

      // Save to persistent storage
      _storageService.saveExpandedFolders(expandedFolders);
    });
  }

  /// Toggle node expansion (recursive)
  List<FileNode> _toggleNodeExpansion(List<FileNode> nodes, String path) {
    final result = <FileNode>[];

    for (final node in nodes) {
      if (node.path == path) {
        result.add(node.copyWith(isExpanded: !node.isExpanded));
      } else if (node.children != null) {
        final childrenWithExpansion = _toggleNodeExpansion(
          node.children!,
          path,
        );
        result.add(node.copyWith(children: childrenWithExpansion));
      } else {
        result.add(node);
      }
    }

    return result;
  }

  /// Select node (folder or file)
  void selectNode(String? path) {
    state.whenData((treeState) {
      state = AsyncValue.data(treeState.copyWith(selectedPath: path));
    });
  }

  /// Check if file is markdown
  bool _isMarkdownFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.md' || ext == '.markdown' || ext == '.mdown';
  }
}

/// File tree provider
final fileTreeProvider =
    StateNotifierProvider<FileTreeNotifier, AsyncValue<FileTreeState>>((ref) {
      return FileTreeNotifier(ref);
    });
