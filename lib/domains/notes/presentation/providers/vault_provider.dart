import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// SharedPreferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

/// Vault 路径状态管理
/// 负责管理笔记仓库的路径
class VaultNotifier extends StateNotifier<AsyncValue<String?>> {
  VaultNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadVaultPath();
  }

  final Ref _ref;

  /// 从本地存储加载 vault 路径
  Future<void> _loadVaultPath() async {
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final path = prefs.getString(AppConstants.keyVaultPath);

      if (path != null) {
        // 验证路径是否有效
        final directory = Directory(path);
        final isValid = await directory.exists();
        if (isValid) {
          state = AsyncValue.data(path);
          return;
        }
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 设置 vault 路径
  Future<void> setVaultPath(String path) async {
    state = const AsyncValue.loading();

    try {
      final directory = Directory(path);
      final isValid = await directory.exists();

      if (!isValid) {
        throw Exception('无效的文件夹路径');
      }

      final prefs = await _ref.read(sharedPreferencesProvider.future);
      await prefs.setString(AppConstants.keyVaultPath, path);

      state = AsyncValue.data(path);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 清除 vault 路径
  Future<void> clearVaultPath() async {
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      await prefs.remove(AppConstants.keyVaultPath);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Vault 路径 Provider
final vaultProvider = StateNotifierProvider<VaultNotifier, AsyncValue<String?>>(
  (ref) {
    return VaultNotifier(ref);
  },
);

/// 是否有有效的 vault 路径
final hasVaultProvider = Provider<bool>((ref) {
  final vault = ref.watch(vaultProvider);
  return vault.maybeWhen(
    data: (path) => path != null && path.isNotEmpty,
    orElse: () => false,
  );
});
