import 'dart:io';

import '../../../../core/utils/file_utils.dart';

/// 文件系统服务
/// 负责管理本地文件的读写操作
///
/// 注意：此服务为低级文件操作工具类。
/// 笔记的主要 CRUD 操作应通过 NoteRepository（数据库）和 IndexerService 进行，
/// 以确保数据库索引与文件系统保持同步。
class FileSystemService {
  /// 检查目录是否是有效的笔记仓库
  Future<bool> isValidVault(String path) async {
    final directory = Directory(path);
    return directory.exists();
  }

  /// 确保资源目录存在
  Future<String> ensureAssetsDirectory(String vaultPath) async {
    final assetsPath = FileUtils.getAssetsPath(vaultPath);
    await FileUtils.ensureDirectoryExists(assetsPath);
    return assetsPath;
  }
}
