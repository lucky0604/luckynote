import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/file_utils.dart';

/// 图片处理服务
/// 负责图片的保存和路径管理
class ImageHandler {
  /// 保存图片到资源文件夹
  /// 返回相对路径（用于 Markdown 引用）
  Future<String> saveImage({
    required String vaultPath,
    required Uint8List imageData,
    String? fileName,
  }) async {
    // 确保资源目录存在
    final assetsPath = FileUtils.getAssetsPath(vaultPath);
    await FileUtils.ensureDirectoryExists(assetsPath);

    // 生成文件名
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = fileName ?? 'image_$timestamp.png';
    final sanitizedName = FileUtils.sanitizeFileName(name);

    // 保存文件
    final filePath = p.join(assetsPath, sanitizedName);
    final file = File(filePath);
    await file.writeAsBytes(imageData);

    // 返回相对路径
    return '${AppConstants.assetsFolder}/$sanitizedName';
  }

  /// 从文件路径复制图片
  Future<String> copyImageFromPath({
    required String vaultPath,
    required String sourcePath,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw FileSystemException('源文件不存在', sourcePath);
    }

    final imageData = await sourceFile.readAsBytes();
    final originalName = p.basename(sourcePath);

    return saveImage(
      vaultPath: vaultPath,
      imageData: imageData,
      fileName: originalName,
    );
  }

  /// 生成 Markdown 图片引用
  String generateMarkdownImageRef(String relativePath, {String? altText}) {
    final alt = altText ?? 'image';
    return '![$alt]($relativePath)';
  }

  /// 检查文件是否为支持的图片格式
  bool isSupportedImage(String path) {
    final extension = p.extension(path).toLowerCase();
    return [
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.bmp',
    ].contains(extension);
  }

  /// 获取图片的完整路径
  String getImageFullPath(String vaultPath, String relativePath) {
    return p.join(vaultPath, relativePath);
  }

  /// 删除图片
  Future<void> deleteImage(String vaultPath, String relativePath) async {
    final fullPath = getImageFullPath(vaultPath, relativePath);
    final file = File(fullPath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
