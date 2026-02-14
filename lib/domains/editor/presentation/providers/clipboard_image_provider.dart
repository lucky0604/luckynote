import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/clipboard_image_service.dart';
import '../../../notes/presentation/providers/image_provider.dart';

/// 剪贴板图片服务 Provider
final clipboardImageServiceProvider = Provider<ClipboardImageService>((ref) {
  return ClipboardImageService();
});

/// 从剪贴板粘贴图片的 Provider
/// 返回插入编辑器的 Markdown 图片引用字符串
class ClipboardImagePasteNotifier extends StateNotifier<AsyncValue<String?>> {
  ClipboardImagePasteNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// 尝试从剪贴板粘贴图片
  /// 如果剪贴板包含图片，保存并返回 Markdown 引用
  /// 如果不包含图片，返回 null
  Future<String?> pasteImage() async {
    state = const AsyncValue.loading();

    try {
      final clipboardService = _ref.read(clipboardImageServiceProvider);

      // 尝试获取剪贴板图片
      final imageData = await clipboardService.getImageData();
      if (imageData == null || imageData.isEmpty) {
        state = const AsyncValue.data(null);
        return null;
      }

      // 生成文件名并保存
      final fileName = clipboardService.generateImageFileName();
      final markdownRef = await _ref.read(imageProvider.notifier).saveImage(
        imageData,
        fileName: fileName,
      );

      state = AsyncValue.data(markdownRef);
      return markdownRef;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// 剪贴板图片粘贴 Provider
final clipboardImagePasteProvider =
    StateNotifierProvider<ClipboardImagePasteNotifier, AsyncValue<String?>>(
  (ref) => ClipboardImagePasteNotifier(ref),
);
