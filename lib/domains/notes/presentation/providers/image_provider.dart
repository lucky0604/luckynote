import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/image_handler.dart';
import 'vault_provider.dart';

/// 图片处理服务 Provider
final imageHandlerProvider = Provider<ImageHandler>((ref) {
  return ImageHandler();
});

/// 图片处理 Notifier
class ImageNotifier extends StateNotifier<AsyncValue<void>> {
  ImageNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// 保存图片并返回 Markdown 引用
  Future<String?> saveImage(Uint8List imageData, {String? fileName}) async {
    final vaultPath = _ref
        .read(vaultProvider)
        .maybeWhen(data: (path) => path, orElse: () => null);

    if (vaultPath == null) {
      return null;
    }

    state = const AsyncValue.loading();

    try {
      final imageHandler = _ref.read(imageHandlerProvider);
      final relativePath = await imageHandler.saveImage(
        vaultPath: vaultPath,
        imageData: imageData,
        fileName: fileName,
      );

      final markdownRef = imageHandler.generateMarkdownImageRef(relativePath);
      state = const AsyncValue.data(null);
      return markdownRef;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 从文件路径复制图片
  Future<String?> copyImageFromPath(String sourcePath) async {
    final vaultPath = _ref
        .read(vaultProvider)
        .maybeWhen(data: (path) => path, orElse: () => null);

    if (vaultPath == null) {
      return null;
    }

    state = const AsyncValue.loading();

    try {
      final imageHandler = _ref.read(imageHandlerProvider);
      final relativePath = await imageHandler.copyImageFromPath(
        vaultPath: vaultPath,
        sourcePath: sourcePath,
      );

      final markdownRef = imageHandler.generateMarkdownImageRef(relativePath);
      state = const AsyncValue.data(null);
      return markdownRef;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// 图片处理 Provider
final imageProvider = StateNotifierProvider<ImageNotifier, AsyncValue<void>>((
  ref,
) {
  return ImageNotifier(ref);
});
