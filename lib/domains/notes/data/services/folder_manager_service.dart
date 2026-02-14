import 'dart:io';
import 'package:path/path.dart' as p;

import '../../../../core/utils/file_utils.dart';
import 'package:luckynote/domains/notes/data/repositories/note_repository.dart';
import '../indexing/indexer_service.dart';

/// Folder operation result
class FolderOperationResult {
  const FolderOperationResult({
    this.success = true,
    this.message,
    this.affectedNotes = 0,
  });

  final bool success;
  final String? message;
  final int affectedNotes;
}

/// Delete folder result
class DeleteFolderResult extends FolderOperationResult {
  const DeleteFolderResult({
    required super.success,
    super.message,
    required super.affectedNotes,
    this.notePaths = const [],
  });

  final List<String> notePaths;
}

/// Folder manager service
class FolderManagerService {
  FolderManagerService({
    required this.indexerService,
    required this.noteRepository,
  });

  final IndexerService indexerService;
  final NoteRepository noteRepository;

  /// Create a new folder
  Future<FolderOperationResult> createFolder(
    String parentPath,
    String folderName,
  ) async {
    try {
      // Validate folder name
      if (folderName.isEmpty) {
        return const FolderOperationResult(
          success: false,
          message: '文件夹名称不能为空',
        );
      }

      if (folderName.contains(RegExp(r'[<>:"/\\|?*]'))) {
        return const FolderOperationResult(
          success: false,
          message: '文件夹名称包含非法字符',
        );
      }

      // Check if folder already exists
      final folderPath = p.join(parentPath, folderName);
      final existingFolder = Directory(folderPath);
      if (await existingFolder.exists()) {
        return const FolderOperationResult(success: false, message: '文件夹已存在');
      }

      // Create folder
      await existingFolder.create(recursive: true);

      return const FolderOperationResult(success: true, message: '文件夹创建成功');
    } catch (e) {
      return FolderOperationResult(success: false, message: '创建文件夹失败: $e');
    }
  }

  /// Rename a folder
  Future<FolderOperationResult> renameFolder(
    String oldPath,
    String newName,
  ) async {
    try {
      // Validate new name
      if (newName.isEmpty) {
        return const FolderOperationResult(
          success: false,
          message: '文件夹名称不能为空',
        );
      }

      if (newName.contains(RegExp(r'[<>:"/\\|?*]'))) {
        return const FolderOperationResult(
          success: false,
          message: '文件夹名称包含非法字符',
        );
      }

      final oldDir = Directory(oldPath);
      if (!await oldDir.exists()) {
        return const FolderOperationResult(success: false, message: '文件夹不存在');
      }

      final parentPath = p.dirname(oldPath);
      final newPath = p.join(parentPath, newName);
      final newDir = Directory(newPath);

      // Check if new name conflicts with existing folder
      if (await newDir.exists()) {
        return const FolderOperationResult(
          success: false,
          message: '目标文件夹名称已存在',
        );
      }

      // Find all notes in folder (recursive)
      final notePaths = await _getNotePathsInFolder(oldPath);

      // Batch update database paths
      for (final oldNotePath in notePaths) {
        final relativePath = p.relative(oldNotePath, from: oldPath);
        final newNotePath = p.join(newPath, relativePath);

        await noteRepository.updateFilePath(oldNotePath, newNotePath);
      }

      // Rename folder in file system
      await oldDir.rename(newPath);

      // Re-index folder (scan parent directory)
      await indexerService.fullScan(parentPath);

      return FolderOperationResult(
        success: true,
        message: '文件夹重命名成功',
        affectedNotes: notePaths.length,
      );
    } catch (e) {
      return FolderOperationResult(success: false, message: '重命名文件夹失败: $e');
    }
  }

  /// Delete a folder and all its contents
  Future<DeleteFolderResult> deleteFolder(String folderPath) async {
    try {
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        return const DeleteFolderResult(
          success: false,
          message: '文件夹不存在',
          affectedNotes: 0,
        );
      }

      // Find all notes in parent directory to get vault path
      final vaultPath = p.dirname(folderPath);

      // Find all notes in folder (recursive)
      final notePaths = await _getNotePathsInFolder(folderPath);

      // Delete notes from database
      for (final notePath in notePaths) {
        await noteRepository.deleteByFilePath(notePath);
      }

      // Delete folder from file system
      await folder.delete(recursive: true);

      // Re-index to clean up
      await indexerService.fullScan(vaultPath);

      return DeleteFolderResult(
        success: true,
        message: '文件夹删除成功',
        affectedNotes: notePaths.length,
        notePaths: notePaths,
      );
    } catch (e) {
      return DeleteFolderResult(
        success: false,
        message: '删除文件夹失败: $e',
        affectedNotes: 0,
      );
    }
  }

  /// Get all markdown file paths in a folder (recursive)
  Future<List<String>> _getNotePathsInFolder(String folderPath) async {
    final folder = Directory(folderPath);
    final notePaths = <String>[];

    await for (final entity in folder.list(recursive: true)) {
      if (entity is File && FileUtils.isMarkdownFile(entity.path)) {
        notePaths.add(entity.path);
      }
    }

    return notePaths;
  }

  /// Get note count in a folder (recursive)
  Future<int> getNoteCount(String folderPath) async {
    final notePaths = await _getNotePathsInFolder(folderPath);
    return notePaths.length;
  }

  /// Move a file to a new folder
  Future<FolderOperationResult> moveFile(
    String sourcePath,
    String destFolderPath,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return const FolderOperationResult(
          success: false,
          message: '源文件不存在',
        );
      }

      final destFolder = Directory(destFolderPath);
      if (!await destFolder.exists()) {
        return const FolderOperationResult(
          success: false,
          message: '目标文件夹不存在',
        );
      }

      final fileName = p.basename(sourcePath);
      final destPath = p.join(destFolderPath, fileName);

      // Check if file already exists in destination
      if (await File(destPath).exists()) {
        return const FolderOperationResult(
          success: false,
          message: '目标位置已存在同名文件',
        );
      }

      // Update database path first
      await noteRepository.updateFilePath(sourcePath, destPath);

      // Move file in file system
      await sourceFile.rename(destPath);

      return const FolderOperationResult(
        success: true,
        message: '文件移动成功',
        affectedNotes: 1,
      );
    } catch (e) {
      return FolderOperationResult(success: false, message: '移动文件失败: $e');
    }
  }

  /// Move a folder to a new parent folder
  Future<FolderOperationResult> moveFolder(
    String sourcePath,
    String destParentPath,
  ) async {
    try {
      final sourceFolder = Directory(sourcePath);
      if (!await sourceFolder.exists()) {
        return const FolderOperationResult(
          success: false,
          message: '源文件夹不存在',
        );
      }

      final destParent = Directory(destParentPath);
      if (!await destParent.exists()) {
        return const FolderOperationResult(
          success: false,
          message: '目标文件夹不存在',
        );
      }

      // Prevent moving folder into itself
      if (destParentPath.startsWith(sourcePath)) {
        return const FolderOperationResult(
          success: false,
          message: '不能将文件夹移动到自身内部',
        );
      }

      final folderName = p.basename(sourcePath);
      final destPath = p.join(destParentPath, folderName);

      // Check if folder already exists in destination
      if (await Directory(destPath).exists()) {
        return const FolderOperationResult(
          success: false,
          message: '目标位置已存在同名文件夹',
        );
      }

      // Find all notes in folder and update paths
      final notePaths = await _getNotePathsInFolder(sourcePath);
      for (final oldNotePath in notePaths) {
        final relativePath = p.relative(oldNotePath, from: sourcePath);
        final newNotePath = p.join(destPath, relativePath);
        await noteRepository.updateFilePath(oldNotePath, newNotePath);
      }

      // Move folder in file system
      await sourceFolder.rename(destPath);

      return FolderOperationResult(
        success: true,
        message: '文件夹移动成功',
        affectedNotes: notePaths.length,
      );
    } catch (e) {
      return FolderOperationResult(success: false, message: '移动文件夹失败: $e');
    }
  }
}
