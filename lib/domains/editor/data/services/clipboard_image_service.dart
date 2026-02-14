import 'dart:typed_data';

import 'package:pasteboard/pasteboard.dart';

/// 剪贴板图片服务
/// 负责从剪贴板读取图片数据
class ClipboardImageService {
  ClipboardImageService();

  /// 从剪贴板获取图片数据
  /// 返回 null 如果剪贴板不包含图片
  Future<Uint8List?> getImageData() async {
    try {
      final imageBytes = await Pasteboard.image;
      return imageBytes;
    } catch (e) {
      return null;
    }
  }

  /// 检查剪贴板是否包含图片
  Future<bool> hasImage() async {
    final imageData = await getImageData();
    return imageData != null && imageData.isNotEmpty;
  }

  /// 生成唯一的图片文件名
  String generateImageFileName() {
    final now = DateTime.now();
    final timestamp = '${now.year}${_pad(now.month)}${_pad(now.day)}'
        '_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return 'img_$timestamp.png';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
