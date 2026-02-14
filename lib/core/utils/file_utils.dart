import 'dart:io';

import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';

/// 文件工具函数
abstract final class FileUtils {
  /// 支持的 Markdown 文件扩展名
  static const supportedMarkdownExtensions = [
    '.md',
    '.markdown',
    '.mdown',
    '.mkd',
    '.mkdn',
    '.mdtxt',
  ];

  /// 检查路径是否为 Markdown 文件
  static bool isMarkdownFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return supportedMarkdownExtensions.contains(ext);
  }

  /// 从文件路径获取笔记标题（不含扩展名）
  static String getTitleFromPath(String path) {
    return p.basenameWithoutExtension(path);
  }

  /// 从文件名获取完整路径
  static String getFullPath(String vaultPath, String fileName) {
    return p.join(vaultPath, fileName);
  }

  /// 生成唯一的笔记文件名
  static String generateNoteFileName(String title) {
    final sanitizedTitle = sanitizeFileName(title);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$sanitizedTitle-$timestamp${AppConstants.noteExtension}';
  }

  /// 清理文件名，移除非法字符
  static String sanitizeFileName(String name) {
    // 移除或替换非法字符
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  /// 获取资源文件夹路径
  static String getAssetsPath(String vaultPath) {
    return p.join(vaultPath, AppConstants.assetsFolder);
  }

  /// 确保目录存在
  static Future<void> ensureDirectoryExists(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// 获取文件的相对路径（相对于 vault）
  static String getRelativePath(String vaultPath, String filePath) {
    return p.relative(filePath, from: vaultPath);
  }

  /// 从 Markdown 内容中提取第一行作为标题
  static String extractTitleFromContent(String content) {
    if (content.isEmpty) {
      return AppConstants.newNoteTitle;
    }

    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        // 如果是标题行，移除 # 符号
        if (trimmed.startsWith('#')) {
          return trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        }
        // 否则返回第一行非空内容（截取前50个字符）
        return trimmed.length > 50 ? '${trimmed.substring(0, 50)}...' : trimmed;
      }
    }

    return AppConstants.newNoteTitle;
  }

  /// 从 Markdown 内容中提取预览文本
  static String extractPreviewFromContent(
    String content, {
    int maxLength = 100,
  }) {
    if (content.isEmpty) {
      return '';
    }

    // 移除 Markdown 语法符号
    final cleaned = content
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '') // 标题
        .replaceAll(RegExp(r'\*\*|__'), '') // 粗体
        .replaceAll(RegExp(r'\*|_'), '') // 斜体
        .replaceAll(RegExp(r'~~'), '') // 删除线
        .replaceAll(RegExp(r'`+'), '') // 代码
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '[图片]') // 图片
        .replaceAll(RegExp(r'\[([^\]]+)\]\(.*?\)'), r'$1') // 链接
        .replaceAll(RegExp(r'^\s*[-*+]\s*', multiLine: true), '') // 无序列表
        .replaceAll(RegExp(r'^\s*\d+\.\s*', multiLine: true), '') // 有序列表
        .replaceAll(RegExp(r'^\s*>\s*', multiLine: true), '') // 引用
        .replaceAll(RegExp(r'\n+'), ' ') // 换行符转空格
        .trim();

    if (cleaned.length <= maxLength) {
      return cleaned;
    }

    return '${cleaned.substring(0, maxLength)}...';
  }
}
